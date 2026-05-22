@echo off
cd /d "%~dp0"
echo === Setting Git identity ===
git config user.name "Angs009"
git config user.email "Angs009@users.noreply.github.com"

echo === Committing ns.yml ===
git add .
git commit -m "Added Kubernetes namespace manifest"
if errorlevel 1 (
  echo COMMIT FAILED - see message above
  pause
  exit /b 1
)

echo === Pushing to GitHub ===
git branch -M main
git remote remove origin 2>nul
git remote add origin https://github.com/Angs009/k8-killercoda.git
git push -u origin main

if errorlevel 1 (
  echo.
  echo PUSH FAILED - sign in when browser opens, then run this file again.
  pause
  exit /b 1
)

echo.
echo DONE! Open: https://github.com/Angs009/k8-killercoda
pause
