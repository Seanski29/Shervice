import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shervice_flutter/screens/admin/admin_import_export.dart';
import 'package:shervice_flutter/session_manager.dart';
import 'package:shervice_flutter/theme/theme_manager.dart';

void main() {
  testWidgets('admin import/export screen limits import to attendance only', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AdminImportExport()));

    expect(find.text('Import & Export'), findsOneWidget);
    expect(find.text('Trips'), findsOneWidget);
    expect(find.text('Maintenance'), findsOneWidget);
    expect(find.text('Attendance'), findsOneWidget);

    final initialImportButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Import Locked'),
    );
    expect(initialImportButton.onPressed, isNull);

    await tester.tap(find.text('Attendance'));
    await tester.pump();

    final attendanceImportButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Import Excel'),
    );
    expect(attendanceImportButton.onPressed, isNotNull);
    expect(find.textContaining('xlsx'), findsWidgets);
  });

  test('theme preference survives loading and logout', () async {
    SharedPreferences.setMockInitialValues({
      'darkMode': true,
      'isLoggedIn': true,
      'role': 'admin',
    });

    await ThemeManager.loadSavedTheme();
    expect(ThemeManager.themeMode, ThemeMode.dark);

    await SessionManager.clearSession();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('darkMode'), isTrue);
    expect(prefs.getBool('isLoggedIn'), isNull);
  });
}
