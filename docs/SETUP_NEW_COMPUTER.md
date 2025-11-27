# Setting Up This Project on a New Computer

This guide helps you get the AI Trading Platform running when accessing the external drive from a different computer.

---

## Prerequisites

### Required Software
| Software | Purpose | Install Command (macOS) |
|----------|---------|------------------------|
| VS Code | IDE | Download from code.visualstudio.com |
| Git | Version control | `brew install git` |
| Node.js | Web frontend | `brew install node` |
| pnpm | Package manager | `npm install -g pnpm` |
| Python 3.11+ | Backend | `brew install python@3.11` |

---

## Quick Setup Checklist

### 1. VS Code Settings Sync (One-Time)
If Settings Sync is already enabled on your main computer, just sign in on the new one:

1. Open VS Code
2. `Cmd+Shift+P` → **"Settings Sync: Turn On"**
3. Sign in with **GitHub** (same account as main computer)
4. Wait for extensions to install automatically

Your extensions, settings, keybindings, and snippets will sync.

### 2. Git Configuration (One-Time per Computer)
```bash
# Set your identity
git config --global user.name "Your Name"
git config --global user.email "your@email.com"

# Verify remote access (test with a pull)
cd /Volumes/YOUR_DRIVE/ai-trading-platform
git pull
```

If push fails, set up authentication:
- **SSH**: Copy your SSH key or generate new one with `ssh-keygen`
- **HTTPS**: Use GitHub CLI (`gh auth login`) or personal access token

### 3. Open the Project
```bash
# Navigate to project on external drive
cd /Volumes/YOUR_DRIVE/ai-trading-platform

# Open in VS Code
code .
```

### 4. Web Frontend Setup
```bash
cd web
pnpm install
pnpm dev
```
Dashboard runs at http://localhost:5173

### 5. Backend Setup
```bash
cd backend

# Create virtual environment (one-time per computer)
python3 -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

---

## What Travels With the Drive

| Item | Location | Portable? |
|------|----------|-----------|
| Source code | `./` | ✅ Yes |
| Git history | `.git/` | ✅ Yes |
| Project settings | `.vscode/` | ✅ Yes |
| Chat logs | `LOCAL_DRIVE_CHAT_LOG.md` | ✅ Yes |
| Node modules | `web/node_modules/` | ⚠️ Reinstall with `pnpm install` |
| Python venv | `backend/.venv/` | ❌ Recreate per computer |

---

## What Stays on Each Computer

| Item | Why | Action |
|------|-----|--------|
| VS Code extensions | Installed per-computer | Settings Sync handles this |
| Git credentials | Security | Set up once per computer |
| Python interpreter | System-level | Install Python if missing |
| Node.js/pnpm | System-level | Install if missing |

---

## Troubleshooting

### "Python interpreter not found"
```bash
# VS Code needs to know where Python is
Cmd+Shift+P → "Python: Select Interpreter"
# Choose the .venv in backend/ or system Python
```

### "pnpm: command not found"
```bash
npm install -g pnpm
```

### Git push rejected
```bash
# Always pull before starting work
git pull origin main

# If conflicts, resolve them or:
git stash
git pull
git stash pop
```

### Extensions not syncing
1. Check Settings Sync is enabled: `Cmd+Shift+P` → "Settings Sync: Show Synced Data"
2. Force sync: `Cmd+Shift+P` → "Settings Sync: Sync Now"

---

## First-Time Workflow on New Computer

```bash
# 1. Plug in external drive
# 2. Open terminal

cd /Volumes/YOUR_DRIVE/ai-trading-platform
git pull                          # Get latest changes

# 3. Open in VS Code
code .

# 4. Set up environments (one-time)
cd web && pnpm install && cd ..
cd backend && python3 -m venv .venv && source .venv/bin/activate && pip install -r requirements.txt

# 5. Start working!
```

---

## Notes

- **Settings Sync** is already enabled on the primary iMac
- This project uses **GitHub** for remote repository: `psjvortex/ai-trading-platform`
- Chat logs are maintained per-drive to track conversations specific to each location

---

*Last updated: November 27, 2025*
