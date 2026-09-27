import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mongez/app.dart';
import 'package:mongez/core/di/services_locator.dart';
import 'package:mongez/core/services/fcm_service.dart';
import 'package:mongez/core/utils/app_prefs.dart';
import 'package:mongez/firebase_options.dart';

final fcmService = FcmService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  if (!kIsWeb) {
    _initFirebase();
  }

  setup();
  await AppPrefs.init();

  runZonedGuarded(
    () => runApp(const MyApp()),
    (error, stack) {
      developer.log('Uncaught error: $error', name: 'Mongez');
      if (!kIsWeb) {
        try {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        } catch (_) {}
      }
    },
  );
}

Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(!kDebugMode);
  } catch (e) {
    developer.log('Firebase init failed: $e', name: 'Mongez');
  }
}
