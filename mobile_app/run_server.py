import gzip
import http.client
import http.server
import io
import ipaddress
import os
import socket
import ssl
import sys
import urllib.error
import urllib.parse
import urllib.request
import zlib

PORT = 8080
DIRECTORY = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'build', 'web')

MAX_RAW_BYTES = 2 * 1024 * 1024          # 2 MB compressed/raw response cap
MAX_DECOMPRESSED_BYTES = 5 * 1024 * 1024 # 5 MB decompressed cap (anti-gzip/deflate-bomb)
MAX_REDIRECTS = 5

ALLOWED_SCHEMES = {'http', 'https'}
BLOCKED_HOSTNAMES = {
    'localhost',
    'localhost.localdomain',
    'metadata.google.internal',
    'metadata',
    'instance-data',
}


class ProxySecurityError(Exception):
    """Raised when a proxy target violates SSRF, origin, or scheme security policies."""


class PayloadTooLargeError(Exception):
    """Raised when upstream response or compressed stream exceeds safe memory bounds."""


def _is_disallowed_ip_obj(
    ip: ipaddress.IPv4Address | ipaddress.IPv6Address,
) -> bool:
    """Recursively checks IPv4/IPv6 addresses (including mapped, 6to4, and Teredo) for non-public ranges."""
    if isinstance(ip, ipaddress.IPv6Address):
        if ip.ipv4_mapped is not None and _is_disallowed_ip_obj(ip.ipv4_mapped):
            return True
        if ip.sixtofour is not None and _is_disallowed_ip_obj(ip.sixtofour):
            return True
        if ip.teredo is not None:
            server_ip, client_ip = ip.teredo
            if _is_disallowed_ip_obj(server_ip) or _is_disallowed_ip_obj(client_ip):
                return True

    return (
        not ip.is_global
        or ip.is_private
        or ip.is_loopback
        or ip.is_link_local
        or ip.is_multicast
        or ip.is_reserved
        or ip.is_unspecified
    )


def _is_disallowed_ip(ip_str: str) -> bool:
    """Returns True if an IP is non-global, loopback, private, CGNAT, link-local, metadata, or reserved."""
    try:
        clean_ip = ip_str.split('%', 1)[0] if '%' in ip_str else ip_str
        ip = ipaddress.ip_address(clean_ip)
    except ValueError:
        return True
    return _is_disallowed_ip_obj(ip)


def validate_and_pin_url(
    target_url: str,
    resolver=socket.getaddrinfo,
    pin_map: dict[tuple[str, int], str] | None = None,
) -> str:
    """
    Validates that target_url uses http/https, has no embedded credentials,
    and resolves exclusively to globally routable public IP addresses.
    Records the validated IP in pin_map (if provided) to prevent DNS rebinding (TOCTOU).
    """
    if not target_url or not isinstance(target_url, str):
        raise ProxySecurityError('Missing or invalid target URL')

    clean_url = target_url.strip()
    if len(clean_url) > 2048:
        raise ProxySecurityError('URL exceeds maximum length of 2048 characters')

    parsed = urllib.parse.urlparse(clean_url)
    scheme = (parsed.scheme or '').lower()
    if scheme not in ALLOWED_SCHEMES:
        raise ProxySecurityError(f'Disallowed URL scheme: {scheme or "none"}')

    if parsed.username or parsed.password:
        raise ProxySecurityError('Embedded credentials in URL are not allowed')

    hostname = (parsed.hostname or '').strip().lower().rstrip('.')
    if not hostname:
        raise ProxySecurityError('Missing hostname in URL')

    if (
        hostname in BLOCKED_HOSTNAMES
        or hostname.endswith('.localhost')
        or hostname.endswith('.local')
        or hostname.endswith('.internal')
    ):
        raise ProxySecurityError(f'Blocked internal hostname: {hostname}')

    try:
        port = parsed.port or (443 if scheme == 'https' else 80)
    except ValueError as exc:
        raise ProxySecurityError(f'Invalid port in URL: {exc}') from exc

    # Direct IP literal check before DNS lookup
    try:
        ipaddress.ip_address(hostname)
        if _is_disallowed_ip(hostname):
            raise ProxySecurityError(f'Blocked non-public IP address: {hostname}')
        if pin_map is not None:
            pin_map[(hostname, port)] = hostname
        return clean_url
    except ValueError:
        pass

    try:
        addr_infos = resolver(hostname, port, type=socket.SOCK_STREAM)
    except socket.gaierror as exc:
        raise ProxySecurityError(f'DNS resolution failed for {hostname}: {exc}') from exc

    if not addr_infos:
        raise ProxySecurityError(f'No DNS records resolved for {hostname}')

    validated_ips: list[str] = []
    for info in addr_infos:
        sockaddr = info[4]
        resolved_ip = sockaddr[0]
        if '%' in resolved_ip:
            resolved_ip = resolved_ip.split('%', 1)[0]
        if _is_disallowed_ip(resolved_ip):
            raise ProxySecurityError(
                f'Host {hostname} resolves to disallowed non-public IP {resolved_ip}'
            )
        validated_ips.append(resolved_ip)

    if pin_map is not None and validated_ips:
        pin_map[(hostname, port)] = validated_ips[0]

    return clean_url


