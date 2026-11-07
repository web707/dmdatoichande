import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:panorama_viewer/panorama_viewer.dart';

typedef _Json = Map<String, dynamic>;
const _mapDotSize = 24.0;

// PDC faces yaw 270 at the center of the image. The Flutter sphere faces
// longitude 0 there and its longitude increases in the opposite direction.
double _longitude(num yaw) => ((450 - yaw) % 360 - 180).toDouble();

class VR360TourPage extends StatefulWidget {
  const VR360TourPage({super.key});

  @override
  State<VR360TourPage> createState() => _VR360TourPageState();
}

class _VR360TourPageState extends State<VR360TourPage> {
  late Future<_Json> _tour = _loadTour();
  AudioPlayer? _player;
  String? _sceneId;
  double? _arrivalYaw;
  String _language = 'en';
  String? _activeTrack;
  bool _audioBusy = false;

  Future<_Json> _loadTour() async =>
      jsonDecode(await rootBundle.loadString('assets/vr360/tour.json'))
          as _Json;

  @override
  void dispose() {
    unawaited(_player?.dispose());
    super.dispose();
  }

  Future<void> _audioAction(Future<void> Function() run) async {
    setState(() => _audioBusy = true);
    try {
      await run();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Narration could not be played.')),
        );
      }
    } finally {
      if (mounted) setState(() => _audioBusy = false);
    }
  }

  void _selectScene(_Json scene, {double? yaw}) {
    if (_audioBusy || scene['id'] == _sceneId) return;
    setState(() {
      _sceneId = scene['id'] as String;
      _arrivalYaw = yaw;
    });
    if (_activeTrack != null &&
        _activeTrack != (scene['audio'] as Map)[_language]) {
      _stopNarration();
    }
  }

  void _stopNarration() {
    final player = _player;
    _activeTrack = null;
    if (player != null) unawaited(_audioAction(player.stop));
  }

  void _playNarration(String track) {
    if (_audioBusy) return;
    final player = _player ??= AudioPlayer();
    unawaited(
      _audioAction(() async {
        if (_activeTrack == track && player.state == PlayerState.playing) {
          await player.pause();
        } else if (_activeTrack == track &&
            player.state == PlayerState.paused) {
          await player.resume();
        } else {
          await player.play(AssetSource('vr360/$track'));
          _activeTrack = track;
        }
      }),
    );
  }

  String _title(_Json scene) =>
      scene[_language == 'en' ? 'titleEn' : 'title'] as String;

  void _showMarker(_Json marker) {
    final english = _language == 'en';
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(marker[english ? 'titleEn' : 'title'] as String),
        content: SingleChildScrollView(
          child: Text(
            (marker[english ? 'contentEn' : 'content'] as List).join('\n\n'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _chooseScene(List<_Json> scenes, String current) async {
    final selected = await showDialog<_Json>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Tour scenes'),
        children: [
          for (final scene in scenes)
            ListTile(
              leading: Text('${scenes.indexOf(scene) + 1}'),
              title: Text(_title(scene)),
              selected: scene['id'] == current,
              onTap: () => Navigator.pop(context, scene),
            ),
        ],
      ),
    );
    if (mounted && selected != null) _selectScene(selected);
  }

  Future<void> _showMap(_Json tour, List<_Json> scenes, String current) async {
    final points = <String, Offset>{};
    for (final scene in scenes) {
      final position = scene['position'] as _Json?;
      if (position != null) {
        points[scene['id'] as String] = Offset(
          (position['x'] as num).toDouble() / 100,
          (position['y'] as num).toDouble() / 100,
        );
      }
    }
    final selected = await showDialog<_Json>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tour map'),
        content: SizedBox(
          width: 440,
          height: 320,
          child: LayoutBuilder(
            builder: (context, bounds) {
              final area = Size(bounds.maxWidth, bounds.maxHeight);
              return Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _TourPaths(
                        points,
                        (tour['mapRoutes'] as List).cast<_Json>(),
                      ),
                    ),
                  ),
                  for (final (index, scene) in scenes.indexed)
                    if (points[scene['id']] case final point?)
                      Positioned(
                        left: point.dx * (area.width - _mapDotSize),
                        top: point.dy * (area.height - _mapDotSize),
                        width: _mapDotSize,
                        height: _mapDotSize,
                        child: IconButton.filledTonal(
                          padding: EdgeInsets.zero,
                          isSelected: scene['id'] == current,
                          style: IconButton.styleFrom(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            minimumSize: const Size.square(_mapDotSize),
                            backgroundColor: scene['id'] == current
                                ? Theme.of(context).colorScheme.primary
                                : null,
                            foregroundColor: scene['id'] == current
                                ? Colors.white
                                : null,
                          ),
                          tooltip: _title(scene),
                          icon: Text('${index + 1}'),
                          onPressed: () => Navigator.pop(context, scene),
                        ),
                      ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
    if (mounted && selected != null) _selectScene(selected);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<_Json>(
    future: _tour,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(
          child: FilledButton(
            onPressed: () => setState(() => _tour = _loadTour()),
            child: const Text('Could not load the tour. Retry'),
          ),
        );
      }
      final tour = snapshot.data;
      if (tour == null) return const Center(child: CircularProgressIndicator());
      return _buildTour(tour);
    },
  );

  Widget _buildTour(_Json tour) {
    final scenes = (tour['scenes'] as List).cast<_Json>();
    final scene = scenes.firstWhere(
      (scene) => scene['id'] == (_sceneId ?? tour['entrySceneId']),
    );
    final id = scene['id'] as String;
    final track = (scene['audio'] as Map)[_language] as String?;
    final markers = (scene['markers'] as List).cast<_Json>();
    final links = (scene['links'] as List).cast<_Json>();
    final nextScenes = {for (final other in scenes) other['id']: other};
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Back to VR360',
                onPressed: () => context.go('/tools/vr360'),
                icon: const Icon(Icons.arrow_back),
              ),
              Expanded(
                child: Text(
                  _title(scene),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text('${scenes.indexOf(scene) + 1}/${scenes.length}'),
            ],
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ColoredBox(
                color: const Color(0xFF182824),
                child: PanoramaViewer(
                  key: ValueKey(id),
                  longitude: _longitude(_arrivalYaw ?? scene['yaw'] as num),
                  latitude: (scene['pitch'] as num).toDouble(),
                  latSegments: 24,
                  lonSegments: 48,
                  hotspots: [
                    for (final link in links)
                      Hotspot(
                        longitude: _longitude(link['yaw'] as num),
                        latitude: (link['pitch'] as num).toDouble(),
                        width: 46,
                        height: 46,
                        widget: IconButton.filled(
                          tooltip:
                              'Go to ${_title(nextScenes[link['targetId']]!)}',
                          onPressed: _audioBusy
                              ? null
                              : () => _selectScene(
                                  nextScenes[link['targetId']]!,
                                  yaw: (link['nextYaw'] as num?)?.toDouble(),
                                ),
                          icon: const Icon(Icons.arrow_upward_rounded),
                        ),
                      ),
                    for (final marker in markers)
                      Hotspot(
                        longitude: _longitude(marker['yaw'] as num),
                        latitude: (marker['pitch'] as num).toDouble(),
                        width: 40,
                        height: 40,
                        widget: IconButton.filledTonal(
                          tooltip:
                              marker[_language == 'en' ? 'titleEn' : 'title']
                                  as String,
                          onPressed: () => _showMarker(marker),
                          icon: const Icon(Icons.info_outline),
                        ),
                      ),
                  ],
                  child: Image.asset('assets/vr360/${scene['image']}'),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Wrap(
              spacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: _audioBusy ? null : () => _chooseScene(scenes, id),
                  icon: const Icon(Icons.layers_outlined),
                  label: const Text('Scenes'),
                ),
                TextButton.icon(
                  onPressed: _audioBusy
                      ? null
                      : () => _showMap(tour, scenes, id),
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Tour map'),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Tour language',
                  enabled: !_audioBusy,
                  initialValue: _language,
                  onSelected: (language) {
                    if (language == _language) return;
                    setState(() => _language = language);
                    _stopNarration();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'en', child: Text('English')),
                    PopupMenuItem(value: 'vi', child: Text('Tiếng Việt')),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(_language == 'en' ? 'English' : 'Tiếng Việt'),
                  ),
                ),
                if (track != null)
                  StreamBuilder<PlayerState>(
                    stream: _player?.onPlayerStateChanged,
                    builder: (_, snapshot) {
                      final playing =
                          _activeTrack == track &&
                          (_player?.state == PlayerState.playing);
                      return TextButton.icon(
                        onPressed: _audioBusy
                            ? null
                            : () => _playNarration(track),
                        icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                        label: Text(playing ? 'Pause narration' : 'Narration'),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TourPaths extends CustomPainter {
  final Map<String, Offset> points;
  final List<_Json> routes;
  const _TourPaths(this.points, this.routes);

  @override
  void paint(Canvas canvas, Size size) {
    final brush = Paint()
      ..color = const Color(0xFFAABDB1)
      ..strokeWidth = 2;
    Offset center(Offset point) => Offset(
      _mapDotSize / 2 + point.dx * (size.width - _mapDotSize),
      _mapDotSize / 2 + point.dy * (size.height - _mapDotSize),
    );
    for (final route in routes) {
      final from = points[route['from']];
      final to = points[route['to']];
      if (from != null && to != null) {
        canvas.drawLine(center(from), center(to), brush);
      }
    }
  }

  @override
  bool shouldRepaint(_TourPaths oldDelegate) =>
      oldDelegate.points != points || oldDelegate.routes != routes;
}
