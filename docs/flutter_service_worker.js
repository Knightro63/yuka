'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter_bootstrap.js": "da0e3a5848f4eb6a6ce1cc41e8bb4b76",
"version.json": "d3994e1f6412c8b0b6e264c83b9788b9",
"index.html": "569a7b0317e79be68a5dd566b71b8834",
"/": "569a7b0317e79be68a5dd566b71b8834",
"main.dart.js": "5805cdabd91599991e44b64c1eb9777b",
"flutter.js": "24bc71911b75b5f8135c949e27a2984e",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"main.dart.mjs": "055c0ec49c08aec680cc540356a435c7",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"manifest.json": "d19dc292e879202587dd9faf5e858f96",
"main.dart.wasm": "8a35383c9532e496858eab2fa8d87641",
"assets/AssetManifest.json": "421937358c42fbbc555e17718202f83e",
"assets/NOTICES": "8de7238066b9288d498b7f65fa47a14f",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/AssetManifest.bin.json": "4bdba9a962aac86d459e5da73f640173",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/packages/three_js_objects/assets/Water_1_M_Normal.jpg": "a33d50da063b016852d1d139cf6e73b1",
"assets/packages/three_js_objects/assets/Water_2_M_Normal.jpg": "639428cf065384aae22d01b529011992",
"assets/packages/three_js_controls/assets/joystick_background.png": "8c9aa78348b48e03f06bb97f74b819c9",
"assets/packages/three_js_controls/assets/joystick_knob.png": "bb0811554c35e7d74df6d80fb5ff5cd5",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/shaders/stretch_effect.frag": "40d68efbbf360632f614c731219e95f0",
"assets/AssetManifest.bin": "fad8172ee3ec707036859b3911e2e0c6",
"assets/fonts/MaterialIcons-Regular.otf": "e9d529c9456934738d124338c7711d94",
"assets/assets/textures/pitch_texture.jpg": "7803e6da205ba702b71038f9475c2f02",
"assets/assets/textures/muzzle.png": "61df58ecb657c87cba5c42b5bbe82451",
"assets/assets/textures/bulletHole.png": "9712b9cfbff4b44b3928700a6ab86133",
"assets/assets/screenshots/first_person.png": "18eb3e377805b01e4adfc81f627b8669",
"assets/assets/screenshots/steering_follow.png": "95d9b4a3fc126278b69599ef69d3313f",
"assets/assets/screenshots/steering_offset_pursuit.png": "84bc03df831170a6bc611eb4343913fa",
"assets/assets/screenshots/nav_basic.png": "a4539cf17f28621aa13c10c9e00d6370",
"assets/assets/screenshots/goal.png": "4150cbddf9e08817fb989c79a2a3080a",
"assets/assets/screenshots/fuzzy.png": "6232aab1510599771cc05e981970d8e7",
"assets/assets/screenshots/line_of_sight.png": "7348e03f241e8fb38a5415b0856e3b1f",
"assets/assets/screenshots/graph_basic.png": "17b5daa575cb86070fe888529969f3f6",
"assets/assets/screenshots/bounding_volumes.png": "173efeed015b0579f437b4d203e6c8e9",
"assets/assets/screenshots/steering_arrive.png": "ac3211f9959639d6fcec1f379cbd2cd9",
"assets/assets/screenshots/steering_flocking.png": "5dc7c7ea2d931626535817cc5864fa9e",
"assets/assets/screenshots/fsm.png": "3d7dfdf8d86ce1b835ed9350216ddfa2",
"assets/assets/screenshots/trigger.png": "2a9121dec5bfd4553f5f238b56e9d8b1",
"assets/assets/screenshots/steering_seek.png": "e09fc7b96556570530ce0a81391361c1",
"assets/assets/screenshots/dive.png": "fa0bf821331b6ab778b4cbc3f160269a",
"assets/assets/screenshots/steering_flee.png": "c66e3d2acd4a51d7cd2f533c93348872",
"assets/assets/screenshots/orientation.png": "22393ca9416676bcf0d876ba66985bbe",
"assets/assets/screenshots/memory_system.png": "a7d6ce0e6e004c3e6094fb163600724c",
"assets/assets/screenshots/steering_interpose.png": "b12d5c5b9ae6f1cfa08617a0fd9eb99b",
"assets/assets/screenshots/bvh.png": "9c3e43248bc99a517072c219483a413e",
"assets/assets/screenshots/steering_obsticle.png": "ff7bca7847e71654248301bc11e58c63",
"assets/assets/screenshots/hideseek.png": "74751ee2cdcf1b705c3c2fc4d2683563",
"assets/assets/screenshots/shooter.png": "3253ba94915fe6531bae7b677069e56f",
"assets/assets/screenshots/nav_advanced.png": "e69bb7cd9c962280b0da7591b545b3c5",
"assets/assets/screenshots/steering_wander.png": "2b37c239861f36ff5980fecf1735b6c7",
"assets/assets/screenshots/steering_pursuit.png": "c0c70c9180f6626852fc8ee9b60d9b33",
"assets/assets/models/level.glb": "d78723bc8e8a7b0bb8cdfe193346c37a",
"assets/assets/models/navmesh.gltf": "6809373bf8971b8c79ebf8255d4c4e6a",
"assets/assets/models/navmesh.glb": "05c9d161afcc1026075aa4233b16df6c",
"assets/assets/models/zombie.glb": "697205e5f3936e4de2622a1ae5263e5b",
"assets/assets/models/assaultRifle.glb": "9926efbcc24fe01bc43baaba9a608d7d",
"assets/assets/models/robot.glb": "9c27b50c71b728536f59cc20aa7e0592",
"assets/assets/models/yuka.glb": "5cb473e1e23bee5a9dd9b5e239fcea81",
"assets/assets/models/shotgun.glb": "4bb65c6740a7964a2b451e0fa6ad4dec",
"assets/assets/models/README.md": "41a708055933faacbc37119569303d5d",
"assets/assets/models/goal.glb": "411c9ef5fb6480c55238cb0df707584f",
"assets/assets/models/soldier.glb": "2db01aeb221b847dac68eefa73204da0",
"assets/assets/models/ball.glb": "6b3310b020774cc7b8e538a9f5f0493f",
"assets/assets/models/house/navmesh.glb": "7719477dbceafee6d97311dc8a0ff2f7",
"assets/assets/models/house/README.md": "bd188f80a41d39726040c8774c1a4e32",
"assets/assets/models/house/house.glb": "78f760b13ab2d4b36cb48b6355800ec7",
"assets/assets/models/buffer_navmesh.bin": "20115a63a4f92fa517f3d048a8e9c8f5",
"assets/assets/models/gun.glb": "3254acaefe1ae8cf7e67ef140870b17e",
"assets/assets/models/target.glb": "b07208529f0dafaf64b535d07f040c06",
"assets/assets/showcase/textures/damageIndicator.psd": "667c702228c872409ff97dd1b0874ce4",
"assets/assets/showcase/textures/levelTexture.png": "53d8adeb95d37f21464b1b16916de0f4",
"assets/assets/showcase/textures/lightmap.png": "48711160f335e68ee405a5db90c427c2",
"assets/assets/showcase/textures/damageIndicatorBack.png": "58877562b59e2de8495b6113c00abb6b",
"assets/assets/showcase/textures/crosshairs.png": "abd3b50413ad87f2ae5a11433f404eb9",
"assets/assets/showcase/textures/muzzle.png": "61df58ecb657c87cba5c42b5bbe82451",
"assets/assets/showcase/textures/damageIndicatorFront.png": "9085514bf0832a07528dbb9785b0db35",
"assets/assets/showcase/textures/damageIndicatorRight.png": "64d3bb9e2055c4b92384371bb2e67a21",
"assets/assets/showcase/textures/shadow.png": "77bde21d0f01358ac41ef25d1fbf6f98",
"assets/assets/showcase/textures/damageIndicatorLeft.png": "aafc73cac817eb0a67e4187e6e11eb9a",
"assets/assets/showcase/config/level.json": "9e04a081611c7179ea187b4efc963822",
"assets/assets/showcase/models/blaster_high.glb": "4c9f1dd0e083f15d19d4ab12a60c6546",
"assets/assets/showcase/models/level.glb": "12843917a9411ad3ec80db76589276e7",
"assets/assets/showcase/models/blaster_low.glb": "625b39917333bd44de7aa27d52dedb97",
"assets/assets/showcase/models/healthPack.glb": "20843104c1f709ee50f63f0cbb5b9a98",
"assets/assets/showcase/models/assaultRifle_high.glb": "b0fc3efa7d9f53246db0c3638a1b2c85",
"assets/assets/showcase/models/README.md": "719544b12c2afab99d3828124117255a",
"assets/assets/showcase/models/level1.glb": "fd16b97826f3d90241850624511beecf",
"assets/assets/showcase/models/assaultRifle_low.glb": "2f042bdb20b9cd3600e65a9faa96adb5",
"assets/assets/showcase/models/soldier.glb": "b8ca4f19efd683fde5d369cdf12e2138",
"assets/assets/showcase/models/shotgun_low.glb": "4c7ea84be2c7b3fbf4e47de0d55ef677",
"assets/assets/showcase/models/shotgun_high.glb": "4d0e1175753897381340da4712c2a4c7",
"assets/assets/showcase/nav/navmesh.glb": "260cd65cba6e72e5c0e4aa23d9f82856",
"assets/assets/showcase/nav/costTable.json": "882c89b0ead9a52a2875a3e91046d734",
"assets/assets/showcase/animations/blaster.json": "db72e7cf1faba61b17f4bd7d19a41372",
"assets/assets/showcase/animations/shotgun.json": "a34d2989b1d3ec8fcf81e6cc0479853d",
"assets/assets/showcase/animations/player.json": "7421bbbfbfcaa676ac8756315bdb2ead",
"assets/assets/showcase/animations/assaultRifle.json": "9f6570bb948885880f3781e4eb7e43e6",
"canvaskit/skwasm.js": "8060d46e9a4901ca9991edd3a26be4f0",
"canvaskit/skwasm_heavy.js": "740d43a6b8240ef9e23eed8c48840da4",
"canvaskit/skwasm.js.symbols": "3a4aadf4e8141f284bd524976b1d6bdc",
"canvaskit/canvaskit.js.symbols": "a3c9f77715b642d0437d9c275caba91e",
"canvaskit/skwasm_heavy.js.symbols": "0755b4fb399918388d71b59ad390b055",
"canvaskit/skwasm.wasm": "7e5f3afdd3b0747a1fd4517cea239898",
"canvaskit/chromium/canvaskit.js.symbols": "e2d09f0e434bc118bf67dae526737d07",
"canvaskit/chromium/canvaskit.js": "a80c765aaa8af8645c9fb1aae53f9abf",
"canvaskit/chromium/canvaskit.wasm": "a726e3f75a84fcdf495a15817c63a35d",
"canvaskit/canvaskit.js": "8331fe38e66b3a898c4f37648aaf7ee2",
"canvaskit/canvaskit.wasm": "9b6a7830bf26959b200594729d73538e",
"canvaskit/skwasm_heavy.wasm": "b0be7910760d205ea4e011458df6ee01"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"main.dart.wasm",
"main.dart.mjs",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
