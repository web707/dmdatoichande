const title = document.querySelector('#scene-title');
const headerBadge = document.querySelector('#header-badge');
const statusLabel = document.querySelector('#status');
const panorama = document.querySelector('#panorama');
const previous = document.querySelector('#previous');
const next = document.querySelector('#next');
const dialog = document.querySelector('#details');
const content = document.querySelector('#content');
const closeDialog = document.querySelector('#close-dialog');

const audioButton = document.querySelector('#audio-button');
const narration = document.querySelector('#narration');
const transcriptButton = document.querySelector('#transcript-button');
const transcriptCard = document.querySelector('#transcript-card');
const transcriptHeading = document.querySelector('#transcript-heading');
const transcriptText = document.querySelector('#transcript-text');
const transcriptClose = document.querySelector('#transcript-close');

const btnLangVi = document.querySelector('#btn-lang-vi');
const btnLangEn = document.querySelector('#btn-lang-en');

let currentLang = 'vi'; // 'vi' or 'en'
let audioAutoPlay = false;

if (closeDialog) {
  closeDialog.addEventListener('click', () => {
    dialog.close();
  });
}
dialog.addEventListener('click', (event) => {
  if (event.target === dialog) {
    dialog.close();
  }
});

function showInfo(marker) {
  content.innerHTML = '';
  const extBtn = document.querySelector('#dialog-external');
  const titleEl = document.querySelector('#dialog-title');
  dialog.classList.remove('is-floorplan', 'is-media', 'is-frame');

  if (marker.type === 'image') {
    dialog.classList.add('is-media');
    if (extBtn) extBtn.hidden = true;
    if (titleEl) titleEl.textContent = currentLang === 'en' ? 'Location Photo' : 'Hình ảnh tư liệu';
    const img = document.createElement('img');
    img.className = 'info-img';
    img.src = marker.url + (marker.url.includes('?') ? '&' : '?') + 'v=clean';
    img.alt = 'Hình ảnh tư liệu';
    content.append(img);
  } else if (marker.type === 'video') {
    dialog.classList.add('is-media');
    if (extBtn) extBtn.hidden = true;
    if (titleEl) titleEl.textContent = currentLang === 'en' ? 'Location Video' : 'Video tư liệu';
    const video = document.createElement('video');
    video.className = 'info-video';
    video.src = marker.url;
    video.controls = true;
    video.autoplay = true;
    video.playsInline = true;
    content.append(video);
  } else {
    // Interactive article / past-present comparison webpage
    dialog.classList.add('is-frame');
    if (extBtn) {
      extBtn.hidden = false;
      extBtn.href = marker.url;
      extBtn.textContent = currentLang === 'en' ? '↗ Click to view details' : '↗ Ấn để xem chi tiết';
    }
    if (titleEl) {
      titleEl.textContent = currentLang === 'en' ? 'Interactive Heritage Story' : 'Tư liệu lịch sử & Di tích';
    }
    const iframe = document.createElement('iframe');
    iframe.className = 'info-frame';
    iframe.src = marker.url;
    iframe.title = 'Thông tin tư liệu';
    iframe.setAttribute('allow', 'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share');
    iframe.setAttribute('allowfullscreen', 'true');
    content.append(iframe);
  }
  dialog.showModal();
}

