@echo off
cd /d "%~dp0"

git config user.name "Angs009"
git config user.email "Angs009@users.noreply.github.com"

if not exist .git git init
git branch -M main
git add ns.yml
git commit -m "Added Kubernetes namespace manifest"
git remote remove origin 2>nul
git remote add origin https://github.com/Angs009/k8-killercoda.git
git push -u origin main

if %ERRORLEVEL% EQU 0 (
  echo.
  echo SUCCESS: https://github.com/Angs009/k8-killercoda
) else (
  echo.
  echo PUSH FAILED. Sign in when prompted, or run: gh auth login
)
pause
