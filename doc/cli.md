# CLI Reference

The Kronix CLI is the heart of the developer experience, providing scaffolding and workflow automation.

## Project Management

### `create <name>`
Scaffolds a new Kronix project with the recommended directory structure.

```bash
kronix create my_api
```

### `watch`
Starts the development server with hot-reloading. It watches `.dart` and `.env` files.

```bash
kronix watch
```

## Generators

### `make:controller <Name>`
Generates a controller in `app/controllers/`.

### `make:request <Name>`
Generates a `FormRequest` validation class in `app/requests/`.

### `make:migration <Name>`
Generates a timestamped SQL migration in `database/migrations/`.

### `make:model <Name>`
Generates a Model class in `app/models/`.

### `make:service <Name>`
Generates a Service class in `app/services/`.

### `make:middleware <Name>`
Generates a middleware function in `app/middleware/`.

## Database

### `migrate`
Executes all pending database migrations.

### `migrate:rollback`
Rolls back the last batch of migrations.