def validate_proxy_url(target_url: str, resolver=socket.getaddrinfo) -> str:
    """Validates target_url against SSRF and scheme rules and returns normalized URL."""
    return validate_and_pin_url(target_url, resolver=resolver, pin_map=None)


class PinnedHTTPConnection(http.client.HTTPConnection):
    """HTTP connection that dials a pre-validated IP directly while keeping the original Host header."""

    def __init__(self, host, port=None, *, pinned_ip: str, dialer=socket.create_connection, **kwargs):
        super().__init__(host, port=port, **kwargs)
        self._pinned_ip = pinned_ip
        self._dialer = dialer

    def connect(self):
        if _is_disallowed_ip(self._pinned_ip):
            raise ProxySecurityError(f'Blocked connection to non-public IP {self._pinned_ip}')
        self.sock = self._dialer(
            (self._pinned_ip, self.port),
            self.timeout,
            self.source_address,
        )


class PinnedHTTPSConnection(http.client.HTTPSConnection):
    """HTTPS connection that dials a pre-validated IP while preserving TLS SNI & hostname verification."""

    def __init__(
        self,
        host,
        port=None,
        *,
        pinned_ip: str,
        dialer=socket.create_connection,
        context=None,
        **kwargs,
    ):
        self._ssl_ctx = context or ssl.create_default_context()
        super().__init__(host, port=port, context=self._ssl_ctx, **kwargs)
        self._pinned_ip = pinned_ip
        self._dialer = dialer

    def connect(self):
        if _is_disallowed_ip(self._pinned_ip):
            raise ProxySecurityError(f'Blocked connection to non-public IP {self._pinned_ip}')
        raw_sock = self._dialer(
            (self._pinned_ip, self.port),
            self.timeout,
            self.source_address,
        )
        server_hostname = self._tunnel_host if self._tunnel_host else self.host
        self.sock = self._ssl_ctx.wrap_socket(raw_sock, server_hostname=server_hostname)


def _lookup_pinned_ip(
    req: urllib.request.Request,
    default_port: int,
    pin_map: dict[tuple[str, int], str],
    resolver,
) -> str:
    parsed = urllib.parse.urlparse(req.full_url)
    hostname = (parsed.hostname or '').strip().lower().rstrip('.')
    port = parsed.port or default_port
    pinned_ip = pin_map.get((hostname, port))
    if not pinned_ip:
        validate_and_pin_url(req.full_url, resolver=resolver, pin_map=pin_map)
        pinned_ip = pin_map.get((hostname, port))
    if not pinned_ip:
        raise ProxySecurityError(f'Unable to pin validated IP for {hostname}:{port}')
    return pinned_ip


class PinnedHTTPHandler(urllib.request.HTTPHandler):
    def __init__(self, pin_map: dict[tuple[str, int], str], resolver=socket.getaddrinfo, dialer=socket.create_connection):
        super().__init__()
        self._pin_map = pin_map
        self._resolver = resolver
        self._dialer = dialer

    def http_open(self, req):
        pinned_ip = _lookup_pinned_ip(req, 80, self._pin_map, self._resolver)
        return self.do_open(
            lambda host, **kw: PinnedHTTPConnection(
                host, pinned_ip=pinned_ip, dialer=self._dialer, **kw
            ),
            req,
        )


class PinnedHTTPSHandler(urllib.request.HTTPSHandler):
    def __init__(self, pin_map: dict[tuple[str, int], str], resolver=socket.getaddrinfo, dialer=socket.create_connection):
        super().__init__()
        self._pin_map = pin_map
        self._resolver = resolver
        self._dialer = dialer

    def https_open(self, req):
        pinned_ip = _lookup_pinned_ip(req, 443, self._pin_map, self._resolver)
        return self.do_open(
            lambda host, **kw: PinnedHTTPSConnection(
                host, pinned_ip=pinned_ip, dialer=self._dialer, **kw
            ),
            req,
        )


