import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'screens/launch_flow.dart';

class AtomIQApp extends StatelessWidget {
  const AtomIQApp({super.key, this.theme});
  final ThemeData? theme;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AtomIQ',
      theme: theme ?? AppTheme.light(),
      home: const LaunchFlow(),
    );
  }
}
