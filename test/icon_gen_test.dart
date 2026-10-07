// Renders the app icon at several sizes to build/icon/*.png.
// Opt in with: ICON_GEN=1 flutter test test/icon_gen_test.dart
// tool/make_ico.py then packs them into windows/runner/resources/app_icon.ico.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:ai_hujjat/ui/app_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('render icon sizes', (tester) async {
    Directory('build/icon').createSync(recursive: true);
    for (final n in [16, 20, 24, 32, 40, 48, 64, 96, 128, 256, 512]) {
      final bytes = await tester.runAsync(() async {
        final recorder = ui.PictureRecorder();
        const AppLogoPainter().paint(Canvas(recorder), Size(n.toDouble(), n.toDouble()));
        final image = await recorder.endRecording().toImage(n, n);
        return (await image.toByteData(format: ui.ImageByteFormat.png))!;
      });
      File('build/icon/$n.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    }
  }, skip: Platform.environment['ICON_GEN'] != '1');
}