class SafeRedirectHandler(urllib.request.HTTPRedirectHandler):
    """Re-validates and pins every HTTP redirect target against SSRF rules."""

    def __init__(
        self,
        resolver=socket.getaddrinfo,
        pin_map: dict[tuple[str, int], str] | None = None,
    ):
        super().__init__()
        self._resolver = resolver
        self._pin_map = pin_map
        self._redirects = 0

    def redirect_request(self, req, fp, code, msg, headers, newurl):
        self._redirects += 1
        if self._redirects > MAX_REDIRECTS:
            raise ProxySecurityError(f'Exceeded maximum redirects ({MAX_REDIRECTS})')

        resolved_target = urllib.parse.urljoin(req.full_url, newurl)
        validate_and_pin_url(resolved_target, resolver=self._resolver, pin_map=self._pin_map)
        return super().redirect_request(req, fp, code, msg, headers, resolved_target)


def _decompress_deflate_bounded(data: bytes, max_decompressed_bytes: int) -> bytes:
    """Decompresses zlib-wrapped or raw RFC 1951 deflate streams with a strict byte ceiling."""
    for wbits in (zlib.MAX_WBITS, -zlib.MAX_WBITS):
        decomp = zlib.decompressobj(wbits)
        chunks: list[bytes] = []
        total = 0
        try:
            view = memoryview(data)
            offset = 0
            while offset < len(view):
                block = view[offset:offset + 65536]
                offset += len(block)
                piece = decomp.decompress(block, 65536)
                if piece:
                    total += len(piece)
                    if total > max_decompressed_bytes:
                        raise PayloadTooLargeError(
                            f'Decompressed deflate payload exceeded {max_decompressed_bytes} bytes limit'
                        )
                    chunks.append(piece)
                while decomp.unconsumed_tail:
                    piece = decomp.decompress(decomp.unconsumed_tail, 65536)
                    if piece:
                        total += len(piece)
                        if total > max_decompressed_bytes:
                            raise PayloadTooLargeError(
                                f'Decompressed deflate payload exceeded {max_decompressed_bytes} bytes limit'
                            )
                        chunks.append(piece)
            tail = decomp.flush()
            if tail:
                total += len(tail)
                if total > max_decompressed_bytes:
                    raise PayloadTooLargeError(
                        f'Decompressed deflate payload exceeded {max_decompressed_bytes} bytes limit'
                    )
                chunks.append(tail)
            return b''.join(chunks)
        except PayloadTooLargeError:
            raise
        except zlib.error as exc:
            if wbits == -zlib.MAX_WBITS:
                raise ProxySecurityError(f'Malformed deflate stream: {exc}') from exc
            continue
    return data


def read_bounded_response(
    resp,
    max_raw_bytes: int = MAX_RAW_BYTES,
    max_decompressed_bytes: int = MAX_DECOMPRESSED_BYTES,
) -> bytes:
    """Reads an HTTP response with strict raw, gzip, and deflate decompression caps."""
    content_length = None
    if hasattr(resp, 'headers') and resp.headers is not None:
        raw_cl = resp.headers.get('Content-Length')
        if raw_cl:
            try:
                content_length = int(raw_cl)
            except ValueError:
                content_length = None

    if content_length is not None and content_length > max_raw_bytes:
        raise PayloadTooLargeError(
            f'Upstream Content-Length ({content_length} bytes) exceeds limit ({max_raw_bytes} bytes)'
        )

    chunks = []
    total_read = 0
    while True:
        chunk = resp.read(65536)
        if not chunk:
            break
        total_read += len(chunk)
        if total_read > max_raw_bytes:
            raise PayloadTooLargeError(
                f'Upstream response exceeded {max_raw_bytes} bytes limit'
            )
        chunks.append(chunk)

    data = b''.join(chunks)

    content_encoding = ''
    if hasattr(resp, 'headers') and resp.headers is not None:
        content_encoding = (resp.headers.get('Content-Encoding') or '').lower()

    if data.startswith(b'\x1f\x8b') or 'gzip' in content_encoding:
        decompressed_chunks = []
        decompressed_total = 0
        try:
            with gzip.GzipFile(fileobj=io.BytesIO(data)) as gz:
                while True:
                    piece = gz.read(65536)
                    if not piece:
                        break
                    decompressed_total += len(piece)
                    if decompressed_total > max_decompressed_bytes:
                        raise PayloadTooLargeError(
                            f'Decompressed gzip payload exceeded {max_decompressed_bytes} bytes limit'
                        )
                    decompressed_chunks.append(piece)
        except OSError as exc:
            raise ProxySecurityError(f'Malformed gzip stream: {exc}') from exc
        data = b''.join(decompressed_chunks)
    elif 'deflate' in content_encoding:
        data = _decompress_deflate_bounded(data, max_decompressed_bytes)

    return data


def _is_trusted_origin(origin_header: str | None) -> bool:
    """Returns True when Origin is absent (same-origin/CLI) or explicitly localhost/127.0.0.1."""
    if not origin_header or not origin_header.strip():
        return True
    parsed = urllib.parse.urlparse(origin_header.strip())
    return parsed.scheme in ('http', 'https') and parsed.hostname in ('127.0.0.1', 'localhost')


