// One complete release per cache. A new worker waits for all old app windows
// to close; never reload a driver's active calendar or clear their IndexedDB.
const CACHE = 'driver-calendar-web-__BUILD__';
const FILES = __FILES__;
const HOME = new URL('./index.html', self.location).href;
self.addEventListener('install', event => {
  event.waitUntil(caches.open(CACHE).then(cache => cache.addAll(FILES)));
});
self.addEventListener('activate', event => {
  event.waitUntil(caches.keys().then(keys => Promise.all(keys.filter(key => key.startsWith('driver-calendar-web-') && key !== CACHE).map(key => caches.delete(key)))).then(() => self.clients.claim()));
});
self.addEventListener('fetch', event => {
  if (event.request.method !== 'GET') return;
  const url = new URL(event.request.url);
  if (url.origin !== self.location.origin) return;
  const file = event.request.mode === 'navigate' && url.pathname.startsWith('/iphone/') ? HOME : url.href;
  if (!FILES.some(path => new URL(path, self.location).href === file)) return;
  event.respondWith(caches.open(CACHE).then(async cache => {
    const response = (await cache.match(file)) || await fetch(event.request);
    // Static hosting may redirect index.html to /iphone/. Navigation requests
    // can reject cached redirected responses, so return the same body directly.
    return response.redirected ? new Response(response.body,{status:response.status,statusText:response.statusText,headers:response.headers}) : response;
  }));
});
