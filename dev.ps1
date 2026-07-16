# Tự động găm gói package vào bộ gỡ lỗi adb
adb shell setprop debug.firebase.analytics.app com.korokoro.journalai
# Sau đó tự khởi chạy app
flutter run --no-enable-impeller

#./dev.ps1