abstract class Disposable {
  Future<void> dispose();
}

class Container {
  final Container? parent;
  final Map<String, dynamic> _singletons = {};
  final Map<String, dynamic Function(Container)> _factories = {};
  final Map<String, dynamic Function(Container)> _scopedFactories = {};
  final Map<String, dynamic> _instances = {}; // For scoped instances in this container

  Container({this.parent});

  String _key<T>([String? name]) => "${T.toString()}${name != null ? ':$name' : ''}";

  void instance<T>(T instance, {String? name}) => _instances[_key<T>(name)] = instance;
  void registerInstance<T>(T instance, {String? name}) => _instances[_key<T>(name)] = instance;

  void singleton<T>(T instance, {String? name}) => _singletons[_key<T>(name)] = instance;
  
  void lazySingleton<T>(T Function(Container) factory, {String? name}) {
    _factories[_key<T>(name)] = (c) {
      final instance = factory(c);
      _singletons[_key<T>(name)] = instance;
      return instance;
    };
  }

  void factory<T>(T Function(Container) factory, {String? name}) => 
    _factories[_key<T>(name)] = factory;

  void scoped<T>(T Function(Container) factory, {String? name}) => 
    _scopedFactories[_key<T>(name)] = factory;

  Container child() => Container(parent: this);

  bool has<T>({String? name}) {
    final key = _key<T>(name);
    return _instances.containsKey(key) || 
           _singletons.containsKey(key) || 
           _scopedFactories.containsKey(key) || 
           _factories.containsKey(key) || 
           (parent?.has<T>(name: name) ?? false);
  }

  T resolve<T>({String? name}) {
    final key = _key<T>(name);

    if (_instances.containsKey(key)) return _instances[key] as T;
    if (_singletons.containsKey(key)) return _singletons[key] as T;

    if (_scopedFactories.containsKey(key)) {
      final instance = _scopedFactories[key]!(this);
      _instances[key] = instance;
      return instance as T;
    }

    if (_factories.containsKey(key)) {
      return _factories[key]!(this) as T;
    }

    if (parent != null) {
      return parent!.resolve<T>(name: name);
    }

    throw Exception('Service $key not registered in this container or any of its parents.');
  }

  Future<void> dispose() async {
    for (var instance in _instances.values.toList()) {
      if (instance is Disposable) {
        try {
          await instance.dispose();
        } catch (e) {
          // In a framework, we should probably log this but not let it crash the request loop
        }
      }
    }
    _instances.clear();
  }
}

final di = Container();
