@echo off
echo ========================================
echo Google Sign-In Fix Script
echo ========================================
echo.

echo Step 1: Getting SHA-1 fingerprint...
echo.
cd android
echo Running gradlew signingReport...
gradlew signingReport > ../sha1_output.txt 2>&1

echo.
echo SHA-1 fingerprint has been saved to sha1_output.txt
echo.
echo Step 2: Please follow these instructions:
echo.
echo 1. Open sha1_output.txt file in the project root
echo 2. Look for the "debug" section
echo 3. Copy the SHA1 fingerprint (format: XX:XX:XX:...)
echo 4. Go to Firebase Console: https://console.firebase.google.com/
echo 5. Select project: gateease-23400
echo 6. Go to Project Settings (gear icon)
echo 7. Scroll to "Your apps" section
echo 8. Find Android app: com.example.gate_ease
echo 9. Click "Add fingerprint"
echo 10. Paste the SHA1 fingerprint
echo 11. Click Save
echo 12. Download new google-services.json
echo 13. Replace android/app/google-services.json
echo 14. Run: flutter clean && flutter pub get
echo.
echo Press any key to continue...
pause > nul

cd ..
echo.
echo Step 3: Cleaning and rebuilding...
flutter clean
flutter pub get

echo.
echo ========================================
echo Fix completed!
echo ========================================
echo.
echo If Google Sign-In still fails:
echo 1. Make sure you added the correct SHA1 fingerprint
echo 2. Make sure you downloaded the updated google-services.json
echo 3. Try restarting the app completely
echo.
pause