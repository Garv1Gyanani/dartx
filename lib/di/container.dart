class Container {
  final Container? parent;
  final Map<Type, dynamic> _singletons = {};
  final Map<Type, dynamic Function(Container)> _factories = {};
  final Map<Type, dynamic Function(Container)> _scopedFactories = {};
  final Map<Type, dynamic> _instances = {}; // For scoped instances in this container

  Container({this.parent});

  void instance<T>(T instance) => _instances[T] = instance;

  // Alias for instance() to match requested enterprise naming
  void registerInstance<T>(T instance) => _instances[T] = instance;

  void singleton<T>(T instance) => _singletons[T] = instance;
  void factory<T>(T Function(Container) factory) => _factories[T] = factory;
  void scoped<T>(T Function(Container) factory) => _scopedFactories[T] = factory;

  /// Creates a child container for a specific scope (e.g. a request).
  Container child() => Container(parent: this);

  T resolve<T>() {
    // 1. If we have a cached instance (singleton or already resolved scoped), return it.
    if (_instances.containsKey(T)) return _instances[T] as T;
    if (_singletons.containsKey(T)) return _singletons[T] as T;

    // 2. Check local scoped factories (these are stored in the current container's _instances).
    if (_scopedFactories.containsKey(T)) {
      final instance = _scopedFactories[T]!(this);
      _instances[T] = instance;
      return instance as T;
    }

    // 3. Check local factories.
    if (_factories.containsKey(T)) {
      return _factories[T]!(this) as T;
    }

    // 4. Delegate to parent if available.
    if (parent != null) {
      return parent!.resolve<T>();
    }

    throw Exception('Service $T not registered in this container or any of its parents.');
  }
}

// Global root container
final di = Container();
