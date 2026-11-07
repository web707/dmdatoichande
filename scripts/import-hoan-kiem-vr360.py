"""Archive the upstream tour locally and build its optimized runtime data."""

from concurrent.futures import ThreadPoolExecutor
from hashlib import sha256
from io import BytesIO
import json
from pathlib import Path
import re
from tempfile import NamedTemporaryFile
from urllib.parse import urlparse
from urllib.request import urlopen

from PIL import Image

SOURCE = 'https://nhandan.vn/megastory/2026/VR360-ho-hoan-kiem/'
ROOT = Path(__file__).resolve().parents[1] / '.local/vr360/hoan-kiem'
ARCHIVE = ROOT / 'source'
PUBLIC = ROOT / 'public'


def write_atomic(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    with NamedTemporaryFile(dir=path.parent, delete=False) as temporary:
        temporary.write(data)
    try:
        Path(temporary.name).replace(path)
    finally:
        Path(temporary.name).unlink(missing_ok=True)


def archive(relative, *, refresh=False):
    path = ARCHIVE / relative.split('?')[0]
    if not refresh and path.exists():
        return path.read_bytes()
    with urlopen(SOURCE + relative, timeout=40) as response:
        data = response.read()
    write_atomic(path, data)
    return data


def publish(name, extension, content):
    filename = f'{name}-{sha256(content).hexdigest()[:16]}.{extension}'
    write_atomic(PUBLIC / 'assets' / filename, content)
    return f'data/assets/{filename}'


def webp(image, name, size, quality):
    result = image.copy()
    result.thumbnail(size, Image.Resampling.LANCZOS)
    data = BytesIO()
    result.save(data, 'WEBP', quality=quality, method=6)
    return publish(name, 'webp', data.getvalue())


def marker_data(marker, room_ids):
    kind = marker['type']
    item = {key: marker[key] for key in ('id', 'yaw', 'pitch', 'type')}
    if kind == 'marker':
        target = str(marker['id_room_target'])
        if target not in room_ids:
            raise ValueError(f'Unknown destination {target}')
        return item | {
            'target': target,
            'label': marker['name_room_target'].strip(),
            'icon': marker['icon'],
            'targetPitch': marker['pitch_room_target'],
            'targetYaw': marker['yaw_room_target'],
        }

    content = marker['content']
    if kind == 'image' and re.fullmatch(r'content/content_[a-z0-9]+\.png', content):
        with Image.open(BytesIO(archive(content))) as image:
            return item | {'url': webp(image, f'info-{marker["id"]}', (1600, 1600), 90)}
    if kind == 'link' and urlparse(content).scheme == 'https':
        return item | {'url': content}
    if kind == 'video' and re.fullmatch(r'content/content_[a-z0-9]+\.mp4', content):
        return item | {'url': publish(f'video-{marker["id"]}', 'mp4', archive(content))}
    raise ValueError(f'Unsupported content for hotspot {marker["id"]}')


def scene_data(room, room_ids, duration):
    filename = room['panorama_image']
    if room['type'] != 'image' or not re.fullmatch(r'pano_[a-z0-9]+\.jpg', filename):
        raise ValueError(f'Unsupported panorama {filename}')
    scene_id = str(room['id'])
    with Image.open(BytesIO(archive('panoramas/' + filename))) as image:
        if image.width != 2 * image.height:
            raise ValueError(f'Invalid 360° image ratio for scene {scene_id}')
        panorama = webp(image, f'scene-{scene_id}', (3072, 1536), 80)
        preview = webp(image, f'preview-{scene_id}', (1024, 512), 70)
    fade = room['transition_time'] if room['transition_override'] else duration
    return {
        'id': scene_id,
        'title': room['name'].strip(),
        'panorama': panorama,
        'preview': preview,
        'pitch': room['pitch'],
        'yaw': room['yaw'],
        'hfov': room['hfov'],
        'northOffset': room['northOffset'],
        'fadeMs': max(0, min(400, int(fade))),
        'hotspots': [marker_data(marker, room_ids) for marker in room['markers']],
    }


def floorplan_data(rooms):
    source = json.loads(archive('ajax/maps.json', refresh=True))
    floorplan = next(item for item in source['maps'] if item['map_type'] == 'floorplan')
    filename = floorplan['map']
    if not re.fullmatch(r'map_[a-z0-9]+\.png', filename):
        raise ValueError('Invalid floorplan image name')
    with Image.open(BytesIO(archive('maps/' + filename))) as image:
        url = webp(image, 'floorplan', (1600, 1600), 90)
    return {
        'title': floorplan['name'],
        'url': url,
        'points': [
            {'id': str(room['id']), 'label': room['name'].strip(),
             'x': room['map_left'] / 3, 'y': room['map_top'] * floorplan['map_ratio'] / 3}
            for room in rooms if room['id_map'] == floorplan['id']
            and room['map_left'] is not None and room['map_top'] is not None
        ],
    }


def main():
    html = archive('index.html', refresh=True).decode('utf-8')
    source = json.loads(archive('ajax/rooms.json', refresh=True))
    rooms = source['rooms']
    room_ids = {str(room['id']) for room in rooms}
    if source['status'] != 'ok' or '9861' not in room_ids or len(rooms) != len(room_ids):
        raise ValueError('Source tour does not contain a usable scene list')

    for filename in ('index.js', 'script.js'):
        match = re.search(rf'src="(js/{re.escape(filename)}(?:\?[^"<>]*)?)"', html)
        if not match:
            raise ValueError(f'Missing source script {filename}')
        archive(match[1], refresh=True)

    with ThreadPoolExecutor(max_workers=4) as executor:
        scenes = list(executor.map(
            lambda room: scene_data(room, room_ids, source['transition_time']), rooms
        ))
    manifest = {'firstScene': '9861', 'scenes': scenes, 'floorplan': floorplan_data(rooms)}
    write_atomic(PUBLIC / 'tour.json', json.dumps(manifest, ensure_ascii=False).encode('utf-8'))
    print(f'Imported {len(scenes)} panoramas and {sum(len(s["hotspots"]) for s in scenes)} hotspots.')
    print(f'Runtime data: {PUBLIC}')


if __name__ == '__main__':
    main()
