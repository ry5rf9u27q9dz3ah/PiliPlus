import 'package:PiliPlus/common/widgets/list_tile.dart';
import 'package:PiliPlus/pages/setting/models/model.dart';
import 'package:PiliPlus/pages/setting/models/recommend_settings.dart';
import 'package:PiliPlus/services/learning_mode_service.dart';
import 'package:flutter/material.dart' hide ListTile;

class RecommendSetting extends StatefulWidget {
  const RecommendSetting({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  State<RecommendSetting> createState() => _RecommendSettingState();
}

class _RecommendSettingState extends State<RecommendSetting> {
  final list = recommendSettings;
  late final List<SettingsModel> part;
  final svc = LearningModeService.instance;

  @override
  void initState() {
    super.initState();
    part = list.sublist(0, 4);
    list.removeRange(0, 4);
  }

  @override
  Widget build(BuildContext context) {
    final showAppBar = widget.showAppBar;
    final padding = MediaQuery.viewPaddingOf(context);
    final theme = Theme.of(context);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: widget.showAppBar == false
          ? null
          : AppBar(title: const Text('推荐流设置')),
      body: ListView(
        padding: EdgeInsets.only(
          left: showAppBar ? padding.left : 0,
          right: showAppBar ? padding.right : 0,
          bottom: padding.bottom + 100,
        ),
        children: [
          // Learning Mode section (migrated from LearningModePage)
          Builder(builder: (context) {
            final s = svc.settings;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('学习模式 白名单', style: Theme.of(context).textTheme.titleMedium),
                      Switch(
                        value: s.enabled,
                        onChanged: (v) async {
                          if (v) {
                            await svc.enable();
                          } else {
                            await svc.disable();
                          }
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('UP 白名单 (输入 upId)'),
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: TextEditingController(),
                        decoration: const InputDecoration(hintText: '输入 upId, 例如: 12345'),
                        onSubmitted: (v) async {
                          final t = v.trim();
                          if (t.isNotEmpty) {
                            await svc.addUp(t);
                            setState(() {});
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: null,
                    )
                  ]),
                  Wrap(
                    spacing: 8,
                    children: s.upWhitelist
                        .map((e) => Chip(
                              label: Text(e),
                              onDeleted: () async {
                                await svc.removeUp(e);
                                setState(() {});
                              },
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  const Text('Tag 白名单 (输入标签)'),
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: TextEditingController(),
                        decoration: const InputDecoration(hintText: '输入 tag'),
                        onSubmitted: (v) async {
                          final t = v.trim();
                          if (t.isNotEmpty) {
                            await svc.addTag(t);
                            setState(() {});
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: null,
                    )
                  ]),
                  Wrap(
                    spacing: 8,
                    children: s.tagWhitelist
                        .map((e) => Chip(
                              label: Text(e),
                              onDeleted: () async {
                                await svc.removeTag(e);
                                setState(() {});
                              },
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  const Text('关键字 白名单 (输入关键字)'),
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: TextEditingController(),
                        decoration: const InputDecoration(hintText: '输入关键字'),
                        onSubmitted: (v) async {
                          final t = v.trim();
                          if (t.isNotEmpty) {
                            await svc.addKeyword(t);
                            setState(() {});
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: null,
                    )
                  ]),
                  Wrap(
                    spacing: 8,
                    children: s.keywordWhitelist
                        .map((e) => Chip(
                              label: Text(e),
                              onDeleted: () async {
                                await svc.removeKeyword(e);
                                setState(() {});
                              },
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () async {
                      for (final e in List.of(s.upWhitelist)) {
                        await svc.removeUp(e);
                      }
                      for (final e in List.of(s.tagWhitelist)) {
                        await svc.removeTag(e);
                      }
                      for (final e in List.of(s.keywordWhitelist)) {
                        await svc.removeKeyword(e);
                      }
                      setState(() {});
                    },
                    child: const Text('清空所有白名单'),
                  ),
                  const Divider(),
                ],
              ),
            );
          }),
          ...part.map((item) => item.widget),
          const Divider(height: 1),
          ...list.map((item) => item.widget),
          ListTile(
            dense: true,
            subtitle: Text(
              '¹ 由于接口未提供关注信息，无法豁免相关视频中的已关注Up。\n\n'
              '* 其它（如热门视频、手动搜索、链接跳转等）均不受过滤器影响。\n'
              '* 设定较严苛的条件可导致推荐项数锐减或多次请求，请酌情选择。\n'
              '* 后续可能会增加更多过滤条件，敬请期待。',
              style: theme.textTheme.labelSmall!.copyWith(
                color: theme.colorScheme.outline.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
