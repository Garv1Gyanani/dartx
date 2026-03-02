import '../core/server.dart';

/// Base class for all Kronix plugins.
abstract class Plugin {
  /// Internal constructor for [Plugin].
  Plugin();

  /// Registers the plugin with the provided [app].
  void register(App app);
}

/// Extension on [App] to support plugins.
extension AppPluginExtension on App {
  /// Registers a [plugin] with the current application.
  void usePlugin(Plugin plugin) {
    plugin.register(this);
  }
}
