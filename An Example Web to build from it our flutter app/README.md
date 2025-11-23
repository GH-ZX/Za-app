# Task Management System | نظام إدارة المهام

A modern, full-stack task management system with Kanban board functionality, similar to Jira. Built with FastAPI (Python) backend and React (TypeScript) frontend, featuring full Arabic language support and RTL layout.

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Python](https://img.shields.io/badge/python-3.11+-blue.svg)
![Node](https://img.shields.io/badge/node-18+-green.svg)
![Docker](https://img.shields.io/badge/docker-ready-blue.svg)

## ✨ Features

### Core Functionality
- 🔐 **User Authentication** - JWT-based secure authentication system
- 📊 **Project Management** - Create and organize projects with custom keys
- ✅ **Task Management** - Full CRUD operations for tasks with rich metadata
- 🎯 **Kanban Board** - Drag-and-drop interface for task status updates
- 📋 **List View** - Table-based task overview with filtering
- 🔍 **Advanced Filtering** - Filter tasks by status, priority, search text
- 📝 **Inline Editing** - Quick task updates via drawer interface
- 🔗 **Shareable Links** - Direct task links with URL query parameters
- 👥 **Admin Dashboard** - System statistics, user management, charts
- 🌐 **Full Arabic Support** - Complete RTL interface with Arabic translations

### Technical Features
- 🚀 **Fast API** - High-performance async backend with automatic API docs
- ⚛️ **React 18** - Modern frontend with hooks and TypeScript
- 🎨 **Tailwind CSS** - Utility-first styling with RTL support
- 🐳 **Docker Ready** - Multi-stage builds and docker-compose orchestration
- 📱 **Responsive Design** - Mobile-friendly interface
- 🔒 **Security** - Password hashing, JWT tokens, CORS configuration
- 📈 **Charts & Analytics** - Task distribution visualization
- ✨ **Form Validation** - Client and server-side validation
- 🎭 **Error Handling** - User-friendly error messages in Arabic

## 🏗️ Architecture

```
7eshamt/
├── backend/               # FastAPI backend
│   ├── app/
│   │   ├── api/          # API endpoints
│   │   ├── core/         # Config, database, security
│   │   ├── crud/         # Database operations
│   │   ├── models/       # SQLAlchemy models
│   │   └── schemas/      # Pydantic schemas
│   ├── Dockerfile
│   └── requirements.txt
├── frontend/             # React frontend
│   ├── public/
│   ├── src/
│   │   ├── components/   # React components
│   │   ├── services/     # API clients
│   │   ├── types/        # TypeScript types
│   │   └── translations/ # Arabic translations
│   ├── Dockerfile
│   ├── nginx.conf
│   └── package.json
├── docker-compose.yml
└── docs/
    └── getting-started.md
```

## 🚀 Quick Start

> **📖 New to development?** Start with **[QUICK_START.md](QUICK_START.md)** for a beginner-friendly guide!  
> **⚡ Need a quick reference?** Check **[CHEATSHEET.md](CHEATSHEET.md)** for one-page commands!

### Option 1: Docker (Recommended)

```bash
# Clone the repository
git clone <repository-url>
cd 7eshamt

# Configure environment
cp .env.example .env
# Edit .env and set SECRET_KEY

# Start with Docker Compose
docker-compose up --build

# Access the application
# Frontend: http://localhost
# Backend: http://localhost:8000
# API Docs: http://localhost:8000/docs
```

### Option 2: Manual Setup

**Prerequisites:**
- Python 3.11+
- Node.js 18+
- npm

**Backend:**
```bash
cd backend
python -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate
pip install -r requirements.txt
python run.py
```

**Frontend:**
```bash
cd frontend
npm install
npm start
```

### 📚 Documentation for All Levels

- **🎯 [QUICK_START.md](QUICK_START.md)** - Beginner-friendly guide for non-developers
- **⚡ [CHEATSHEET.md](CHEATSHEET.md)** - One-page quick reference with all commands
- **📖 [Getting Started Guide](docs/getting-started.md)** - Comprehensive setup for all platforms
- **🐳 [Docker Guide](docs/docker-guide.md)** - Detailed Docker commands and troubleshooting
- **🚀 [Deployment Checklist](docs/deployment-checklist.md)** - Production deployment guide

## 📖 Documentation

### For Non-Developers
- **[QUICK_START.md](QUICK_START.md)** - Step-by-step guide with screenshots concepts
- **[CHEATSHEET.md](CHEATSHEET.md)** - One-page reference for daily use

### For Developers
- **[Getting Started Guide](docs/getting-started.md)** - Comprehensive setup for all platforms (Windows, macOS, Linux, Docker)
- **[Docker Guide](docs/docker-guide.md)** - Docker commands, troubleshooting, and best practices
- **[Task Management Guide](docs/task-management-guide.md)** - How to use board, list, filters, drawer
- **[API Reference](docs/api.md)** - Complete API documentation

### For System Administrators
- **[Deployment Checklist](docs/deployment-checklist.md)** - Production deployment procedures
- **[Docker Guide](docs/docker-guide.md)** - Container orchestration and management

### Interactive API Docs
- **Swagger UI** - http://localhost:8000/docs
- **ReDoc** - http://localhost:8000/redoc

## 📦 API Endpoints

### Authentication
```
POST   /api/auth/register      # Register new user
POST   /api/auth/login         # Login user
GET    /api/auth/me            # Get current user
```

### Projects
```
GET    /api/projects           # List all projects
POST   /api/projects           # Create project
GET    /api/projects/{id}      # Get project details
PUT    /api/projects/{id}      # Update project
DELETE /api/projects/{id}      # Delete project
```

### Tasks
```
GET    /api/tasks              # List tasks (with filters)
POST   /api/tasks              # Create task
GET    /api/tasks/{id}         # Get task details
PUT    /api/tasks/{id}         # Update task
DELETE /api/tasks/{id}         # Delete task
```

### Admin
```
GET    /api/admin/stats        # System statistics
GET    /api/admin/users        # List users
PUT    /api/admin/users/{id}   # Update user status
```

## 🔧 Configuration

### Environment Variables

**Backend (.env):**
```env
SECRET_KEY=<generate-secure-key>
JWT_SECRET_KEY=<generate-secure-key>
ENVIRONMENT=development
DATABASE_URL=sqlite:///./task_management.db
CORS_ORIGINS=http://localhost:3000,http://localhost:80
```

**Frontend (.env):**
```env
REACT_APP_API_URL=http://localhost:8000
```

### Generate Secure Keys

```bash
# Python
python -c "import secrets; print(secrets.token_urlsafe(32))"

# OpenSSL (macOS/Linux)
openssl rand -base64 32

# PowerShell (Windows)
[Convert]::ToBase64String([System.Security.Cryptography.RandomNumberGenerator]::GetBytes(32))
```

## 🛠️ Technology Stack

### Backend
- **FastAPI** - Modern Python web framework
- **SQLAlchemy** - SQL toolkit and ORM
- **SQLite** - Lightweight database (easily swappable)
- **Pydantic** - Data validation using Python type hints
- **python-jose** - JWT token handling
- **passlib** - Password hashing with bcrypt
- **uvicorn** - ASGI server

### Frontend
- **React 18** - UI library
- **TypeScript** - Type-safe JavaScript
- **React Router** - Client-side routing
- **Tailwind CSS** - Utility-first CSS framework
- **react-hook-form** - Form state management
- **react-hot-toast** - Toast notifications
- **Recharts** - Chart library for admin dashboard
- **@hello-pangea/dnd** - Drag-and-drop for Kanban board

### DevOps
- **Docker** - Containerization
- **Docker Compose** - Multi-container orchestration
- **Nginx** - Static file serving and reverse proxy
- **Multi-stage builds** - Optimized production images

## 🧪 Development

### Running Tests

```bash
# Backend tests
cd backend
pytest

# Frontend tests
cd frontend
npm test
```

### Code Formatting

```bash
# Backend
cd backend
black .
isort .

# Frontend
cd frontend
npm run lint
```

### Building for Production

```bash
# Frontend production build
cd frontend
npm run build

# Backend with Gunicorn
cd backend
gunicorn -w 4 -k uvicorn.workers.UvicornWorker app.main:app
```

## 🐳 Docker Commands

```bash
# Start services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Rebuild after changes
docker-compose up --build

# Remove volumes (reset database)
docker-compose down -v
```

## 🌍 Internationalization

The application currently supports Arabic with RTL layout. The translation system is built using a custom implementation that supports:

- Nested translation keys
- Dynamic value interpolation
- Fallback handling
- Type-safe translations

To add new translations, edit `frontend/src/translations/ar.ts`.

## 🔒 Security

- Password hashing using bcrypt
- JWT token authentication
- CORS configuration
- Input validation (client & server)
- SQL injection prevention via ORM
- Environment-based secrets

## 📝 License

This project is licensed under the MIT License.

## 🤝 Contributing

Contributions are welcome! See `CONTRIBUTING.md` for guidelines.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 🐛 Bug Reports

Found a bug? Please open an issue with:
- Description of the bug
- Steps to reproduce
- Expected behavior
- Screenshots (if applicable)
- Environment details (OS, browser, versions)

## 📧 Contact

For questions or feedback, please open an issue on GitHub.

---

**Built with ❤️ using FastAPI, React, and TypeScript**
