import 'adapter.dart';

abstract class Migration {
  Future<void> up(DatabaseAdapter db);
  Future<void> down(DatabaseAdapter db);
}
