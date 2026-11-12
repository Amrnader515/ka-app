/* بيخزن الغلاف بس (الصفحة والأيقونات) — الداتا دايماً من السيرفر */
/* 🔔 إشعارات Firebase — الإشعار نفسه بيظهر لوحده، ولما تدوس عليه بيفتح التطبيق */
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js','https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js');
firebase.initializeApp({ apiKey:'AIzaSyCHQNQHWr0uHhsTFWdp9-6HsQUVfChYE3I', authDomain:'ka-app-24aa3.firebaseapp.com', projectId:'ka-app-24aa3',
  storageBucket:'ka-app-24aa3.firebasestorage.app', messagingSenderId:'345594149704', appId:'1:345594149704:web:fed3ccfdc973a78ea1917d' });
firebase.messaging();
var C='ka-shell-v4', F=['./','index.html','manifest.json','icon-192.png','icon-512.png','icon-180.png'];
self.addEventListener('install',function(e){ e.waitUntil(caches.open(C).then(function(c){ return c.addAll(F); })); self.skipWaiting(); });
self.addEventListener('activate',function(e){ e.waitUntil(caches.keys().then(function(k){ return Promise.all(k.filter(function(x){return x!==C;}).map(function(x){return caches.delete(x);})); })); self.clients.claim(); });
self.addEventListener('fetch',function(e){
  var u=new URL(e.request.url);
  if(u.origin!==location.origin) return;
  e.respondWith(fetch(e.request).catch(function(){ return caches.match(e.request); }));
});
