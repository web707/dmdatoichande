import { copyFile, mkdir, writeFile } from 'node:fs/promises';
import { basename, join, resolve } from 'node:path';
import { createRequire } from 'node:module';
import { fileURLToPath, pathToFileURL } from 'node:url';

if (!process.argv[2]) throw new Error('Usage: node scripts/import-vr360.mjs <pdc-vr360 directory>');
const source = resolve(process.argv[2]);
const output = fileURLToPath(new URL('../assets/vr360/', import.meta.url));
const { dinhDenDinhCongTour: tour } = await import(pathToFileURL(join(source, 'src/tours/dinh-den-dinh-cong.ts')));
const requireFromSource = createRequire(join(source, 'package.json'));
const sharp = requireFromSource('sharp');
const titles = [
  'Communal house gate', 'Courtyard by the ponds', 'Inner courtyard entrance',
  'Garden between the ponds', 'Courtyard and ancient tree', 'Main hall courtyard',
  'Screen wall and pillars', 'Main ceremonial hall', 'Temple stone screen',
  'Temple courtyard', 'Goldsmith Ancestors Temple', 'Inside the temple',
  'Festival stage', 'Aerial overview', 'Dinh Cong panorama',
];
const copiedAudio = new Set();
for (const directory of ['panoramas', 'en', 'vi']) await mkdir(join(output, directory), { recursive: true });
const scenes = [];
for (const scene of tour.scenes) {
  const image = `panoramas/${basename(scene.image)}`;
  await sharp(join(source, 'public', scene.image)).resize({ width: 3072, withoutEnlargement: true })
    .webp({ quality: 80 }).toFile(join(output, image));
  const audio = {};
  for (const [language, narration] of [['en', tour.sceneNarrationEn], ['vi', tour.sceneNarration]]) {
    const track = narration.get(scene.id)?.[0];
    if (!track) continue;
    audio[language] = `${language}/${basename(track)}`;
    if (!copiedAudio.has(track)) {
      await copyFile(join(source, 'public', track), join(output, audio[language]));
      copiedAudio.add(track);
    }
  }
  scenes.push({
    id: scene.id,
    title: scene.title,
    titleEn: titles[Number(scene.order) - 1] ?? scene.title,
    image,
    yaw: scene.initialYaw,
    pitch: scene.initialPitch,
    position: scene.hideOnMap ? null : scene.mapPosition,
    links: scene.hotspots.filter((link) => !link.hidden).map(({ targetId, yaw, pitch, nextYaw }) => ({ targetId, yaw, pitch, nextYaw })),
    markers: (scene.infoMarkers ?? []).map(({ id, yaw, pitch, title, titleEn, content, contentEn }) => ({ id, yaw, pitch, title, titleEn, content, contentEn })),
    audio,
  });
}
await writeFile(join(output, 'tour.json'), JSON.stringify({
  title: tour.title,
  entrySceneId: tour.entrySceneId,
  mapRoutes: tour.mapRoutes,
  scenes,
}, null, 2) + '\n');
console.log(`Imported ${scenes.length} scenes and ${copiedAudio.size} tracks.`);
