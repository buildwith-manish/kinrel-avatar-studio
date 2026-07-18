import 'package:flutter/material.dart';

import 'avatar_studio.dart';

/// V1 demo entry point.
///
/// Launches the [AvatarEditorScreen] directly so the user can immediately
/// test the avatar scaffold. When this module is merged into the main
/// Kinrel app, this file is removed and [AvatarEditorScreen] is wired
/// into the app's navigation graph instead.
void main() {
  runApp(const KinrelAvatarStudioApp());
}

class KinrelAvatarStudioApp extends StatelessWidget {
  const KinrelAvatarStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kinrel Avatar Studio',
      debugShowCheckedModeBanner: false,
      theme: AvatarStudioTheme.light(),
      home: const AvatarEditorScreen(),
    );
  }
}
