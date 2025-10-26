import 'dart:io';

import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class FontSettingPage extends StatefulWidget {
  const FontSettingPage({super.key});

  @override
  State<FontSettingPage> createState() => _FontSettingPageState();
}

class _FontSettingPageState extends State<FontSettingPage> {
  late String _primary;
  late String _fallbackRaw;
  late int _fontWeightIndex; // -1 表示系统默认
  bool get _customWeight => _fontWeightIndex != -1;
  late double _textScale;

  final _familyController = TextEditingController();
  final _fallbackController = TextEditingController();
  final _familyFocusNode = FocusNode();
  final _fallbackFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _primary = Pref.appFontFamily;
    _fallbackRaw = Pref.appFontFallbacks.join('\n');
    final w = Pref.appFontWeight;
    _fontWeightIndex = w < -1
        ? -1
        : (w > FontWeight.values.length - 1 ? FontWeight.values.length - 1 : w);
    _textScale = Pref.defaultTextScale;
    _familyController.text = _primary;
    _fallbackController.text = _fallbackRaw;
    _familyFocusNode.addListener(() {
      if (!_familyFocusNode.hasFocus) {
        setState(() {});
      }
    });
    _fallbackFocusNode.addListener(() {
      if (!_fallbackFocusNode.hasFocus) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _familyController.dispose();
    _fallbackController.dispose();
    _familyFocusNode.dispose();
    _fallbackFocusNode.dispose();
    super.dispose();
  }

  List<String> _parseFallback(String raw) => raw
      .split(RegExp(r'[\n,]'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList(growable: false);

  void _applyPreset(String family, List<String> fallbacks) {
    setState(() {
      _familyController.text = family;
      _fallbackController.text = fallbacks.join('\n');
    });
  }

  Future<void> _save() async {
    final family = _familyController.text.trim();
    final fallbacks = _parseFallback(_fallbackController.text);
    await GStorage.setting.put(SettingBoxKey.appFontFamily, family);
    await GStorage.setting.put(SettingBoxKey.appFontFallbacks, fallbacks);
    await GStorage.setting.put(SettingBoxKey.appFontWeight, _fontWeightIndex);
    await GStorage.setting.put(SettingBoxKey.defaultTextScale, _textScale);
    SmartDialog.showToast('设置成功');
    Get.forceAppUpdate();
    setState(() {});
  }

  Future<void> _reset() async {
    await GStorage.setting.put(SettingBoxKey.appFontFamily, '');
    await GStorage.setting.put(
      SettingBoxKey.appFontFallbacks,
      const <String>[],
    );
    await GStorage.setting.put(SettingBoxKey.appFontWeight, -1);
    await GStorage.setting.put(SettingBoxKey.defaultTextScale, 1.0);
    _familyController.clear();
    _fallbackController.clear();
    _fontWeightIndex = -1;
    _textScale = 1.0;
    SmartDialog.showToast('已恢复默认');
    Get.forceAppUpdate();
    setState(() {});
  }

  List<(String, List<String>)> _presets() {
    // 轻量级预设：不同平台常见组合
    if (Platform.isAndroid) {
      return const [
        ('', ['Noto Sans CJK SC', 'Roboto']),
        ('Noto Sans CJK SC', ['Roboto']),
      ];
    }
    if (Platform.isIOS || Platform.isMacOS) {
      return const [
        ('', ['PingFang SC', 'SF Pro Text']),
        ('PingFang SC', ['SF Pro Text']),
      ];
    }
    if (Platform.isWindows) {
      return const [
        ('Microsoft YaHei UI', ['Segoe UI']),
        ('', ['Microsoft YaHei UI', 'Segoe UI']),
      ];
    }
    // Linux & others
    return const [
      ('', ['Noto Sans CJK SC', 'DejaVu Sans', 'Ubuntu']),
      ('Noto Sans CJK SC', ['DejaVu Sans']),
      ('Source Han Sans SC', ['DejaVu Sans']),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final sampleFamily = _familyController.text.trim().isEmpty
        ? null
        : _familyController.text.trim();
    final sampleFallback = _parseFallback(_fallbackController.text);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('修改字体'),
        actions: [
          TextButton(
            onPressed: _reset,
            child: const Text('恢复默认'),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: _save,
            child: const Text('保存'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('主字体', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _familyController,
            focusNode: _familyFocusNode,
            decoration: const InputDecoration(
              hintText: '留空使用系统默认（示例：HarmonyOS Sans SC）',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Text('字体备用列表', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _fallbackController,
            focusNode: _fallbackFocusNode,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: '每行一个或用逗号分隔（示例：Noto Sans CJK SC\nRoboto, Segoe UI）',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          Text('预览', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(_textScale),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'The quick brown fox jumps over the lazy dog.',
                    style: TextStyle(
                      inherit: false,
                      fontFamily: sampleFamily,
                      fontFamilyFallback: sampleFallback.isEmpty
                          ? null
                          : sampleFallback,
                      fontSize: 16,
                      fontWeight: _customWeight
                          ? FontWeight.values[_fontWeightIndex]
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '常用中文示例：我能吞下玻璃而不伤身体。1234567890',
                    style: TextStyle(
                      inherit: false,
                      fontFamily: sampleFamily,
                      fontFamilyFallback: sampleFallback.isEmpty
                          ? null
                          : sampleFallback,
                      fontSize: 16,
                      fontWeight: _customWeight
                          ? FontWeight.values[_fontWeightIndex]
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('字体大小', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _textScale,
                  min: 0.8,
                  max: 1.6,
                  divisions: 16,
                  label: _textScale.toStringAsFixed(2),
                  onChanged: (v) => setState(() => _textScale = v),
                ),
              ),
              SizedBox(
                width: 64,
                child: Text(
                  _textScale == 1.0 ? '默认' : _textScale.toStringAsFixed(2),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('字重（粗细）', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('自定义字重'),
            value: _customWeight,
            onChanged: (v) {
              setState(() {
                _fontWeightIndex = v
                    ? (_fontWeightIndex == -1 ? 5 : _fontWeightIndex)
                    : -1;
              });
            },
          ),
          if (_customWeight) ...[
            Slider(
              value: (_fontWeightIndex + 1).toDouble(),
              min: 1,
              max: FontWeight.values.length.toDouble(),
              divisions: FontWeight.values.length - 1,
              label: FontWeight.values[_fontWeightIndex].toString(),
              onChanged: (val) {
                setState(() {
                  _fontWeightIndex = val.toInt() - 1;
                });
              },
            ),
            Text('当前：${FontWeight.values[_fontWeightIndex]}'),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 8),
          Text('快速选择（按平台推荐）', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ..._presets().map(
            (p) => ListTile(
              leading: const Icon(Icons.bolt_outlined),
              title: Text(p.$1.isEmpty ? '系统默认 + 备用' : p.$1),
              subtitle: Text(p.$2.isEmpty ? '无备用' : p.$2.join('、')),
              onTap: () => _applyPreset(p.$1, p.$2),
            ),
          ),
        ],
      ),
    );
  }
}
