import 'package:PiliPlus/services/learning_mode_service.dart';
import 'package:flutter/material.dart';

class LearningModeButton extends StatefulWidget {
  const LearningModeButton({super.key});

  @override
  State<LearningModeButton> createState() => _LearningModeButtonState();
}

class _LearningModeButtonState extends State<LearningModeButton> {
  late LearningModeService svc;
  late bool enabled;

  @override
  void initState() {
    super.initState();
    svc = LearningModeService.instance;
    enabled = svc.settings.enabled;
    svc.stream.listen((s) {
      setState(() {
        enabled = s.enabled;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: enabled ? '学习模式：已开启' : '学习模式：已关闭',
      icon: Icon(
        enabled ? Icons.school : Icons.school_outlined,
        color: enabled ? Theme.of(context).colorScheme.primary : null,
      ),
      onPressed: () async {
        // 仅做切换，不导航
        if (enabled) {
          await svc.disable();
        } else {
          await svc.enable();
        }
        // setState will be triggered by stream listener
      },
    );
  }
}
