import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'config/firebase_runtime_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const demoMode = bool.fromEnvironment('DEMO_MODE');
  if (demoMode) {
    runApp(const FoodLensApp.demo());
    return;
  }

  final config = FirebaseRuntimeConfig.fromEnvironment();
  if (!config.isConfigured) {
    runApp(const FoodLensApp.setupRequired());
    return;
  }

  try {
    await Firebase.initializeApp(options: config.options);
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );
    runApp(const FoodLensApp.firebase());
  } catch (_) {
    runApp(const FoodLensApp.setupRequired(initializationFailed: true));
  }
}
