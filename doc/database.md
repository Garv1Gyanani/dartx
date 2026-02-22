# Database and ORM in Kronix

Kronix provides a fluent SQL Query Builder and a skeletal ORM for PostgreSQL.

## Database Connection

Configure your database in `.env`:

```env
DB_HOST=localhost
DB_NAME=kronix_db
DB_USER=postgres
DB_PASS=secret
```

Initialize the adapter:

```dart
final db = PostgresAdapter(
  host: Config.get('DB_HOST')!,
  database: Config.get('DB_NAME')!,
  // ...
);

di.singleton<DatabaseAdapter>(db);
```

## Query Builder

Access the query builder via the adapter:

```dart
final users = await db.table('users')
  .where('active', '=', true)
  .orderBy('created_at', 'DESC')
  .limit(10)
  .get();
```

### Supported Methods
- `where(col, op, val)`
- `orWhere(col, op, val)`
- `orderBy(col, [direction])`
- `limit(count)`
- `offset(count)`
- `select([cols])`
- `first()`
- `count()`
- `insert(map)`
- `update(map)`
- `delete()`

## Migrations

Migrations are stored in `database/migrations/`.

### Creating a Migration
```bash
kronix make:migration create_users_table
```

### Running Migrations
```bash
kronix migrate
```

### Rolling Back
```bash
kronix migrate:rollback
```

## Models (Experimental)

Models provide an Active Record-like interface.

```dart
class User extends Model {
  String? name;
  String? email;

  @override
  String get table => 'users';

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email
  };

  @override
  void fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    email = json['email'];
  }
}
```
