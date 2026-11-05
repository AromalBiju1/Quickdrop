import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickdrop/core/app_store.dart';

void main() {
  test('missing theme mode defaults to system', () {
    final settings = AppSettings.fromJson({'device_name': 'Laptop'});
    expect(settings.themeMode, ThemeMode.system);
  });

  test('theme mode round-trips', () {
    for (final mode in ThemeMode.values) {
      final settings = AppSettings(deviceName: 'Laptop', themeMode: mode);
      final restored = AppSettings.fromJson(settings.toJson());
      expect(restored.themeMode, mode);
    }
  });

  test('unknown theme mode falls back to system', () {
    final settings = AppSettings.fromJson({
      'device_name': 'Laptop',
      'theme_mode': 'sepia',
    });
    expect(settings.themeMode, ThemeMode.system);
  });
}
