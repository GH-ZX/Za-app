# Quick Start Guide - For Non-Developers

This is a simple guide to get the Task Management System running on your computer in just a few steps.

## What You'll Need

Before starting, download and install:

1. **Docker Desktop**
   - Windows: [Download Docker Desktop for Windows](https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe)
   - Mac: [Download Docker Desktop for Mac](https://desktop.docker.com/mac/main/amd64/Docker.dmg)
   - After installation, open Docker Desktop and wait for it to start (you'll see a whale icon)

## Installation Steps

### Step 1: Download the Application

1. Download the application files to your computer
2. Extract the ZIP file to a folder (e.g., `My Documents/TaskManagement`)

### Step 2: Start the Application

**Windows:**
1. Open the application folder
2. Hold `Shift` and right-click in an empty space
3. Select "Open PowerShell window here" or "Open in Terminal"
4. Type this command and press Enter:
   ```
   docker-compose up
   ```

**Mac:**
1. Open Terminal (find it in Applications → Utilities)
2. Type `cd ` (with a space after cd)
3. Drag the application folder into the Terminal window and press Enter
4. Type this command and press Enter:
   ```
   docker-compose up
   ```

5. Wait for the messages to stop scrolling (about 2-3 minutes)
6. Look for a message that says "Application startup complete"

### Step 3: Open the Application

1. Open your web browser (Chrome, Firefox, Safari, or Edge)
2. Go to: **http://localhost**
3. You should see the login page! 🎉

## First Time Setup

### Create Your Account

1. Click **"إنشاء حساب"** (Create Account) button
2. Fill in your information:
   - Username
   - Email
   - Password
   - Full Name
3. Click **"إنشاء"** (Create)
4. You'll be logged in automatically

### Create Your First Project

1. Click **"المشاريع"** (Projects) in the sidebar
2. Click the blue **"مشروع جديد"** (New Project) button
3. Enter:
   - Project Name (e.g., "My First Project")
   - Project Key (2-5 letters, like "PROJ")
   - Description (optional)
4. Click **"إنشاء"** (Create)

### Create Your First Task

1. Click on your project name
2. Click **"مهمة جديدة"** (New Task)
3. Fill in the task details
4. Click **"إنشاء"** (Create)
5. Your task appears on the board!

## Daily Usage

### Starting the Application

**Every time you want to use the application:**

1. Make sure Docker Desktop is running (check for the whale icon)
2. Open Terminal/PowerShell in the application folder
3. Run: `docker-compose up`
4. Wait 1-2 minutes
5. Open your browser to: http://localhost

### Stopping the Application

**When you're done working:**

1. Go to the Terminal/PowerShell window
2. Press `Ctrl + C` (Windows/Linux) or `Command + C` (Mac)
3. Wait for it to shut down
4. Close the window
<!-- 
## Quick Reference

### Important Addresses

- **Application:** http://localhost
- **API Documentation:** http://localhost:8000/docs

### Common Tasks

| I want to... | How to do it |
|--------------|--------------|
| Create a project | Click "المشاريع" → "مشروع جديد" button |
| Create a task | Click project → "مهمة جديدة" button |
| Move a task | Drag and drop the task card to a different column |
| Edit a task | Click on the task card |
| Delete a task | Click task → Click trash icon |
| Search tasks | Use the search box at the top |
| Filter tasks | Click the filter buttons above the board |

## Troubleshooting

### "Cannot connect" or "Page not loading"

**Solution:**
1. Make sure Docker Desktop is running
2. Check the Terminal/PowerShell window for error messages
3. Wait a full 2-3 minutes after starting
4. Try refreshing your browser (F5)

### "Port already in use" error

**Solution:**
1. Close any other web servers or applications
2. Or change the port in `docker-compose.yml`:
   ```yaml
   frontend:
     ports:
       - "8080:80"  # Changed from 80:80
   ```
3. Then access at: http://localhost:8080

### Application won't start

**Solution:**
1. Open Docker Desktop and make sure it's running
2. In Terminal/PowerShell, type:
   ```
   docker-compose down
   docker-compose up --build
   ```
3. Wait for the rebuild to complete

### Forgot my password

**Solution:**
Unfortunately, there's no "forgot password" feature yet. You'll need to:
1. Stop the application
2. Delete the database file (see "Reset Everything" below)
3. Start fresh with a new account

## Advanced Options

### Reset Everything (Start Fresh)

⚠️ **Warning:** This deletes all your data!

1. Stop the application (Ctrl+C)
2. Run this command:
   ```
   docker-compose down -v
   ```
3. Start again: `docker-compose up`

### Run in Background

If you don't want to keep the Terminal window open:

1. Start with: `docker-compose up -d`
2. Stop with: `docker-compose down`

### View Application Logs

If something goes wrong:

```
docker-compose logs -f
```

Press `Ctrl+C` to stop viewing logs.

## Getting Help

### Check the Documentation

- Full guide: `docs/getting-started.md`
- Docker guide: `docs/docker-guide.md`
- Deployment checklist: `docs/deployment-checklist.md`

### Common Questions

**Q: Can I access this from another computer?**  
A: Yes, but you need to change `localhost` to your computer's IP address. This requires network configuration.

**Q: Is my data saved when I close the application?**  
A: Yes! Your data is saved in Docker volumes and will be there when you restart.

**Q: Can multiple people use this at the same time?**  
A: Yes, if they access it through your computer's IP address on the same network.

**Q: How do I backup my data?**  
A: See the "Volume Management" section in `docs/docker-guide.md`

**Q: Can I use this on my phone?**  
A: Yes! The interface is mobile-friendly. Just open your computer's IP address in your phone's browser.

## Tips for Best Experience

✅ **DO:**
- Keep Docker Desktop updated
- Backup your data regularly
- Use strong passwords
- Close the application when not in use to save resources

❌ **DON'T:**
- Don't delete the application folder while it's running
- Don't edit files while the application is running (except `.env`)
- Don't share your SECRET_KEY with others
- Don't use the same password for everything

## System Requirements

**Minimum:**
- Windows 10/11, macOS 10.15+, or modern Linux
- 4 GB RAM
- 2 GB free disk space
- Internet connection (for initial setup)

**Recommended:**
- 8 GB RAM or more
- 5 GB free disk space
- Modern web browser (Chrome, Firefox, Safari, Edge)

## Need More Help?

If you're stuck:

1. Check the error message in the Terminal/PowerShell window
2. Read the full documentation in the `docs` folder
3. Ask your developer friend or IT support
4. Check if Docker Desktop is running properly -->

---

**Congratulations! You're ready to start managing your tasks! 🎉**

Remember: The first time you start might take 3-5 minutes to download everything. After that, it's usually just 1-2 minutes.

---

*Last updated: October 2025*
