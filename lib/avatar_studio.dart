/// Kinrel Avatar Studio — public API.
///
/// Import this package as a whole to use the avatar system:
///
/// ```dart
/// import 'package:kinrel_avatar_studio/avatar_studio.dart';
///
/// AvatarRenderer(config: myConfig);
/// AvatarEditorScreen();
/// ```
///
/// When merging into the main Kinrel app, this barrel becomes the
/// package's only public surface — everything else stays internal.
library kinrel_avatar_studio;

// Models
export 'models/avatar_config.dart';
export 'models/avatar_layer.dart';

// Registry
export 'registry/asset_manifest.dart';
export 'registry/avatar_storage.dart';
export 'registry/base_bodies.dart';

// Widgets
export 'widgets/avatar_editor_screen.dart';
export 'widgets/avatar_renderer.dart';
export 'widgets/placeholder_layer.dart';

// Theme
export 'theme/avatar_studio_theme.dart';