function showMap(floorplan, viewer) {
  content.innerHTML = '';
  const extBtn = document.querySelector('#dialog-external');
  const titleEl = document.querySelector('#dialog-title');
  if (extBtn) extBtn.hidden = true;
  if (titleEl) titleEl.textContent = currentLang === 'en' ? 'Tour Map & Floorplan' : 'Bản đồ di tích';
  dialog.classList.remove('is-media', 'is-frame');
  dialog.classList.add('is-floorplan');

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
  const label = isLink ? marker.label : (currentLang === 'en' ? 'Point of interest' : 'Thông tin địa điểm');
  return {
    pitch: marker.pitch,
    yaw: marker.yaw,
    type: 'info',
    cssClass: 'lake-hotspot',
    clickHandlerFunc: () => isLink ? select(marker) : showInfo(marker),
    createTooltipFunc(element) {
      element.dataset.hotspot = marker.id;
      element.tabIndex = 0;
      element.setAttribute('role', 'button');
      element.setAttribute('aria-label', label);
      element.innerHTML = '';

      const iconWrapper = document.createElement('div');
      iconWrapper.className = 'hotspot-icon';

      if (!isLink) {
        element.classList.add('is-info');
        iconWrapper.innerHTML = `
          <svg viewBox="0 0 24 24" class="svg-icon svg-info" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round">
            <circle cx="12" cy="12" r="9.5"></circle>
            <line x1="12" y1="16" x2="12" y2="12"></line>
            <circle cx="12" cy="8" r="1" fill="currentColor"></circle>
          </svg>`;
      } else if (marker.icon && marker.icon.includes('house')) {
        element.classList.add('is-house');
        iconWrapper.innerHTML = `
          <svg viewBox="0 0 24 24" class="svg-icon svg-house" fill="currentColor">
            <path d="M12 3L2 12h3v8h6v-6h2v6h6v-8h3L12 3z"></path>
          </svg>`;
      } else {
        element.classList.add('is-nav');
        // Elegant forward dual navigation chevrons
        iconWrapper.innerHTML = `
          <svg viewBox="0 0 24 24" class="svg-icon svg-arrow" fill="none" stroke="currentColor" stroke-width="2.8" stroke-linecap="round" stroke-linejoin="round">
            <polyline points="6 11 12 5 18 11"></polyline>
            <polyline points="6 17 12 11 18 17" opacity="0.6"></polyline>
          </svg>`;
      }
      element.append(iconWrapper);

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
  const response = await fetch('data/tour.json?v=' + Date.now());
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

  function getAudioUrl(scene) {
    let url = null;
    if (currentLang === 'en') {
      url = scene.audioEn || scene.audioVi || scene.audio;
    } else {
      url = scene.audioVi || scene.audio;
    }
    if (!url) return null;
    return url + (url.includes('?') ? '&' : '?') + 'v=boosted';
  }

  function getSceneTitle(scene) {
    if (currentLang === 'en' && scene.titleEn) return scene.titleEn;
    return scene.titleVi || scene.title;
  }

  function getSceneTranscript(scene) {
    if (currentLang === 'en' && scene.textEn) return scene.textEn;
    return scene.textVi || '';
  }

  function updateAudioForScene(scene) {
    if (!narration || !audioButton) return;
    narration.volume = 1.0;
    const audioUrl = getAudioUrl(scene);
    if (audioUrl) {
      audioButton.hidden = false;
      const wasPlaying = !narration.paused;
      narration.src = audioUrl;
      if (audioAutoPlay || wasPlaying) {
        narration.play().then(() => {
          audioButton.classList.add('active');
          audioButton.textContent = currentLang === 'en' ? '⏸ Pause' : '⏸ Tạm dừng';
        }).catch(() => {
          audioButton.classList.remove('active');
          audioButton.textContent = currentLang === 'en' ? '🔊 Narration' : '🔊 Thuyết minh';
        });
      } else {
        audioButton.classList.remove('active');
        audioButton.textContent = currentLang === 'en' ? '🔊 Narration' : '🔊 Thuyết minh';
      }
    } else {
      audioButton.hidden = true;
      narration.pause();
    }
  }

  function updateTranscript(scene) {
    if (!transcriptButton || !transcriptCard) return;
    const text = getSceneTranscript(scene);
    if (text) {
      transcriptButton.hidden = false;
      transcriptHeading.textContent = currentLang === 'en' ? 'Narration Transcript' : 'Lời thuyết minh';
      transcriptText.textContent = text;
      transcriptButton.textContent = currentLang === 'en' ? '📜 Transcript' : '📜 Lời thoại';
    } else {
      transcriptButton.hidden = true;
      transcriptCard.classList.add('hidden');
    }
  }

  function showScene(id) {
    const scene = byId.get(id);
    const index = scenes.indexOf(scene);
    title.textContent = scene ? getSceneTitle(scene) : '';
    document.body.dataset.scene = id;
    panorama.setAttribute('aria-busy', 'true');
    previous.hidden = index === 0;
    next.hidden = index === scenes.length - 1;
    updateAudioForScene(scene);
    updateTranscript(scene);
  }

  // Language Switch handlers
  if (btnLangVi && btnLangEn) {
    btnLangVi.addEventListener('click', () => {
      if (currentLang === 'vi') return;
      currentLang = 'vi';
      btnLangVi.classList.add('active');
      btnLangEn.classList.remove('active');
      headerBadge.textContent = 'HỒ GƯƠM · VR360';
      const mapBtn = document.querySelector('#map-button');
      if (mapBtn) mapBtn.textContent = '🗺️ Bản đồ';
      const currentScene = byId.get(viewer.getScene());
      if (currentScene) showScene(currentScene.id);
    });

    btnLangEn.addEventListener('click', () => {
      if (currentLang === 'en') return;
      currentLang = 'en';
      btnLangEn.classList.add('active');
      btnLangVi.classList.remove('active');
      headerBadge.textContent = 'HOAN KIEM LAKE · VR360';
      const mapBtn = document.querySelector('#map-button');
      if (mapBtn) mapBtn.textContent = '🗺️ Map';
      const currentScene = byId.get(viewer.getScene());
      if (currentScene) showScene(currentScene.id);
    });
  }

  // Transcript Button & Card Handlers
  if (transcriptButton && transcriptCard) {
    transcriptButton.addEventListener('click', () => {
      const isHidden = transcriptCard.classList.contains('hidden');
      if (isHidden) {
        transcriptCard.classList.remove('hidden');
        transcriptButton.classList.add('active');
      } else {
        transcriptCard.classList.add('hidden');
        transcriptButton.classList.remove('active');
      }
    });
  }

  if (transcriptClose && transcriptCard) {
    transcriptClose.addEventListener('click', () => {
      transcriptCard.classList.add('hidden');
      if (transcriptButton) transcriptButton.classList.remove('active');
    });
  }

  // Audio Button Handlers
  if (audioButton && narration) {
    audioButton.addEventListener('click', () => {
      if (narration.paused) {
        audioAutoPlay = true;
        narration.play().then(() => {
          audioButton.classList.add('active');
          audioButton.textContent = currentLang === 'en' ? '⏸ Pause' : '⏸ Tạm dừng';
        }).catch(e => console.warn('Audio play failed:', e));
      } else {
        audioAutoPlay = false;
        narration.pause();
        audioButton.classList.remove('active');
        audioButton.textContent = currentLang === 'en' ? '🔊 Narration' : '🔊 Thuyết minh';
      }
    });

    narration.addEventListener('ended', () => {
      audioButton.classList.remove('active');
      audioButton.textContent = currentLang === 'en' ? '🔊 Narration' : '🔊 Thuyết minh';
    });
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
    if (mapButton) {
      mapButton.hidden = false;
      mapButton.addEventListener('click', () => showMap(floorplan, viewer));
    }
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
    statusLabel.textContent = currentLang === 'en'
      ? 'Failed to load 360° panorama. Please reload.'
      : 'Không tải được ảnh 360°. Hãy mở lại tour.';
  });

  dialog.addEventListener('close', () => content.replaceChildren());
  showScene(viewer.getScene());
}

start().catch((err) => {
  console.error('Failed to start VR360 tour:', err);
  statusLabel.textContent = 'Chưa tải được dữ liệu tour. Hãy mở tour gốc bên dưới.';
});
