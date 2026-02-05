@echo off
echo ==========================================
echo 🦁 GymBrain Web Build & Transfer 🦁
echo ==========================================

echo.
echo [1/3] Cleaning old build...
call flutter clean

echo.
echo [2/3] Building Web App (No Skia / HTML Renderer)...
:: الأمر الجديد اللي طلبته
call flutter build web --release --dart-define=FLUTTER_WEB_USE_SKIA=false

echo.
echo [3/3] Transferring files to Dist Folder...
:: حدد المسار هنا (تأكد إنه صح)
set DIST_PATH=gym_brain_dist

:: بنمسح القديم في فولدر التوزيع عشان نضمن إن مفيش ملفات زيادة
if exist "%DIST_PATH%\" (
    del /q "%DIST_PATH%\*"
    for /d %%x in ("%DIST_PATH%\*") do @rd /s /q "%%x"
) else (
    mkdir "%DIST_PATH%"
)

:: بننسخ الجديد (Copy) - ده أضمن من Cut
xcopy /s /y "build\web\*" "%DIST_PATH%\"

echo.
echo ✅ DONE! Files are ready in: %DIST_PATH%
echo You can now manually zip or upload this folder.
pause