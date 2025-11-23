# API Overview

The backend exposes RESTful endpoints (FastAPI). Full interactive docs at `/docs`.

## Base URL
```
http://localhost:8000
```

## Auth
- `POST /api/v1/auth/register`
- `POST /api/v1/auth/login`
- `GET /api/v1/auth/me`

## Projects
- `GET /api/v1/projects/`
- `POST /api/v1/projects/`
- `GET /api/v1/projects/{id}`
- `PUT /api/v1/projects/{id}`
- `DELETE /api/v1/projects/{id}`

## Tasks
- `GET /api/v1/tasks/` (optional `project_id` query)
- `POST /api/v1/tasks/`
- `GET /api/v1/tasks/{id}`
- `PUT /api/v1/tasks/{id}`
- `DELETE /api/v1/tasks/{id}`

## Admin
- `GET /api/v1/admin/users`
- `GET /api/v1/admin/users/{id}`
- `PUT /api/v1/admin/users/{id}/activate`
- `PUT /api/v1/admin/users/{id}/deactivate`
- `GET /api/v1/admin/projects`
- `GET /api/v1/admin/projects/{id}/tasks`
- `GET /api/v1/admin/stats/system`
- `GET /api/v1/admin/stats/users`
- `GET /api/v1/admin/stats/projects`

For detailed request/response bodies, use Swagger UI at `/docs`.
