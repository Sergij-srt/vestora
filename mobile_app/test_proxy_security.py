import gzip
import http.client
import http.server
import io
import os
import socket
import threading
import unittest
import urllib.parse
import urllib.request
import zlib

import run_server
from run_server import (
    MAX_DECOMPRESSED_BYTES,
    MAX_RAW_BYTES,
    PayloadTooLargeError,
    ProxySecurityError,
    SafeRedirectHandler,
    VestoraHandler,
    _resolve_allowed_origin,
    read_bounded_response,
    validate_and_pin_url,
    validate_proxy_url,
)


def _public_resolver(host, port, type=0):
    """Fake DNS resolver returning a public routable IP for shop.example.com."""
    if host == 'shop.example.com':
        return [(socket.AF_INET, socket.SOCK_STREAM, 6, '', ('93.184.216.34', port))]
    if host == 'rebind-internal.example.com':
        return [(socket.AF_INET, socket.SOCK_STREAM, 6, '', ('10.0.0.42', port))]
    if host == 'rebind-metadata.example.com':
        return [(socket.AF_INET, socket.SOCK_STREAM, 6, '', ('169.254.169.254', port))]
    if host == 'ipv6-loopback.example.com':
        return [(socket.AF_INET6, socket.SOCK_STREAM, 6, '', ('::1', port, 0, 0))]
    if host == 'cgnat.example.com':
        return [(socket.AF_INET, socket.SOCK_STREAM, 6, '', ('100.64.1.25', port))]
    raise socket.gaierror(f'Unknown host: {host}')


class _FakeHeaders(dict):
    def get(self, key, default=None):
        for k, v in self.items():
            if k.lower() == key.lower():
                return v
        return default


class _FakeResponse:
    def __init__(self, body: bytes, headers: dict | None = None):
        self._stream = io.BytesIO(body)
        self.headers = _FakeHeaders(headers or {})

    def read(self, size: int = -1) -> bytes:
        return self._stream.read(size)


