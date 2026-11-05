# Реліз Vestora v1.0.3 (Виправлення запуску на Android та завантаження фото у Web/PWA)

### 🐛 1. Виправлено помилку запуску на Android («Додаток містить помилку» / Crash on launch):
- **Співставлення namespace та Activity**: файл [`MainActivity.kt`](file:///c:/Users/Admin/Documents/NewProject/mobile_app/android/app/src/main/kotlin/com/vestora/app/MainActivity.kt) перенесено у пакет `com.vestora.app`, який очікує AndroidManifest та Gradle AGP. Раніше застарілий шлях `com.smartwardrobe.smart_wardrobe` викликав фатальну системну помилку `ClassNotFoundException` при спробі відкрити іконку додатку.
- **Повні правила ProGuard/R8 для шифрування та плагінів**: додано правила захисту від обфускації для `MainActivity`, `FlutterSecureStorage`, бібліотеки `Google Tink`, `SharedPreferences`, `Sqflite`, `PathProvider` та `AppLinks` у [`proguard-rules.pro`](file:///c:/Users/Admin/Documents/NewProject/mobile_app/android/app/proguard-rules.pro).
- **Підтримка MultiDex**: увімкнено `multiDexEnabled = true` у [`build.gradle.kts`](file:///c:/Users/Admin/Documents/NewProject/mobile_app/android/app/build.gradle.kts) для сумісності з широким спектром версій Android.
- **Безпечна ініціалізація `safeInit`**: у [`main.dart`](file:///c:/Users/Admin/Documents/NewProject/mobile_app/lib/main.dart) всі сервіси обгорнуті в ізольовані блоки обробки помилок, що гарантує 100% запуск інтерфейсу додатку навіть при тимчасових збоях хмари або пам'яті.

---

### 🌐 2. Виправлено помилку фото у Web/PWA («Could not load Blob from its URL. Has it been revoked?»):
- Усунуто конфлікт внутрішнього Web Canvas Resizer у `image_picker_for_web`: на Web-платформі розміри передаються напряму без виклику передчасного `URL.revokeObjectURL(blob)`, що спричиняло видалення фотографії з пам'яті браузера до її збереження.
- Додано автоматичний безпечний fallback через прямий HTTP/Blob зчитувач байтів при будь-яких мережевих обмеженнях браузера у [`add_item_screen.dart`](file:///c:/Users/Admin/Documents/NewProject/mobile_app/lib/screens/add_item_screen.dart) та [`virtual_fitting_screen.dart`](file:///c:/Users/Admin/Documents/NewProject/mobile_app/lib/screens/virtual_fitting_screen.dart).

---

### 📦 Завантаження оновленого додатку:
- **`app-release.apk`**: готовий файл для прямого встановлення на будь-який смартфон Android.
- **Web PWA**: автоматично розгорнуто за адресою [https://sergij-srt.github.io/vestora/](https://sergij-srt.github.io/vestora/).
