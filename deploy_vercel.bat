@echo off
echo ==========================================
echo 🦁 GymBrain Web Deployment Automator 🦁
echo ==========================================

echo.
echo [1/4] Cleaning old build...
call flutter clean

echo.
echo [2/4] Building Web App (HTML Renderer for compatibility)...
call flutter build web --release --web-renderer html

echo.
echo [3/4] Copying files to Deployment Folder...
:: قم بتغيير المسار ده لمسار فولدر النشر اللي عملناه في الخطوة 1
set DEPLOY_PATH=..\gym_brain_dist

:: بنمسح القديم في فولدر النشر عشان لو فيه ملفات زيادة
del /q "%DEPLOY_PATH%\*"
for /d %%x in ("%DEPLOY_PATH%\*") do @rd /s /q "%%x"

:: بننسخ الجديد من فولدر البيلد
xcopy /s /y "build\web\*" "%DEPLOY_PATH%\"

echo.
echo [4/4] Pushing to GitHub (Triggering Vercel)...
cd "%DEPLOY_PATH%"
git add .
git commit -m "🚀 Auto-deploy: New Update"
git push -u origin main

echo.
echo ✅ DONE! Check Vercel Dashboard.
pause