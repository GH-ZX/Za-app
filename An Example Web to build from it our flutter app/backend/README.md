# Task Management API

A simple task management system backend built with FastAPI, SQLAlchemy, and SQLite - similar to a basic version of Jira.

## Features

- User authentication with JWT tokens
- Project management
- Task management with status tracking (TODO, IN_PROGRESS, IN_REVIEW, DONE)
- Task priority levels (LOW, MEDIUM, HIGH, URGENT)
- RESTful API endpoints
- Automatic API documentation with Swagger UI

## Tech Stack

- **FastAPI** - Modern, fast web framework for building APIs
- **SQLAlchemy** - SQL toolkit and Object-Relational Mapping (ORM) library
- **SQLite** - Lightweight database for development
- **Pydantic** - Data validation using Python type hints
- **JWT** - JSON Web Tokens for authentication
- **Uvicorn** - ASGI server implementation

## Project Structure

```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py              # FastAPI application setup
│   ├── api/
│   │   ├── __init__.py
│   │   ├── deps.py          # Authentication dependencies
│   │   └── v1/
│   │       ├── __init__.py
│   │       ├── auth.py      # Authentication endpoints
│   │       ├── projects.py  # Project endpoints
│   │       └── tasks.py     # Task endpoints
│   ├── core/
│   │   ├── __init__.py
│   │   ├── database.py      # Database configuration
│   │   └── security.py      # Security utilities
│   ├── crud/
│   │   ├── __init__.py
│   │   ├── base.py          # Base CRUD operations
│   │   ├── crud_user.py     # User CRUD operations
│   │   ├── crud_project.py  # Project CRUD operations
│   │   └── crud_task.py     # Task CRUD operations
│   ├── models/
│   │   ├── __init__.py
│   │   ├── base.py          # Base SQLAlchemy model
│   │   ├── user.py          # User model
│   │   ├── project.py       # Project model
│   │   └── task.py          # Task model
│   └── schemas/
│       ├── __init__.py
│       ├── base.py          # Base Pydantic schema
│       ├── user.py          # User schemas
│       ├── project.py       # Project schemas
│       └── task.py          # Task schemas
├── .env                     # Environment variables
├── requirements.txt         # Python dependencies
└── run.py                  # Application startup script
```

## Setup Instructions

1. **Clone and navigate to the backend directory:**
   ```bash
   cd backend
   ```

2. **Create a virtual environment:**
   ```bash
   python -m venv venv
   ```

3. **Activate the virtual environment:**
   ```bash
   # Windows
   venv\Scripts\activate
   
   # macOS/Linux
   source venv/bin/activate
   ```

4. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

5. **Run the application:**
   ```bash
   python run.py
   ```

   Or using uvicorn directly:
   ```bash
   uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
   ```

6. **Access the API:**
   - API Base URL: http://localhost:8000
   - Interactive API docs (Swagger UI): http://localhost:8000/docs
   - Alternative API docs (ReDoc): http://localhost:8000/redoc

## API Endpoints

### Authentication
- `POST /api/v1/auth/register` - Register a new user
- `POST /api/v1/auth/login` - Login and get access token
- `GET /api/v1/auth/me` - Get current user info (requires authentication)

### Projects
- `POST /api/v1/projects/` - Create a new project
- `GET /api/v1/projects/` - Get all projects for current user
- `GET /api/v1/projects/{id}` - Get a specific project
- `PUT /api/v1/projects/{id}` - Update a project
- `DELETE /api/v1/projects/{id}` - Delete a project

### Tasks
- `POST /api/v1/tasks/` - Create a new task
- `GET /api/v1/tasks/` - Get tasks (optionally filter by project_id)
- `GET /api/v1/tasks/{id}` - Get a specific task
- `PUT /api/v1/tasks/{id}` - Update a task
- `DELETE /api/v1/tasks/{id}` - Delete a task

## Usage Examples

### 1. Register a new user
```bash
curl -X POST "http://localhost:8000/api/v1/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "johndoe",
    "email": "john@example.com",
    "full_name": "John Doe",
    "password": "secretpassword"
  }'
```

### 2. Login to get access token
```bash
curl -X POST "http://localhost:8000/api/v1/auth/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=johndoe&password=secretpassword"
```

### 3. Create a project (requires authentication)
```bash
curl -X POST "http://localhost:8000/api/v1/projects/" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "My First Project",
    "description": "This is my first project",
    "key": "MFP"
  }'
```

### 4. Create a task (requires authentication)
```bash
curl -X POST "http://localhost:8000/api/v1/tasks/" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Implement user authentication",
    "description": "Add JWT-based authentication to the API",
    "project_id": 1,
    "priority": "high",
    "status": "todo"
  }'
```

## Database Models

### User
- id, username, email, full_name, hashed_password
- is_active, is_superuser
- created_at, updated_at

### Project
- id, name, description, key
- owner_id (foreign key to User)
- created_at, updated_at

### Task
- id, title, description
- status (TODO, IN_PROGRESS, IN_REVIEW, DONE)
- priority (LOW, MEDIUM, HIGH, URGENT)
- project_id (foreign key to Project)
- assignee_id (foreign key to User, optional)
- created_by_id (foreign key to User)
- estimate_hours, due_date
- created_at, updated_at

## Environment Variables

Create a `.env` file in the backend directory with the following variables:

```env
DATABASE_URL=sqlite:///./task_management.db
SECRET_KEY=your-super-secret-key-change-this-in-production-please
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
```

## Development

The application will automatically create the SQLite database file (`task_management.db`) when you first run it.

For development, the API runs with auto-reload enabled, so any changes to the code will automatically restart the server.

## Next Steps

- Add user roles and permissions
- Implement task comments and attachments
- Add task time tracking
- Create project templates
- Add email notifications
- Implement task dependencies
- Add file upload functionality
- Create dashboard with analytics

## Supabase / Postgres migration notes

If you want to use Supabase as the Postgres database backend, set `DATABASE_URL` to your Supabase Postgres connection string in the backend environment.

Quick local steps to migrate schema to Supabase project (testing):

1. Set environment variables for your backend (do NOT commit secrets):

```pwsh
setx DATABASE_URL "postgresql://<user>:<password>@<host>:5432/<db>" -m
setx SUPABASE_JWT_SECRET "<your-supabase-jwt-secret>" -m
```

2. Install dependencies and run the migrate helper (which creates missing tables and adds light schema changes):

```pwsh
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
python migrate.py
```

Note: This project's migration runner uses SQLAlchemy metadata to create missing tables. It also contains a small check script that attempts to add a `supabase_id` column and make `hashed_password` nullable where supported. For production workflows you should use Alembic or a robust migration plan.