def _resolve_allowed_origin(origin_header: str | None) -> str:
    """Restricts CORS origin to local development origins."""
    if origin_header and _is_trusted_origin(origin_header):
        return origin_header.strip()
    return f'http://127.0.0.1:{PORT}'


class VestoraHandler(http.server.SimpleHTTPRequestHandler):
    resolver = staticmethod(socket.getaddrinfo)
    dialer = staticmethod(socket.create_connection)

    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def _send_cors_headers(self):
        origin = _resolve_allowed_origin(self.headers.get('Origin'))
        self.send_header('Access-Control-Allow-Origin', origin)
        self.send_header('Vary', 'Origin')
        self.send_header('Access-Control-Allow-Methods', 'GET, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Accept')
        self.send_header('X-Content-Type-Options', 'nosniff')

    def do_OPTIONS(self):
        if self.path.startswith('/api/proxy') and not _is_trusted_origin(self.headers.get('Origin')):
            self.send_response(403)
            self._send_cors_headers()
            self.end_headers()
            return
        self.send_response(200)
        self._send_cors_headers()
        self.end_headers()

    def do_GET(self):
        if self.path.startswith('/api/proxy'):
            self._handle_proxy()
            return
        super().do_GET()

    def _build_proxy_opener(self, pin_map: dict[tuple[str, int], str]):
        return urllib.request.build_opener(
            PinnedHTTPHandler(pin_map, resolver=self.resolver, dialer=self.dialer),
            PinnedHTTPSHandler(pin_map, resolver=self.resolver, dialer=self.dialer),
            SafeRedirectHandler(resolver=self.resolver, pin_map=pin_map),
        )

    def _handle_proxy(self):
        if not _is_trusted_origin(self.headers.get('Origin')):
            self.send_response(403)
            self.send_header('Content-Type', 'text/plain; charset=utf-8')
            self._send_cors_headers()
            self.end_headers()
            self.wfile.write(b'Proxy Forbidden: Untrusted cross-origin request')
            return

        parsed = urllib.parse.urlparse(self.path)
        qs = urllib.parse.parse_qs(parsed.query)
        target_url = qs.get('url', [None])[0]
        if not target_url:
            self.send_response(400)
            self.send_header('Content-Type', 'text/plain; charset=utf-8')
            self._send_cors_headers()
            self.end_headers()
            self.wfile.write(b'Missing url parameter')
            return

        try:
            pin_map: dict[tuple[str, int], str] = {}
            safe_url = validate_and_pin_url(target_url, resolver=self.resolver, pin_map=pin_map)
            opener = self._build_proxy_opener(pin_map)
            req = urllib.request.Request(
                safe_url,
                headers={
                    'User-Agent': (
                        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
                        'AppleWebKit/537.36 (KHTML, like Gecko) '
                        'Chrome/124.0.0.0 Safari/537.36'
                    ),
                    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
                    'Accept-Language': 'uk-UA,uk;q=0.9,en-US;q=0.8,en;q=0.7',
                    'Accept-Encoding': 'gzip, deflate, identity',
                },
            )
            with opener.open(req, timeout=10) as resp:
                data = read_bounded_response(resp)

                self.send_response(200)
                self.send_header('Content-Type', 'text/html; charset=utf-8')
                self._send_cors_headers()
                self.end_headers()
                self.wfile.write(data)
        except ProxySecurityError as sec_err:
            self.send_response(403)
            self.send_header('Content-Type', 'text/plain; charset=utf-8')
            self._send_cors_headers()
            self.end_headers()
            self.wfile.write(f'Proxy Forbidden: {sec_err}'.encode('utf-8'))
        except PayloadTooLargeError as size_err:
            self.send_response(413)
            self.send_header('Content-Type', 'text/plain; charset=utf-8')
            self._send_cors_headers()
            self.end_headers()
            self.wfile.write(f'Payload Too Large: {size_err}'.encode('utf-8'))
        except Exception as exc:
            self.send_response(502)
            self.send_header('Content-Type', 'text/plain; charset=utf-8')
            self._send_cors_headers()
            self.end_headers()
            self.wfile.write(f'Proxy Upstream Error: {type(exc).__name__}'.encode('utf-8'))

    def log_message(self, format, *args):
        sys.stdout.write(f"[{self.log_date_time_string()}] {format % args}\n")
        sys.stdout.flush()


if __name__ == '__main__':
    server_address = ('127.0.0.1', PORT)
    httpd = http.server.HTTPServer(server_address, VestoraHandler)
    print(f"Vestora hardened server with SSRF-protected CORS proxy active on http://127.0.0.1:{PORT}")
    sys.stdout.flush()
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        httpd.server_close()
