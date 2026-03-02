import 'dart:async';

/// An interface for services that require explicit cleanup at the end of a lifecycle.
/// 
/// Implementing [Disposable] allows a service to perform asynchronous cleanup
/// (e.g., closing database connections or clearing cache buffers) when the
/// container is disposed.
abstract class Disposable {
  /// Internal constructor for [Disposable].
  Disposable();

  /// Performs cleanup operations.
  Future<void> dispose();
}

/// A hierarchical Dependency Injection (DI) container.
/// 
/// The [Container] supports singletons, factories, and scoped instances.
/// It can be nested to create isolated scopes (e.g., per-request).
class Container {
  /// Creates a new [Container], optionally delegating to a [parent].
  Container({this.parent});

  /// The parent container to delegate to if a service is not found locally.
  final Container? parent;
  final Map<String, dynamic> _singletons = {};
  final Map<String, dynamic Function(Container)> _factories = {};
  final Map<String, dynamic Function(Container)> _scopedFactories = {};
  final Map<String, dynamic> _instances = {}; // For scoped instances in this container

  String _key<T>([String? name]) => '${T.toString()}${name != null ? ':$name' : ''}';

  /// Registers an [instance] locally in this container.
  void instance<T>(T instance, {String? name}) => _instances[_key<T>(name)] = instance;

  /// Registers an [instance] locally in this container. Alias for [instance].
  void registerInstance<T>(T instance, {String? name}) => _instances[_key<T>(name)] = instance;

  /// Registers a [instance] as a singleton available globally (or at this container's level).
  void singleton<T>(T instance, {String? name}) => _singletons[_key<T>(name)] = instance;
  
  /// Registers a [factory] that will be executed once and its result stored as a singleton.
  void lazySingleton<T>(T Function(Container) factory, {String? name}) {
    _factories[_key<T>(name)] = (c) {
      final res = factory(c);
      _singletons[_key<T>(name)] = res;
      return res;
    };
  }

  /// Registers a [factory] that will be executed every time [resolve] is called.
  void factory<T>(T Function(Container) factory, {String? name}) => 
    _factories[_key<T>(name)] = factory;

  /// Registers a [factory] that will be executed once per container scope (e.g. per request).
  void scoped<T>(T Function(Container) factory, {String? name}) => 
    _scopedFactories[_key<T>(name)] = factory;

  /// Creates a child container that delegates to this one for missing services.
  Container child() => Container(parent: this);

  /// Returns `true` if a service of type [T] is registered.
  bool has<T>({String? name}) {
    final key = _key<T>(name);
    return _instances.containsKey(key) || 
           _singletons.containsKey(key) || 
           _scopedFactories.containsKey(key) || 
           _factories.containsKey(key) || 
           (parent?.has<T>(name: name) ?? false);
  }

  /// Resolves an instance of type [T].
  /// 
  /// Searches local instances, then singletons, then factories. If not found, 
  /// delegates to the [parent] container. Throws if not found anywhere.
  T resolve<T>({String? name}) {
    final key = _key<T>(name);

    if (_instances.containsKey(key)) return _instances[key] as T;
    if (_singletons.containsKey(key)) return _singletons[key] as T;

    if (_scopedFactories.containsKey(key)) {
      final res = _scopedFactories[key]!(this);
      _instances[key] = res;
      return res as T;
    }

    if (_factories.containsKey(key)) {
      final res = _factories[key]!(this);
      return res as T;
    }

    final p = parent;
    if (p != null) {
      return p.resolve<T>(name: name);
    }

    throw Exception('Service $key not registered in this container or any of its parents.');
  }

  /// Disposes of all locally registered instances that implement [Disposable].
  Future<void> dispose() async {
    for (final res in _instances.values.toList()) {
      if (res is Disposable) {
        try {
          await res.dispose();
        } catch (_) {
          // In a framework, we should probably log this but not let it crash the request loop
        }
      }
    }
    _instances.clear();
  }
}

/// The global Default Injection [Container].
final di = Container();
