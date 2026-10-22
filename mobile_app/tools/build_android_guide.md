# 📱 Збірка Android (APK та AAB для Google Play)

## Варіант 1: Автоматична збірка в хмарі через GitHub Actions (Рекомендовано)
Репозиторій містить готовий workflow [`.github/workflows/build_and_deploy.yml`](file:///c:/Users/Admin/Documents/NewProject/.github/workflows/build_and_deploy.yml).
Кожен push у гілку `master` автоматично:
1. Запускає віртуальну машину Ubuntu з Java 17 та Android SDK.
2. Проганяє всі 71 юніт/віджет-тест та лінтер.
3. Збирає:
   - `app-release.apk` (для прямого тестування на будь-якому Android-смартфоні).
   - `app-release.aab` (Android App Bundle для публікації в Google Play Console).
4. Завантажує готові файли в розділ **Actions -> Artifacts** вашого GitHub репозиторію.

---

## Варіант 2: Локальна збірка на комп'ютері

### 1. Генерація ключа підпису (Keystore)
Для створення ключа підпису для Google Play запустіть у терміналі:
```bash
keytool -genkey -v -keystore vestora-release-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias vestora-release-key
```

### 2. Створення файлу `key.properties`
Створіть файл `mobile_app/android/key.properties` на основі `key.properties.example`:
```properties
storePassword=ВашПарольДоСховища
keyPassword=ВашПарольКлюча
keyAlias=vestora-release-key
storeFile=../vestora-release-keystore.jks
```

### 3. Команди збірки
- **Збірка універсального APK для тестування**:
  ```powershell
  flutter build apk --release
  ```
  Файл з'явиться в `mobile_app/build/app/outputs/flutter-apk/app-release.apk`.

- **Збірка оптимізованого AAB для Google Play**:
  ```powershell
  flutter build appbundle --release
  ```
  Файл з'явиться в `mobile_app/build/app/outputs/bundle/release/app-release.aab`.
