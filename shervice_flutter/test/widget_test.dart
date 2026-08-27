import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shervice_flutter/session_manager.dart';
import 'package:shervice_flutter/utils/theme_manager.dart';

void main() {
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
