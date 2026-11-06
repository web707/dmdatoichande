import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';
import 'catalog.dart';

final guideProvider = ChangeNotifierProvider<GuideStore>(
  (ref) => throw StateError('GuideStore must be provided at startup'),
);

class GuideStore extends ChangeNotifier {
  final GuideApi api;
  final SharedPreferences preferences;
  final Map<String, List<CatalogRecord>> records = {
    for (final type in collections) type: [],
  };
  List<Map<String, dynamic>> emergencyContacts = [];
  late Set<String> favorites;
  Map<String, dynamic>? user;
  String? error;
  bool loading = true;
  bool live = false;
  DateTime? lastSync;
  int _generation = 0;
  int _refreshSerial = 0;
  bool _disposed = false;
  Timer? _poll;
  Timer? _debounce;
  StreamSubscription<Map<String, dynamic>>? _events;
  GuideStore(this.api, this.preferences) {
    favorites = (preferences.getStringList('phrase_favorites') ?? []).toSet();
  }
  bool get isAdmin => user?['role'] == 'admin';
  List<CatalogRecord> list(String collection) => records[collection] ?? [];
  CatalogRecord? find(String collection, String id) {
    for (final record in list(collection)) {
      if (record.id == id) return record;
    }
    return null;
  }

  void start() {
    unawaited(refresh());
    unawaited(_loadEmergency());
    _events = api.watchChanges().listen((event) {
      if (_disposed) return;
      if (event['type'] == 'reconnecting') {
        live = false;
        notifyListeners();
        return;
      }
      live = true;
      if (event['type'] == 'heartbeat') {
        notifyListeners();
        return;
      }
      _debounce?.cancel();
      _debounce = Timer(
        const Duration(milliseconds: 100),
        () => unawaited(refresh()),
      );
    });
    // Reconcile missed notifications and expired sessions even after an interrupted stream.
    _poll = Timer.periodic(
      const Duration(seconds: 20),
      (_) => unawaited(refresh()),
    );
  }

  Future<void> refresh() async {
    final generation = _generation;
    final serial = ++_refreshSerial;
    try {
      final result = await Future.wait(collections.map(api.fetchRecords));
      if (_disposed || generation != _generation || serial != _refreshSerial) {
        return;
      }
      for (var i = 0; i < collections.length; i++) {
        records[collections[i]] = result[i];
      }
      error = null;
      lastSync = DateTime.now();
    } catch (failure) {
      if (_disposed || generation != _generation || serial != _refreshSerial) {
        return;
      }
      live = false;
      error = failure.toString();
      if (failure is ApiException && failure.status == 401) {
        user = null;
        api.token = null;
        _generation++;
        records['phrases'] =
            []; // Never retain private phrases after session expiry.
      }
    } finally {
      if (!_disposed && serial == _refreshSerial) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> authenticate(
    String email,
    String password, {
    bool register = false,
  }) async {
    final authenticated = await api.authenticate(
      email,
      password,
      register: register,
    );
    _generation++;
    user = authenticated;
    records['phrases'] = [];
    notifyListeners();
    await refresh();
  }

  Future<void> logout() async {
    try {
      await api.logout();
    } finally {
      _generation++;
      user = null;
      records['phrases'] = [];
      notifyListeners();
      await refresh();
    }
  }

  Future<void> save(
    String collection,
    Map<String, dynamic> data, {
    String? id,
  }) async {
    await api.saveRecord(collection, data, id: id);
    await refresh();
  }

  Future<void> delete(CatalogRecord record) async {
    await api.deleteRecord(record);
    await refresh();
  }

  Future<void> toggleFavorite(String id) async {
    final next = {...favorites};
    next.contains(id) ? next.remove(id) : next.add(id);
    if (!await preferences.setStringList('phrase_favorites', next.toList())) {
      throw const ApiException(0, 'Could not save this bookmark.');
    }
    favorites = next;
    notifyListeners();
  }

  Future<void> _loadEmergency() async {
    try {
      emergencyContacts = await api.fetchEmergency();
      notifyListeners();
    } catch (_) {
      // Emergency contacts fallback to hardcoded in EmergencyPage
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _poll?.cancel();
    _debounce?.cancel();
    unawaited(_events?.cancel());
    api.dispose();
    super.dispose();
  }
}
