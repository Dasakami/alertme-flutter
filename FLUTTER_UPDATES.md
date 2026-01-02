# AlertMe Flutter - Полная документация обновлений

## 📦 Новые зависимости

```yaml
dependencies:
  # Аутентификация и JWT
  jwt_decoder: ^2.0.1
  
  # PIN код ввода для OTP
  pin_code_fields: ^8.0.0
  
  # Загрузка UI
  flutter_spinkit: ^5.2.0
  
  # Кэширование изображений
  cached_network_image: ^3.3.0
  
  # State Management
  riverpod: ^2.4.0
  flutter_riverpod: ^2.4.0
  
  # Network
  dio: ^5.3.0
  freezed_annotation: ^2.4.1
  json_serializable: ^6.7.1
  
  # Утилиты
  get_it: ^7.6.0
  uuid: ^4.0.0
```

## 🔐 Авторизация через SMS (обновлено)

### Flow регистрации
1. Пользователь вводит номер телефона и пароль
2. Система отправляет SMS код через Twilio
3. Пользователь вводит 6-значный код из SMS
4. Система верифицирует и выдает JWT токен

### Код
```dart
// auth_provider.dart
final authProvider = context.read<AuthProvider>();

// Шаг 1: Регистрация
await authProvider.register(
  phoneNumber: '+996555123456',
  password: 'Password123!',
  passwordConfirm: 'Password123!',
);

// Шаг 2: Отправка кода
final response = await authProvider.sendOTP('+996555123456');
// response['code'] - для тестирования (в продакшене не показывается)

// Шаг 3: Верификация кода
final success = await authProvider.verifyOTP(
  phoneNumber: '+996555123456',
  code: '123456',
);

if (success) {
  // Пользователь авторизован, переходим на главный экран
}
```

## 🎯 Система подписок (переработана)

### Новые возможности
1. ✅ Проверка premium статуса перед функциями
2. ✅ Активация кодов из Telegram с пролонгацией
3. ✅ Отображение дней до истечения подписки
4. ✅ Синхронизация с бэкендом

### Использование
```dart
// subscription_provider.dart
final subProvider = context.read<SubscriptionProvider>();

// Загрузка текущей подписки
await subProvider.loadCurrentSubscription();

if (subProvider.isPremium) {
  print('✅ Пользователь Premium');
  print('Дней осталось: ${subProvider.currentSubscription?.daysRemaining}');
}

// Активация кода
final success = await subProvider.activateCode('PROMO123ABC');

if (success) {
  print('✅ Подписка активирована!');
  print('До: ${subProvider.currentSubscription?.endDate}');
}
```

## 📱 Экраны

### OTPVerificationScreen
- Вод 6-значного кода из SMS
- Автоматическое переключение между полями
- Кнопка "Отправить повторно" с таймером
- Интеграция с authProvider

### ActivationCodeScreen
- Ввод кода активации подписки
- Валидация формата
- Проверка кода перед активацией
- Обновление UI после активации

### SubscriptionScreen
- Отображение текущей подписки (если Premium)
- Список функций Premium
- Кнопка "Активировать код"
- Инструкция по оплате

## 🔌 API интеграция

### Endpoints (обновлено)
```
POST /auth/register/ - Регистрация
POST /auth/send-sms/ - Отправка SMS кода
POST /auth/verify-sms/ - Верификация кода
POST /auth/login/ - Вход по номер+пароль

GET /subscriptions/current/ - Текущая подписка
POST /subscriptions/activate/ - Активация кода
GET /subscription-plans/ - Список планов
```

## 🛠️ Конфигурация

### lib/config/api_config.dart
```dart
const String apiBaseUrl = 'https://api.alertme.app';  // Продакшен
// const String apiBaseUrl = 'http://192.168.1.100:8000';  // Разработка
```

## 🧪 Тестирование

### Mock SMS код
Во время разработки бэкенд возвращает код в ответе:
```json
{
  "detail": "Verification code sent",
  "code": "123456",  // ДЛЯ ТЕСТИРОВАНИЯ
  "phone_number": "+996555123456"
}
```

### Тестовый акаунт
```
Номер: +996555123456
Пароль: TestPass123!
SMS код: 123456 (показывается в консоли бэкенда)
```

## ⚡ Производительность

### Кэширование
- Подписка кэшируется в SharedPreferences
- Обновляется при входе и активации кода
- LocalStorage сохраняет токены JWT

### Асинхронность
- Все запросы async/await
- Загрузка не блокирует UI
- Показываются Loading индикаторы

## 🔄 Обновление проекта

### Шаги
```bash
# 1. Обновить зависимости
flutter pub upgrade

# 2. Запустить генератор кода (если используется Freezed)
flutter pub run build_runner build

# 3. Проверить синтаксис
flutter analyze

# 4. Запустить тесты
flutter test
```

## 📊 Структура провайдеров

```
AuthProvider
├── isAuthenticated: bool
├── currentUser: UserModel?
├── register()
├── login()
├── sendOTP()
├── verifyOTP()
└── logout()

SubscriptionProvider
├── isPremium: bool
├── currentSubscription: UserSubscription?
├── plans: List<SubscriptionPlan>
├── loadCurrentSubscription()
├── activateCode()
└── loadPlans()
```

## 🚨 Обработка ошибок

### Пример
```dart
try {
  await authProvider.verifyOTP(phone, code);
} on ApiException catch (e) {
  // e.message содержит текст ошибки от сервера
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Ошибка: ${e.message}')),
  );
}
```

## 💡 Советы

1. **Всегда проверяйте isPremium** перед открытием Premium функций
2. **Загружайте подписку при старте** в главном экране
3. **Обновляйте подписку** после активации кода
4. **Кэшируйте данные** для быстрого отображения
5. **Тестируйте offline** режим с mock данными

## 📝 Логирование

Все операции логируются через logger пакет:
```dart
logger.i('✅ SMS код верифицирован');
logger.e('❌ Ошибка загрузки подписки', error: e);
```

## 🎓 Примеры использования

### Полный flow регистрации
```dart
// В экране регистрации
final authProvider = context.read<AuthProvider>();

// 1. Регистрация
await authProvider.register(
  phoneNumber: '+996555123456',
  password: 'TestPass123!',
  passwordConfirm: 'TestPass123!',
);

// 2. Переход на экран OTP
Navigator.push(context, MaterialPageRoute(
  builder: (_) => OTPVerificationScreen(phoneNumber: '+996555123456'),
));

// 3. В OTP экране - отправка и верификация кода
await authProvider.sendOTP('+996555123456');

// Пользователь вводит код
final success = await authProvider.verifyOTP(phone, code);

if (success) {
  // 4. Загружаем подписку
  final subProvider = context.read<SubscriptionProvider>();
  await subProvider.loadCurrentSubscription();
  
  // Переход на главный экран
  Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
}
```

### Проверка и активация подписки
```dart
final subProvider = context.read<SubscriptionProvider>();

// Загружаем при старте
await subProvider.loadCurrentSubscription();

// Проверяем статус
if (subProvider.isPremium) {
  print('🎉 Premium пользователь до ${subProvider.currentSubscription?.endDate}');
} else {
  print('📱 Free пользователь');
}

// Активация кода
if (subProvider.activateCode('PROMO123ABC')) {
  print('✅ Успешно активирован!');
  // UI автоматически обновится через notifyListeners()
}
```
