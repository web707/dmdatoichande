import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/store.dart';
import '../core/widgets.dart';
import 'hoan_kiem_viewer_native.dart'
    if (dart.library.js_interop) 'hoan_kiem_viewer_web.dart';

const hoanKiemLakePlaceId = '10000000-0000-4000-8000-000000000001';
const hoanKiemTourPath = '/tools/vr360/hoan-kiem';
const _source = 'https://nhandan.vn/megastory/2026/VR360-ho-hoan-kiem/';

class HoanKiemTourButton extends StatelessWidget {
  const HoanKiemTourButton({super.key});

  @override
  Widget build(BuildContext context) => FilledButton.tonalIcon(
    icon: const Icon(Icons.view_in_ar_outlined),
    label: const Text('Explore in VR360'),
    onPressed: () => context.push(hoanKiemTourPath),
  );
}

class HoanKiemTourPage extends ConsumerWidget {
  const HoanKiemTourPage({super.key, this.sceneId});

  final String? sceneId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scene = _scenes.firstWhere(
      (scene) => scene.id == sceneId,
      orElse: () => _scenes.first,
    );
    final url = Uri.parse(_source).replace(queryParameters: {'room': scene.id});
    final api = ref.read(guideProvider).api;
    final viewerUrl = Uri.parse(api.effectiveBaseUrl)
        .resolve('/vr360/hoan-kiem/index.html')
        .replace(queryParameters: {'room': scene.id});
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Back',
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/tools/vr360'),
              icon: const Icon(Icons.arrow_back),
            ),
            Expanded(
              child: Text(
                'Hoan Kiem Lake in 360°',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            TextButton(
              onPressed: () => _chooseScene(context),
              child: Text('All ${_scenes.length} scenes'),
            ),
          ],
        ),
        Expanded(
          key: const ValueKey('hoan-kiem-tour-viewer'),
          child: HoanKiemViewer(key: ValueKey(viewerUrl), url: viewerUrl),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: SourceLink(url.toString(), label: 'Open on Báo Nhân Dân'),
        ),
      ],
    );
  }

  Future<void> _chooseScene(BuildContext context) async {
    final selected = await showDialog<_LakeScene>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Tour scenes'),
        children: [
          for (final (index, scene) in _scenes.indexed)
            ListTile(
              leading: CircleAvatar(child: Text('${index + 1}')),
              title: Text(scene.title),
              subtitle: Text('${scene.nameVi}\n${scene.description}'),
              onTap: () => Navigator.pop(context, scene),
            ),
        ],
      ),
    );
    if (context.mounted && selected != null) {
      context.replace('$hoanKiemTourPath/${selected.id}');
    }
  }
}

class _LakeScene {
  const _LakeScene(this.id, this.title, this.nameVi, this.description);

  final String id, title, nameVi, description;
}

// IDs correspond to the original tour's public scenes.
const _scenes = [
  _LakeScene(
    '9861',
    'Hoan Kiem Lake from above',
    'Hồ Gươm trên cao',
    'Start above the lake to see how Turtle Tower, the temple island and the streets of central Hanoi fit together.',
  ),
  _LakeScene(
    '9847',
    'Hoan Kiem Lake',
    'Hồ Gươm',
    'Look across the water for Turtle Tower on its small island. The lake’s name recalls the legend of King Lê Lợi returning a magical sword to a turtle.',
  ),
  _LakeScene(
    '9848',
    'Ngoc Son Temple',
    'Đền Ngọc Sơn',
    'Visit the temple on Jade Island, reached by the red Thê Húc Bridge. The temple honours figures including the military commander Trần Hưng Đạo.',
  ),
  _LakeScene(
    '9849',
    'Ba Kieu Temple',
    'Đền Bà Kiệu',
    'Find the temple on Đinh Tiên Hoàng Street opposite the entrance to Ngọc Sơn Temple. It is a place of worship in Vietnam’s Mother Goddess tradition.',
  ),
  _LakeScene(
    '9850',
    'Hanoi Defenders Monument',
    'Tượng đài Cảm tử',
    'Look closely at the sculpted figures near Bà Kiệu Temple. The memorial commemorates those who fought to defend Hanoi at the start of the First Indochina War.',
  ),
  _LakeScene(
    '9851',
    'Báo Nhân Dân headquarters',
    'Báo Nhân Dân',
    'See the newspaper’s headquarters on Hàng Trống Street. Báo Nhân Dân produced the original 360° tour.',
  ),
  _LakeScene(
    '9852',
    'Nhân Dân banyan tree',
    'Cây đa Nhân Dân',
    'Look upward at the banyan beside the Báo Nhân Dân headquarters. This scene places you beneath the tree’s canopy.',
  ),
  _LakeScene(
    '9853',
    'Nam Huong Communal House',
    'Đình Nam Hương',
    'Explore a communal house in the lakeside Hàng Trống area. It preserves royal decrees and other objects connected with the worship of local guardian deities.',
  ),
  _LakeScene(
    '9855',
    'King Le Thai To Temple',
    'Đền vua Lê Thái Tổ',
    'Look for the statue of King Lê Thái Tổ and the small pavilion in the memorial grounds. The site connects the historical ruler with the lake’s sword legend.',
  ),
  _LakeScene(
    '9856',
    'Hanoi Post Office',
    'Bưu điện Hà Nội',
    'Look up at the clock tower of the Hanoi Post Office on Đinh Tiên Hoàng Street, a familiar landmark along the eastern shore.',
  ),
  _LakeScene(
    '9857',
    'Bac Bo Phu',
    'Bắc Bộ Phủ',
    'See the former seat of government in northern Vietnam on Ngô Quyền Street. The building is associated with Hanoi’s August Revolution of 1945.',
  ),
  _LakeScene(
    '9858',
    'Ly Thai To Garden',
    'Vườn hoa Lý Thái Tổ',
    'Look for the statue of Lý Thái Tổ, the king who moved the capital to Thăng Long, now Hanoi, in 1010.',
  ),
  _LakeScene(
    '9859',
    'Hanoi City Hall',
    'UBND TP Hà Nội',
    'See the headquarters of the Hanoi People’s Committee from the lakeside street. The building stands near the city’s post office and Lý Thái Tổ Garden.',
  ),
  _LakeScene(
    '9860',
    'The Huc Bridge',
    'Cầu Thê Húc',
    'Follow the red wooden bridge from the shore toward Ngọc Sơn Temple. Turn to either side for views of the lake from the crossing.',
  ),
];