class ProxySecurityUnitTests(unittest.TestCase):
    def test_blocks_non_http_schemes_and_local_files(self):
        disallowed_urls = [
            'file:///etc/passwd',
            'file:///C:/Windows/win.ini',
            'ftp://shop.example.com/catalog.csv',
            'gopher://127.0.0.1:6379/_INFO',
            'javascript:alert(1)',
            'data:text/html,<script>alert(1)</script>',
            '',
        ]
        for url in disallowed_urls:
            with self.subTest(url=url):
                with self.assertRaises(ProxySecurityError):
                    validate_proxy_url(url, resolver=_public_resolver)

    def test_blocks_private_loopback_cgnat_6to4_link_local_and_cloud_metadata_ips(self):
        ssrf_targets = [
            'http://127.0.0.1:8080/api/secret',
            'http://127.0.1.1/',
            'http://localhost:3000/',
            'http://sub.localhost/',
            'http://printer.local/',
            'http://metadata.google.internal/computeMetadata/v1/',
            'http://169.254.169.254/latest/meta-data/iam/security-credentials/',
            'http://10.0.0.1/internal',
            'http://100.64.0.1/cgnat',
            'http://100.127.255.254/cgnat',
            'http://172.16.0.1/internal',
            'http://172.31.255.254/internal',
            'http://192.168.1.1/router',
            'http://198.18.0.1/benchmark',
            'http://0.0.0.0/',
            'http://[::1]:8080/',
            'http://[::ffff:127.0.0.1]/',
            'http://[::ffff:169.254.169.254]/latest/meta-data/',
            'http://[2002:7f00:0001::1]/',  # 6to4 encoding 127.0.0.1
            'http://[2002:a9fe:a9fe::1]/',  # 6to4 encoding 169.254.169.254
            'http://[fe80::1]/',
            'https://user:pass@shop.example.com/item',
            'https://rebind-internal.example.com/product',
            'https://rebind-metadata.example.com/product',
            'https://ipv6-loopback.example.com/product',
            'https://cgnat.example.com/product',
        ]
        for url in ssrf_targets:
            with self.subTest(url=url):
                with self.assertRaises(ProxySecurityError):
                    validate_proxy_url(url, resolver=_public_resolver)

    def test_allows_valid_public_https_url_and_pins_resolved_ip(self):
        pin_map: dict[tuple[str, int], str] = {}
        clean = validate_and_pin_url(
            'https://shop.example.com/products/wool-coat?id=42',
            resolver=_public_resolver,
            pin_map=pin_map,
        )
        self.assertEqual(clean, 'https://shop.example.com/products/wool-coat?id=42')
        self.assertEqual(pin_map.get(('shop.example.com', 443)), '93.184.216.34')

    def test_redirect_handler_blocks_ssrf_and_redirect_loops(self):
        req = urllib.request.Request('https://shop.example.com/item')

        for malicious_redirect in (
            'http://127.0.0.1:8080/admin',
            'http://169.254.169.254/latest/meta-data/',
            'file:///etc/passwd',
            'https://rebind-internal.example.com/pwn',
        ):
            with self.subTest(target=malicious_redirect):
                fresh = SafeRedirectHandler(resolver=_public_resolver)
                with self.assertRaises(ProxySecurityError):
                    fresh.redirect_request(
                        req, None, 302, 'Found', {}, malicious_redirect
                    )

        # Max redirect cap (5 hops allowed, 6th blocked)
        pin_map: dict[tuple[str, int], str] = {}
        loop_handler = SafeRedirectHandler(resolver=_public_resolver, pin_map=pin_map)
        for hop in range(5):
            next_req = loop_handler.redirect_request(
                req, None, 302, 'Found', {}, f'https://shop.example.com/step-{hop}'
            )
            self.assertIsNotNone(next_req)
        self.assertEqual(pin_map.get(('shop.example.com', 443)), '93.184.216.34')
        with self.assertRaises(ProxySecurityError):
            loop_handler.redirect_request(
                req, None, 302, 'Found', {}, 'https://shop.example.com/step-overflow'
            )

    def test_blocks_oversized_raw_payload_gzip_bomb_and_deflate_bomb(self):
        # 1) Content-Length header exceeds 2 MB
        oversized_header_resp = _FakeResponse(
            b'tiny',
            headers={'Content-Length': str(MAX_RAW_BYTES + 1)},
        )
        with self.assertRaises(PayloadTooLargeError):
            read_bounded_response(oversized_header_resp)

        # 2) Streaming body without Content-Length exceeds 2 MB
        oversized_stream_resp = _FakeResponse(b'X' * (MAX_RAW_BYTES + 1024))
        with self.assertRaises(PayloadTooLargeError):
            read_bounded_response(oversized_stream_resp)

        # 3) Streaming gzip bomb: ~8 KB compressed -> 8 MB decompressed (> 5 MB cap)
        gzip_bomb = gzip.compress(b'0' * (8 * 1024 * 1024))
        self.assertLess(len(gzip_bomb), MAX_RAW_BYTES)
        bomb_resp = _FakeResponse(
            gzip_bomb,
            headers={'Content-Encoding': 'gzip', 'Content-Length': str(len(gzip_bomb))},
        )
        with self.assertRaises(PayloadTooLargeError):
            read_bounded_response(bomb_resp)

        # 4) Streaming deflate bomb (both zlib-wrapped and raw RFC 1951): 8 MB decompressed (> 5 MB cap)
        deflate_bomb = zlib.compress(b'D' * (8 * 1024 * 1024))
        self.assertLess(len(deflate_bomb), MAX_RAW_BYTES)
        deflate_resp = _FakeResponse(
            deflate_bomb,
            headers={'Content-Encoding': 'deflate', 'Content-Length': str(len(deflate_bomb))},
        )
        with self.assertRaises(PayloadTooLargeError):
            read_bounded_response(deflate_resp)

        raw_comp = zlib.compressobj(level=6, wbits=-zlib.MAX_WBITS)
        raw_deflate_bomb = raw_comp.compress(b'R' * (8 * 1024 * 1024)) + raw_comp.flush()
        raw_deflate_resp = _FakeResponse(
            raw_deflate_bomb,
            headers={'Content-Encoding': 'deflate'},
        )
        with self.assertRaises(PayloadTooLargeError):
            read_bounded_response(raw_deflate_resp)

        # 5) Legitimate gzipped and deflated HTML pass cleanly
        html = b'<html><head><meta property="og:title" content="Silk Trench"/></head></html>'
        valid_gz = _FakeResponse(
            gzip.compress(html),
            headers={'Content-Encoding': 'gzip'},
        )
        self.assertEqual(read_bounded_response(valid_gz), html)

        valid_deflate = _FakeResponse(
            zlib.compress(html),
            headers={'Content-Encoding': 'deflate'},
        )
        self.assertEqual(read_bounded_response(valid_deflate), html)
        self.assertGreater(MAX_DECOMPRESSED_BYTES, MAX_RAW_BYTES)

    def test_cors_origin_restricted_to_localhost(self):
        self.assertEqual(
            _resolve_allowed_origin('http://localhost:8090'),
            'http://localhost:8090',
        )
        self.assertEqual(
            _resolve_allowed_origin('http://127.0.0.1:3000'),
            'http://127.0.0.1:3000',
        )
        # Untrusted external origins must never be echoed back or wildcarded
        fallback = _resolve_allowed_origin('https://evil-attacker.example')
        self.assertEqual(fallback, f'http://127.0.0.1:{run_server.PORT}')
        self.assertNotEqual(fallback, '*')


class ProxyHttpIntegrationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.upstream_hits = 0
        cls.dialed_targets: list[tuple[str, int]] = []
        cls.dns_lookup_counts: dict[str, int] = {}

        # Ephemeral upstream server simulating gzip/deflate bombs and malicious 302 redirect
        class _UpstreamHandler(http.server.BaseHTTPRequestHandler):
            def do_GET(self):
                cls.upstream_hits += 1
                if self.path == '/bomb':
                    payload = gzip.compress(b'B' * (7 * 1024 * 1024))
                    self.send_response(200)
                    self.send_header('Content-Encoding', 'gzip')
                    self.send_header('Content-Length', str(len(payload)))
                    self.end_headers()
                    self.wfile.write(payload)
                elif self.path == '/deflate-bomb':
                    payload = zlib.compress(b'Z' * (7 * 1024 * 1024))
                    self.send_response(200)
                    self.send_header('Content-Encoding', 'deflate')
                    self.send_header('Content-Length', str(len(payload)))
                    self.end_headers()
                    self.wfile.write(payload)
                elif self.path == '/redirect-metadata':
                    self.send_response(302)
                    self.send_header('Location', 'http://169.254.169.254/latest/meta-data/')
                    self.end_headers()
                else:
                    host_hdr = self.headers.get('Host', '')
                    body = f'<html><title>Vestora Coat ({host_hdr})</title></html>'.encode('utf-8')
                    self.send_response(200)
                    self.send_header('Content-Type', 'text/html; charset=utf-8')
                    self.end_headers()
                    self.wfile.write(body)

            def do_POST(self):
                cls.upstream_hits += 1
                cl = int(self.headers.get('Content-Length', 0))
                body = self.rfile.read(cl)
                auth = self.headers.get('x-goog-api-key')
                if auth == 'valid-test-key':
                    self.send_response(200)
                    self.send_header('Content-Type', 'application/json')
                    self.end_headers()
                    self.wfile.write(b'{"candidates": [{"content": {"parts": [{"text": "OK"}]}}]}')
                else:
                    self.send_response(403)
                    self.send_header('Content-Type', 'application/json')
                    self.end_headers()
                    self.wfile.write(b'{"error": "Forbidden key"}')

            def log_message(self, format, *args):
                pass

        cls.upstream = http.server.HTTPServer(('127.0.0.1', 0), _UpstreamHandler)
        cls.upstream_port = cls.upstream.server_address[1]
        cls.upstream_thread = threading.Thread(target=cls.upstream.serve_forever, daemon=True)
        cls.upstream_thread.start()

        def _rebinding_test_resolver(host, port, type=0):
            cls.dns_lookup_counts[host] = cls.dns_lookup_counts.get(host, 0) + 1
            if host == 'toctou-rebind.example.com':
                # First lookup returns public IP; any second lookup attempts DNS rebinding to 127.0.0.1!
                if cls.dns_lookup_counts[host] == 1:
                    return [(socket.AF_INET, socket.SOCK_STREAM, 6, '', ('93.184.216.34', port))]
                return [(socket.AF_INET, socket.SOCK_STREAM, 6, '', ('127.0.0.1', port))]
            if host == 'generativelanguage.googleapis.com':
                return [(socket.AF_INET, socket.SOCK_STREAM, 6, '', ('93.184.216.34', port))]
            return _public_resolver(host, port, type=type)

        def _test_dialer(address, timeout=socket._GLOBAL_DEFAULT_TIMEOUT, source_address=None):
            ip, port = address
            cls.dialed_targets.append((ip, port))
            # Route only the validated public test IP to our local ephemeral test upstream
            if ip == '93.184.216.34':
                return socket.create_connection(('127.0.0.1', cls.upstream_port), timeout, source_address)
            raise AssertionError(f'Unexpected outbound dial to unpinned address: {address}')

        class _TestableVestoraHandler(VestoraHandler):
            resolver = staticmethod(_rebinding_test_resolver)
            dialer = staticmethod(_test_dialer)

            def log_message(self, format, *args):
                pass

        cls.proxy = http.server.HTTPServer(('127.0.0.1', 0), _TestableVestoraHandler)
        cls.proxy_port = cls.proxy.server_address[1]
        cls.proxy_thread = threading.Thread(target=cls.proxy.serve_forever, daemon=True)
        cls.proxy_thread.start()

    @classmethod
    def tearDownClass(cls):
        cls.proxy.shutdown()
        cls.proxy.server_close()
        cls.upstream.shutdown()
        cls.upstream.server_close()

    def _proxy_get(self, target_url: str | None, origin: str | None = 'http://localhost:8090'):
        conn = http.client.HTTPConnection('127.0.0.1', self.proxy_port, timeout=5)
        try:
            path = '/api/proxy'
            if target_url is not None:
                path += '?' + urllib.parse.urlencode({'url': target_url})
            headers = {'Origin': origin} if origin is not None else {}
            conn.request('GET', path, headers=headers)
            resp = conn.getresponse()
            body = resp.read()
            resp_headers = dict(resp.getheaders())
            return resp.status, resp_headers, body
        finally:
            conn.close()

    def test_http_endpoint_blocks_cross_origin_requests_before_upstream_fetch(self):
        hits_before = self.upstream_hits
        status, headers, body = self._proxy_get(
            'http://shop.example.com/ok',
            origin='https://evil.example',
        )
        self.assertEqual(status, 403)
        self.assertIn(b'Untrusted cross-origin', body)
        self.assertEqual(self.upstream_hits, hits_before)
        self.assertEqual(
            headers.get('Access-Control-Allow-Origin'),
            f'http://127.0.0.1:{run_server.PORT}',
        )

    def test_http_endpoint_rejects_missing_file_and_metadata_urls(self):
        status, _, _ = self._proxy_get(None)
        self.assertEqual(status, 400)

        for forbidden_url in (
            'file:///etc/passwd',
            f'http://127.0.0.1:{self.upstream_port}/ok',
            'http://169.254.169.254/latest/meta-data/',
            'https://rebind-metadata.example.com/secret',
        ):
            with self.subTest(url=forbidden_url):
                status, headers, body = self._proxy_get(forbidden_url)
                self.assertEqual(status, 403)
                self.assertIn(b'Proxy Forbidden', body)
                self.assertEqual(headers.get('X-Content-Type-Options'), 'nosniff')

    def test_http_endpoint_pins_dns_against_toctou_rebinding_and_blocks_bombs(self):
        # 1) Legitimate public page succeeds with 200 and preserves original Host header
        status, headers, body = self._proxy_get(
            'http://shop.example.com/ok',
            origin='http://localhost:8090',
        )
        self.assertEqual(status, 200)
        self.assertIn(b'Vestora Coat (shop.example.com)', body)
        self.assertEqual(headers.get('Access-Control-Allow-Origin'), 'http://localhost:8090')

        # 2) TTL=0 TOCTOU DNS rebinding domain: resolved ONCE and pinned to 93.184.216.34 (never 127.0.0.1)
        self.dns_lookup_counts.pop('toctou-rebind.example.com', None)
        self.dialed_targets.clear()
        status, _, body = self._proxy_get('http://toctou-rebind.example.com/ok')
        self.assertEqual(status, 200)
        self.assertEqual(self.dns_lookup_counts.get('toctou-rebind.example.com'), 1)
        self.assertEqual(self.dialed_targets, [('93.184.216.34', 80)])

        # 3) Public host 302-redirecting to AWS metadata IP is blocked with HTTP 403
        status, _, body = self._proxy_get('http://shop.example.com/redirect-metadata')
        self.assertEqual(status, 403)
        self.assertIn(b'Proxy Forbidden', body)

        # 4) Public host serving 7 MB gzip bomb is aborted with HTTP 413
        status, _, body = self._proxy_get('http://shop.example.com/bomb')
        self.assertEqual(status, 413)
        self.assertIn(b'Payload Too Large', body)

        # 5) Public host serving 7 MB deflate bomb is aborted with HTTP 413
        status, _, body = self._proxy_get('http://shop.example.com/deflate-bomb')
        self.assertEqual(status, 413)
        self.assertIn(b'Payload Too Large', body)

    def _proxy_options(self, path: str = '/api/proxy', origin: str | None = 'http://localhost:8090'):
        conn = http.client.HTTPConnection('127.0.0.1', self.proxy_port, timeout=5)
        try:
            headers = {'Origin': origin} if origin is not None else {}
            conn.request('OPTIONS', path, headers=headers)
            resp = conn.getresponse()
            body = resp.read()
            resp_headers = dict(resp.getheaders())
            return resp.status, resp_headers, body
        finally:
            conn.close()

    def _proxy_post(
        self,
        path: str = '/api/ai/vision',
        body: bytes = b'{}',
        headers: dict | None = None,
        origin: str | None = 'http://localhost:8090',
    ):
        conn = http.client.HTTPConnection('127.0.0.1', self.proxy_port, timeout=5)
        try:
            req_headers = {'Content-Type': 'application/json'}
            if headers:
                req_headers.update(headers)
            if origin is not None and 'Origin' not in req_headers:
                req_headers['Origin'] = origin
            conn.request('POST', path, body=body, headers=req_headers)
            resp = conn.getresponse()
            resp_body = resp.read()
            resp_headers = dict(resp.getheaders())
            return resp.status, resp_headers, resp_body
        finally:
            conn.close()

    def test_coop_and_coep_headers_present_on_all_responses(self):
        status, headers, _ = self._proxy_get('http://shop.example.com/ok')
        self.assertEqual(status, 200)
        self.assertEqual(headers.get('Cross-Origin-Opener-Policy'), 'same-origin')
        self.assertEqual(headers.get('Cross-Origin-Embedder-Policy'), 'credentialless')

    def test_options_cors_methods_and_headers(self):
        status, headers, _ = self._proxy_options('/api/ai/vision')
        self.assertEqual(status, 200)
        self.assertIn('POST', headers.get('Access-Control-Allow-Methods', ''))
        self.assertIn('x-goog-api-key', headers.get('Access-Control-Allow-Headers', ''))
        self.assertEqual(headers.get('Cross-Origin-Opener-Policy'), 'same-origin')
        self.assertEqual(headers.get('Cross-Origin-Embedder-Policy'), 'credentialless')

    def test_ai_vision_blocks_untrusted_origin(self):
        status, headers, body = self._proxy_post(origin='https://evil.example')
        self.assertEqual(status, 403)
        self.assertIn(b'Untrusted cross-origin', body)

    def test_ai_vision_validates_model_parameter(self):
        status, _, body = self._proxy_post(
            path='/api/ai/vision?model=../../evil_model',
            body=b'{"contents": []}',
        )
        self.assertEqual(status, 400)
        self.assertIn(b'Invalid model', body)

    def test_ai_vision_requires_api_key(self):
        status, _, body = self._proxy_post(
            path='/api/ai/vision?model=gemini-2.5-flash',
            body=b'{"contents": []}',
        )
        self.assertEqual(status, 401)
        self.assertIn(b'Missing Gemini API key', body)

    def test_ai_vision_validates_oversized_body(self):
        # 10MB + 1 byte body
        oversized = b'A' * (10 * 1024 * 1024 + 1)
        status, _, body = self._proxy_post(
            path='/api/ai/vision?model=gemini-2.5-flash',
            body=oversized,
            headers={'x-goog-api-key': 'test-key'},
        )
        self.assertEqual(status, 413)
        self.assertIn(b'Payload Too Large', body)

    def test_ai_vision_proxies_upstream_successfully(self):
        old_val = os.environ.get('GEMINI_UPSTREAM_BASE_URL')
        os.environ['GEMINI_UPSTREAM_BASE_URL'] = 'http://shop.example.com'
        try:
            status, headers, body = self._proxy_post(
                path='/api/ai/vision?model=gemini-2.5-flash',
                body=b'{"contents": [{"parts": [{"text": "analyze"}]}]}',
                headers={'x-goog-api-key': 'valid-test-key'},
            )
            self.assertEqual(status, 200)
            self.assertIn(b'"text": "OK"', body)
            self.assertEqual(headers.get('Cross-Origin-Opener-Policy'), 'same-origin')
            self.assertEqual(headers.get('Cross-Origin-Embedder-Policy'), 'credentialless')
        finally:
            if old_val is not None:
                os.environ['GEMINI_UPSTREAM_BASE_URL'] = old_val
            else:
                os.environ.pop('GEMINI_UPSTREAM_BASE_URL', None)


if __name__ == '__main__':
    unittest.main(verbosity=2)

