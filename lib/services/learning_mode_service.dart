import 'dart:async';

import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';

/// Minimal LearningModeService MVP
/// - Uses Pref/GStorage style storage via SettingBoxKey if available
/// - Exposes enable/disable, up/tag/keyword whitelists, matches(map) api

class LearningModeSettings {
  bool enabled;
  List<String> upWhitelist;
  List<String> tagWhitelist;
  List<String> keywordWhitelist;

  LearningModeSettings({
    this.enabled = false,
    List<String>? upWhitelist,
    List<String>? tagWhitelist,
    List<String>? keywordWhitelist,
  }) : upWhitelist = upWhitelist ?? [],
       tagWhitelist = tagWhitelist ?? [],
       keywordWhitelist = keywordWhitelist ?? [];

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'upWhitelist': upWhitelist,
    'tagWhitelist': tagWhitelist,
    'keywordWhitelist': keywordWhitelist,
  };

  static LearningModeSettings fromJson(Map? map) {
    if (map == null) return LearningModeSettings();
    return LearningModeSettings(
      enabled: map['enabled'] as bool? ?? false,
      upWhitelist:
          (map['upWhitelist'] as List?)?.map((e) => e.toString()).toList() ??
          [],
      tagWhitelist:
          (map['tagWhitelist'] as List?)?.map((e) => e.toString()).toList() ??
          [],
      keywordWhitelist:
          (map['keywordWhitelist'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

class LearningModeService {
  LearningModeSettings _settings = LearningModeSettings();
  final StreamController<LearningModeSettings> _controller =
      StreamController.broadcast();

  static final LearningModeService _instance = LearningModeService._internal();

  LearningModeService._internal() {
    _loadFromStorage();
  }

  static LearningModeService get instance => _instance;

  Stream<LearningModeSettings> get stream => _controller.stream;

  LearningModeSettings get settings => _settings;

  Future<void> _loadFromStorage() async {
    try {
      final map =
          GStorage.setting.get(SettingBoxKey.learningModeSettings) as Map?;
      _settings = LearningModeSettings.fromJson(map);
      _controller.add(_settings);
    } catch (e) {
      // ignore, defaults remain
    }
  }

  Future<void> _saveToStorage() async {
    try {
      await GStorage.setting.put(
        SettingBoxKey.learningModeSettings,
        _settings.toJson(),
      );
    } catch (e) {
      // ignore write error for MVP
    }
  }

  Future<void> enable() async {
    _settings.enabled = true;
    await _saveToStorage();
    _controller.add(_settings);
  }

  Future<void> disable() async {
    _settings.enabled = false;
    await _saveToStorage();
    _controller.add(_settings);
  }

  Future<void> toggle() async {
    _settings.enabled = !_settings.enabled;
    await _saveToStorage();
    _controller.add(_settings);
  }

  Future<void> addUp(String upId) async {
    final v = upId.trim().toLowerCase();
    if (!_settings.upWhitelist.contains(v)) {
      _settings.upWhitelist.add(v);
      await _saveToStorage();
      _controller.add(_settings);
    }
  }

  Future<void> removeUp(String upId) async {
    final v = upId.trim().toLowerCase();
    _settings.upWhitelist.remove(v);
    await _saveToStorage();
    _controller.add(_settings);
  }

  Future<void> addTag(String tag) async {
    final v = tag.trim().toLowerCase();
    if (!_settings.tagWhitelist.contains(v)) {
      _settings.tagWhitelist.add(v);
      await _saveToStorage();
      _controller.add(_settings);
    }
  }

  Future<void> removeTag(String tag) async {
    final v = tag.trim().toLowerCase();
    _settings.tagWhitelist.remove(v);
    await _saveToStorage();
    _controller.add(_settings);
  }

  Future<void> addKeyword(String k) async {
    final v = k.trim().toLowerCase();
    if (!_settings.keywordWhitelist.contains(v)) {
      _settings.keywordWhitelist.add(v);
      await _saveToStorage();
      _controller.add(_settings);
    }
  }

  Future<void> removeKeyword(String k) async {
    final v = k.trim().toLowerCase();
    _settings.keywordWhitelist.remove(v);
    await _saveToStorage();
    _controller.add(_settings);
  }

  bool _matchKeyword(String? text) {
    if (text == null || text.isEmpty) return false;
    final lower = text.toLowerCase();
    for (final k in _settings.keywordWhitelist) {
      if (lower.contains(k)) return true;
    }
    return false;
  }

  /// item: expected to be a Map or object with ['upId'] and ['tags'] and ['title'] / ['desc']
  bool matches(dynamic item) {
    if (!_settings.enabled) return true; // when disabled, don't filter

    try {
      // normalize up id
      final upId = _extractUpId(item)?.toLowerCase();
      if (upId != null && _settings.upWhitelist.contains(upId)) return true;

      final tags = _extractTags(item);
      for (final t in tags) {
        if (_settings.tagWhitelist.contains(t.toLowerCase())) return true;
      }

      final title = _extractTitle(item);
      if (_matchKeyword(title)) return true;

      final desc = _extractDesc(item);
      if (_matchKeyword(desc)) return true;
    } catch (e) {
      // ignore parse errors, default to false (hide if learning mode on)
    }

    return false;
  }

  String? _extractUpId(dynamic item) {
    if (item == null) return null;
    if (item is Map) {
      if (item.containsKey('upId')) return item['upId']?.toString();
      if (item.containsKey('mid')) return item['mid']?.toString();
      if (item.containsKey('owner') && item['owner'] is Map)
        return item['owner']['mid']?.toString();
    }
    try {
      final m = item;
      final mid = m.mid;
      return mid?.toString();
    } catch (_) {}
    return null;
  }

  List<String> _extractTags(dynamic item) {
    if (item == null) return [];
    if (item is Map) {
      final ts = <String>[];
      if (item.containsKey('tags') && item['tags'] is List) {
        for (final t in item['tags']) {
          ts.add(t.toString());
        }
      }
      if (item.containsKey('tag') && item['tag'] != null)
        ts.add(item['tag'].toString());
      return ts;
    }
    try {
      final m = item;
      if (m.tags is List)
        return (m.tags as List).map((e) => e.toString()).toList();
    } catch (_) {}
    return [];
  }

  String? _extractTitle(dynamic item) {
    if (item == null) return null;
    if (item is Map) {
      if (item.containsKey('title')) return item['title']?.toString();
      if (item.containsKey('name')) return item['name']?.toString();
    }
    try {
      return item.title?.toString();
    } catch (_) {}
    return null;
  }

  String? _extractDesc(dynamic item) {
    if (item == null) return null;
    if (item is Map) {
      if (item.containsKey('description'))
        return item['description']?.toString();
      if (item.containsKey('desc')) return item['desc']?.toString();
    }
    try {
      return item.desc?.toString();
    } catch (_) {}
    return null;
  }
}
