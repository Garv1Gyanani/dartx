import '../core/server.dart';

abstract class Plugin {
  void register(App app);
}

extension AppPluginExtension on App {
  void usePlugin(Plugin plugin) {
    plugin.register(this);
  }
}
