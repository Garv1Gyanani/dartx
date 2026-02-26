import 'dart:io';
import 'package:kronix/kronix.dart';

// ─── MODELS ───────────────────────────────────────────────────────

class Post extends Model {
  @override String get tableName => 'posts';
  String title;
  int userId;

  Post({super.id, required this.title, required this.userId});

  factory Post.fromRow(Map<String, dynamic> row) => Post(
    id: row['id'],
    title: row['title'],
    userId: row['user_id'],
  );

  @override Map<String, dynamic> toMap() => {'title': title, 'user_id': userId};

  Future<User?> author() => belongsTo<User>(User.fromRow);
}

class User extends Model {
  @override String get tableName => 'users';
  String name;

  User({super.id, required this.name});

  factory User.fromRow(Map<String, dynamic> row) => User(
    id: row['id'],
    name: row['name'],
  );

  @override Map<String, dynamic> toMap() => {'name': name};

  Future<List<Post>> posts() => hasMany<Post>(Post.fromRow);
  Future<Profile?> profile() => hasOne<Profile>(Profile.fromRow);
}

class Profile extends Model {
  @override String get tableName => 'profiles';
  String bio;
  int userId;

  Profile({super.id, required this.bio, required this.userId});

  factory Profile.fromRow(Map<String, dynamic> row) => Profile(
    id: row['id'],
    bio: row['bio'],
    userId: row['user_id'],
  );

  @override Map<String, dynamic> toMap() => {'bio': bio, 'user_id': userId};
}

// ─── VERIFICATION ─────────────────────────────────────────────────

void main() async {
  print('--- Testing ORM Relationships ---');
  
  final db = MockDB();
  
  // 1. Setup Mock User
  final userRow = {'id': 1, 'name': 'John Doe'};
  final user = User.fromRow(userRow);
  user.setRawData(db, userRow);

  // 2. Test Has Many
  print('Testing hasMany...');
  final posts = await user.posts();
  if (posts.length == 2 && posts[0].title == 'Post 1') {
    print('✅ hasMany works.');
  } else {
    print('❌ hasMany failed.');
  }

  // 3. Test Belongs To
  print('Testing belongsTo...');
  final postRow = {'id': 10, 'title': 'Post 10', 'user_id': 1};
  final post = Post.fromRow(postRow);
  post.setRawData(db, postRow);
  
  final author = await post.author();
  if (author?.id == 1 && author?.name == 'John Doe') {
    print('✅ belongsTo works.');
  } else {
    print('❌ belongsTo failed. Author: $author');
  }

  // 4. Test Has One
  print('Testing hasOne...');
  final profile = await user.profile();
  if (profile?.bio == 'My Bio') {
    print('✅ hasOne works.');
  } else {
    print('❌ hasOne failed.');
  }

  print('\nORM Relationship Verification Complete.');
  exit(0);
}

// ─── MOCKS ───────────────────────────────────────────────────────

class MockDB extends DatabaseAdapter {
  @override
  Future<QueryResult> query(String sql, [Map<String, dynamic>? params]) async {
    final lowerSql = sql.toLowerCase();
    if (lowerSql.contains('from "posts"') || lowerSql.contains('from posts')) {
      return MockQueryResult([
        {'id': 1, 'title': 'Post 1', 'user_id': 1},
        {'id': 2, 'title': 'Post 2', 'user_id': 1},
      ]);
    }
    if (lowerSql.contains('from "users"') || lowerSql.contains('from users')) {
      return MockQueryResult([
        {'id': 1, 'name': 'John Doe'},
      ]);
    }
    if (lowerSql.contains('from "profiles"') || lowerSql.contains('from profiles')) {
      return MockQueryResult([
        {'id': 5, 'bio': 'My Bio', 'user_id': 1},
      ]);
    }
    return MockQueryResult([]);
  }

  @override Future<T> transaction<T>(Future<T> Function(DatabaseExecutor tx) callback) async => await callback(this);
  @override QueryBuilder table(String name, [DatabaseExecutor? executor]) => QueryBuilder(name, executor ?? this);
  @override Future<void> connect() async {}
  @override Future<void> close() async {}
  @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockQueryResult implements QueryResult {
  @override final List<Map<String, dynamic>> rows;
  @override final int? affectedRows = 0;
  MockQueryResult(this.rows);
}
