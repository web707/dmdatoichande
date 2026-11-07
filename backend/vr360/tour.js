const title = document.querySelector('#scene-title');
const statusLabel = document.querySelector('#status');
const panorama = document.querySelector('#panorama');
const previous = document.querySelector('#previous');
const next = document.querySelector('#next');
const dialog = document.querySelector('#details');
const content = document.querySelector('#content');

function showInfo(marker) {
  const element = document.createElement(marker.type === 'image' ? 'img' : marker.type === 'video' ? 'video' : 'a');
  if (element instanceof HTMLAnchorElement) {
    element.href = marker.url;
    element.target = '_blank';
    element.rel = 'noopener noreferrer';
    element.textContent = 'Mở nội dung về địa điểm';
  } else {
    element.src = marker.url;
    if (element instanceof HTMLVideoElement) element.controls = true;
    else element.alt = 'Thông tin về địa điểm';
  }
  content.replaceChildren(element);
  dialog.showModal();
}

function showMap(floorplan, viewer) {
  const map = document.createElement('div');
  map.className = 'floorplan';
  const image = document.createElement('img');
  image.src = floorplan.url;
  image.alt = floorplan.title;
  map.append(image);
  for (const point of floorplan.points) {
    const button = document.createElement('button');
    button.type = 'button';
    button.title = point.label;
    button.setAttribute('aria-label', point.label);
    button.setAttribute('aria-current', String(point.id === viewer.getScene()));
    button.style.left = `${point.x}%`;
    button.style.top = `${point.y}%`;
    button.addEventListener('click', () => {
      dialog.close();
      if (point.id !== viewer.getScene() && viewer.isLoaded()) viewer.loadScene(point.id);
    });
    map.append(button);
  }
  content.replaceChildren(map);
  dialog.showModal();
}

function hotspot(marker, select) {
  const isLink = marker.type === 'marker';
  const label = isLink ? marker.label : 'Thông tin địa điểm';
  return {
    pitch: marker.pitch,
    yaw: marker.yaw,
    type: 'info',
    cssClass: 'lake-hotspot',
    // Pannellum's default scene hotspot reacts to touchend, including a drag
    // that ends over it. A click lets the browser distinguish a tap from a drag.
    clickHandlerFunc: () => isLink ? select(marker) : showInfo(marker),
    createTooltipFunc(element) {
      element.dataset.hotspot = marker.id;
      element.tabIndex = 0;
      element.setAttribute('role', 'button');
      element.setAttribute('aria-label', label);
      element.textContent = !isLink ? 'i' : marker.icon.includes('house') ? '⌂'
        : marker.icon.includes('up') ? '↑' : '•';
      element.addEventListener('keydown', event => {
        if (event.key === 'Enter' || event.key === ' ') {
          event.preventDefault();
          element.click();
        }
      });
      if (isLink) {
        const caption = document.createElement('span');
        caption.className = 'hotspot-label';
        caption.textContent = label;
        element.append(caption);
      }
    },
  };
}

async function start() {
  const response = await fetch('data/tour.json');
  if (!response.ok) throw new Error('Tour data unavailable');
  const { firstScene, scenes, floorplan } = await response.json();
  const byId = new Map(scenes.map(scene => [scene.id, scene]));
  const requested = new URLSearchParams(location.search).get('room');
  const reducedMotion = matchMedia('(prefers-reduced-motion: reduce)').matches;
  function select(marker) {
    if (viewer.isLoaded()) {
      viewer.loadScene(marker.target, marker.targetPitch ?? undefined, marker.targetYaw ?? undefined);
    }
  }
  const viewer = pannellum.viewer('panorama', {
    default: {
      firstScene: byId.has(requested) ? requested : firstScene,
      autoLoad: true,
      escapeHTML: true,
      compass: true,
      ignoreGPanoXMP: true,
    },
    scenes: Object.fromEntries(scenes.map(scene => [scene.id, {
      type: 'equirectangular',
      panorama: scene.panorama,
      preview: scene.preview,
      pitch: scene.pitch,
      yaw: scene.yaw,
      hfov: scene.hfov,
      northOffset: scene.northOffset,
      sceneFadeDuration: reducedMotion ? 0 : scene.fadeMs,
      hotSpots: scene.hotspots.map(marker => hotspot(
        marker.target === firstScene ? { ...marker, pitch: scene.pitch + 32 } : marker,
        select,
      )),
    }])),
  });
  const prefetched = new Set();
  let prefetching = 0;
  function showScene(id) {
    const index = scenes.indexOf(byId.get(id));
    title.textContent = scenes[index].title;
    document.body.dataset.scene = id;
    panorama.setAttribute('aria-busy', 'true');
    previous.hidden = index === 0;
    next.hidden = index === scenes.length - 1;
  }
  function step(direction) {
    const index = scenes.indexOf(byId.get(viewer.getScene()));
    const scene = scenes[index + direction];
    if (scene && viewer.isLoaded()) viewer.loadScene(scene.id);
  }
  previous.addEventListener('click', () => step(-1));
  next.addEventListener('click', () => step(1));
  if (floorplan) {
    const mapButton = document.querySelector('#map-button');
    mapButton.hidden = false;
    mapButton.addEventListener('click', () => showMap(floorplan, viewer));
  }
  viewer.on('scenechange', showScene);
  viewer.on('load', () => {
    panorama.setAttribute('aria-busy', 'false');
    statusLabel.hidden = true;
    const scene = byId.get(viewer.getScene());
    if (navigator.connection?.saveData) return;
    const neighbors = [...new Set(scene.hotspots.map(marker => marker.target).filter(Boolean))];
    for (const target of neighbors.slice(0, 2)) {
      if (prefetching >= 2) break;
      const url = byId.get(target).panorama;
      if (prefetched.has(url)) continue;
      prefetched.add(url);
      prefetching++;
      fetch(url, { cache: 'force-cache', priority: 'low' })
        .then(response => {
          if (!response.ok) throw new Error('Prefetch failed');
          return response.arrayBuffer();
        })
        .catch(() => prefetched.delete(url))
        .finally(() => prefetching--);
    }
  });
  viewer.on('error', () => {
    panorama.setAttribute('aria-busy', 'false');
    statusLabel.hidden = false;
    statusLabel.textContent = 'Không tải được ảnh 360°. Hãy mở lại tour.';
  });
  dialog.addEventListener('close', () => content.replaceChildren());
  showScene(viewer.getScene());
}

start().catch(() => {
  statusLabel.textContent = 'Chưa tải được dữ liệu tour. Hãy mở tour gốc bên dưới.';
});
