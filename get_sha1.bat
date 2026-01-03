@echo off
echo Getting SHA-1 fingerprint for Google Sign-In configuration...
echo.
echo Debug SHA-1 (for development):
cd android
gradlew signingReport
echo.
echo Copy the SHA1 fingerprint from the debug keystore above and add it to your Firebase project:
echo 1. Go to Firebase Console
echo 2. Select your project
echo 3. Go to Project Settings
echo 4. Add the SHA1 fingerprint under "Your apps" section
echo.
pause