import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path_provider/path_provider.dart';

import 'app_controller.dart';
import 'data/database.dart';
import 'data/legacy_migration.dart';
import 'l10n/app_localizations.dart';
import 'services/app_log.dart';
import 'services/settings_service.dart';
import 'ui/home_shell.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLog.init();
  AppLog.write('--- start');
  FlutterError.onError = (details) {
    AppLog.write('FlutterError: ${details.exceptionAsString()}\n${details.stack}');
    FlutterError.presentError(details);
  };
  ui.PlatformDispatcher.instance.onError = (error, stack) {
    AppLog.write('Uncaught: $error\n$stack');
    return true;
  };
  AppLifecycleListener(
    onExitRequested: () async {
      AppLog.write('exit requested');
      return ui.AppExitResponse.exit;
    },
    onDetach: () => AppLog.write('detached'),
  );

  // Must run before anything opens the settings file or the database.
  await migrateLegacyDataDir(await getApplicationSupportDirectory());
  final settings = await SettingsService.load();
  final db = await AppDatabase.open();
  AppLog.write('database open');
  runApp(AiHujjatApp(controller: AppController(db, settings)));
  AppLog.write('runApp done');
}

class AiHujjatApp extends StatelessWidget {
  const AiHujjatApp({super.key, required this.controller, this.fontFamily, this.themeMode = ThemeMode.system});
  final AppController controller;

  /// Overrides the platform font (screenshot tests load Roboto).
  final String? fontFamily;
  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: controller,
      child: ListenableBuilder(
        listenable: controller.settings,
        builder: (context, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          onGenerateTitle: (c) => AppLocalizations.of(c).appTitle,
          theme: buildTheme(Brightness.light, fontFamily: fontFamily),
          darkTheme: buildTheme(Brightness.dark, fontFamily: fontFamily),
          themeMode: themeMode,
          locale: controller.settings.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const HomeShell(),
        ),
      ),
    );
  }
}
