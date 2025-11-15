import 'package:PiliPlus/services/learning_mode_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LearningModeService', () {
    test('default settings disabled', () {
      final svc = LearningModeService.instance;
      expect(svc.settings.enabled, false);
    });

    test('add and match up', () async {
      final svc = LearningModeService.instance;
      await svc.addUp('12345');
      await svc.enable();

      final item = {'upId': '12345', 'title': 'test'};
      expect(svc.matches(item), true);

      await svc.removeUp('12345');
      expect(svc.matches(item), false);
      await svc.disable();
    });

    test('tag matching and keyword matching', () async {
      final svc = LearningModeService.instance;
      await svc.addTag('Flutter');
      await svc.addKeyword('tutorial');
      await svc.enable();

      final item1 = {
        'tags': ['flutter', 'dart'],
        'title': 'something',
      };
      final item2 = {
        'tags': ['other'],
        'title': 'A great tutorial about x',
      };

      expect(svc.matches(item1), true);
      expect(svc.matches(item2), true);

      await svc.removeTag('Flutter');
      await svc.removeKeyword('tutorial');
      await svc.disable();
    });
  });
}
