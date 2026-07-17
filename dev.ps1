# 1. Build debug APK
flutter build apk --debug

# 2. Cài APK lên emulator
adb install -r build/app/outputs/flutter-apk/app-debug.apk

# 3. Set debug property SAU KHI cài, TRƯỚC KHI khởi chạy app
adb shell setprop debug.firebase.analytics.app com.example.lab2

# 4. Khởi chạy app (app sẽ đọc debug property ngay khi Analytics init)
adb shell am start -n com.example.lab2/.MainActivity

# 5. Theo dõi logcat realtime (Ctrl+C để thoát)
adb logcat -s flutter,FA,Analytics
