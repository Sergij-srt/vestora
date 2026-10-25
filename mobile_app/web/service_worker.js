// Vestora PWA Service Worker v1.2.0 (Isolated Shell Cache + Bounded Runtime Cache + Wasm Ready)
const SHELL_CACHE = 'vestora-shell-v1.2.0';
const RUNTIME_CACHE = 'vestora-runtime-v1.2.0';
const ACTIVE_CACHES = [SHELL_CACHE, RUNTIME_CACHE];
const MAX_RUNTIME_ENTRIES = 80;

const PRECACHE_ASSETS = [
  './',
  './index.html',
  './manifest.json',
  './favicon.png',
  './icons/Icon-192.png',
  './icons/Icon-512.png',
  './icons/Icon-maskable-192.png',
  './icons/Icon-maskable-512.png'
];

async function trimCache(cacheName, maxItems) {
  const cache = await caches.open(cacheName);
  const keys = await cache.keys();
  if (keys.length > maxItems) {
    const deleteCount = keys.length - maxItems;
    for (let i = 0; i < deleteCount; i++) {
      await cache.delete(keys[i]);
    }
  }
}

// Install: Precache immutable offline shell assets in SHELL_CACHE (never trimmed)
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(SHELL_CACHE).then((cache) => {
      return cache.addAll(PRECACHE_ASSETS);
    }).then(() => self.skipWaiting())
  );
});

// Activate: Purge older cache versions while preserving both SHELL_CACHE and RUNTIME_CACHE
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((name) => {
          if (!ACTIVE_CACHES.includes(name)) {
            return caches.delete(name);
          }
        })
      );
    }).then(() => self.clients.claim())
  );
});

// Fetch: Same-origin only, API excluded, Wasm/static Cache-First in RUNTIME_CACHE, HTML Network-First in SHELL_CACHE
self.addEventListener('fetch', (event) => {
  const request = event.request;
  const url = new URL(request.url);

  // Never intercept non-GET, cross-origin (Supabase/Gemini/Open-Meteo/Unsplash), or local /api/ proxy calls
  if (
    request.method !== 'GET' ||
    url.origin !== self.location.origin ||
    url.pathname.startsWith('/api/')
  ) {
    return;
  }

  // 1. HTML Document Navigation -> Network First with pinned SHELL_CACHE ./index.html fallback
  if (request.mode === 'navigate') {
    event.respondWith(
      fetch(request)
        .then((networkResponse) => {
          if (networkResponse && networkResponse.status === 200) {
            const clone = networkResponse.clone();
            caches.open(SHELL_CACHE).then((cache) => cache.put('./index.html', clone));
          }
          return networkResponse;
        })
        .catch(() => {
          return caches.open(SHELL_CACHE).then((shell) => {
            return shell.match(request).then((exact) => exact || shell.match('./index.html'));
          });
        })
    );
    return;
  }

  // 2. Same-origin Static & Wasm Assets -> Cache First with bounded RUNTIME_CACHE
  const isStatic = (
    url.pathname.endsWith('.js') ||
    url.pathname.endsWith('.mjs') ||
    url.pathname.endsWith('.wasm') ||
    url.pathname.endsWith('.symbols') ||
    url.pathname.endsWith('.ttf') ||
    url.pathname.endsWith('.otf') ||
    url.pathname.endsWith('.woff2') ||
    url.pathname.endsWith('.png') ||
    url.pathname.endsWith('.jpg') ||
    url.pathname.endsWith('.webp') ||
    url.pathname.endsWith('.json')
  );

  if (isStatic) {
    event.respondWith(
      caches.match(request).then((cachedResponse) => {
        if (cachedResponse) {
          fetch(request).then((networkResponse) => {
            if (networkResponse && networkResponse.status === 200) {
              caches.open(RUNTIME_CACHE).then((cache) => {
                cache.put(request, networkResponse);
                trimCache(RUNTIME_CACHE, MAX_RUNTIME_ENTRIES);
              });
            }
          }).catch(() => {/* Offline */});
          return cachedResponse;
        }

        return fetch(request).then((networkResponse) => {
          if (networkResponse && networkResponse.status === 200) {
            const clone = networkResponse.clone();
            caches.open(RUNTIME_CACHE).then((cache) => {
              cache.put(request, clone);
              trimCache(RUNTIME_CACHE, MAX_RUNTIME_ENTRIES);
            });
          }
          return networkResponse;
        });
      })
    );
  }
});
