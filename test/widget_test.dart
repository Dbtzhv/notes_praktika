import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:notes_org/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Приложение строится и показывает заголовок', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(const NotesOrgApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Заметки мероприятий'), findsWidgets);
  });
}
