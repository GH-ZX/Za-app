# Getting Started

This guide helps you run the full app locally.

## Prerequisites
- Python 3.11+
- Node.js 18+

## Backend setup
```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\activate
pip install -r requirements.txt
python run.py
```
- API: http://localhost:8000
- Docs: http://localhost:8000/docs

## Frontend setup
```powershell
cd frontend
npm install
npm start
```
- App: http://localhost:3000

## Environment variables
- `backend/.env`
- `frontend/.env` (optional):
```env
REACT_APP_API_URL=http://localhost:8000
```

## First steps
1. Register a new user in the UI.
2. Create your first project.
3. Create tasks and manage them on the Kanban board.
4. If you are an admin, explore the Admin Dashboard.
