import 'package:PiliPlus/services/learning_mode_service.dart';
import 'package:flutter/material.dart';

class LearningModeSetting extends StatefulWidget {
  const LearningModeSetting({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  State<LearningModeSetting> createState() => _LearningModeSettingState();
}

class _LearningModeSettingState extends State<LearningModeSetting> {
  final svc = LearningModeService.instance;
  final upController = TextEditingController();
  final tagController = TextEditingController();
  final keyController = TextEditingController();

  @override
  void dispose() {
    upController.dispose();
    tagController.dispose();
    keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = svc.settings;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: widget.showAppBar ? AppBar(title: const Text('学习模式')) : null,
      body: ListView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewPaddingOf(context).bottom + 100,
          left: widget.showAppBar ? MediaQuery.viewPaddingOf(context).left : 0,
          right: widget.showAppBar
              ? MediaQuery.viewPaddingOf(context).right
              : 0,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '学习模式 白名单',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
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
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: upController,
                        decoration: const InputDecoration(
                          hintText: '输入 upId, 例如: 12345',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () async {
                        final v = upController.text.trim();
                        if (v.isNotEmpty) {
                          await svc.addUp(v);
                          upController.clear();
                          setState(() {});
                        }
                      },
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  children: s.upWhitelist
                      .map(
                        (e) => Chip(
                          label: Text(e),
                          onDeleted: () async {
                            await svc.removeUp(e);
                            setState(() {});
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
                const Text('Tag 白名单 (输入标签)'),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: tagController,
                        decoration: const InputDecoration(hintText: '输入 tag'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () async {
                        final v = tagController.text.trim();
                        if (v.isNotEmpty) {
                          await svc.addTag(v);
                          tagController.clear();
                          setState(() {});
                        }
                      },
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  children: s.tagWhitelist
                      .map(
                        (e) => Chip(
                          label: Text(e),
                          onDeleted: () async {
                            await svc.removeTag(e);
                            setState(() {});
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
                const Text('关键字 白名单 (输入关键字)'),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: keyController,
                        decoration: const InputDecoration(hintText: '输入关键字'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () async {
                        final v = keyController.text.trim();
                        if (v.isNotEmpty) {
                          await svc.addKeyword(v);
                          keyController.clear();
                          setState(() {});
                        }
                      },
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  children: s.keywordWhitelist
                      .map(
                        (e) => Chip(
                          label: Text(e),
                          onDeleted: () async {
                            await svc.removeKeyword(e);
                            setState(() {});
                          },
                        ),
                      )
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
