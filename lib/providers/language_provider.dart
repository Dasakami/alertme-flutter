import 'package:flutter/foundation.dart';

class LanguageProvider with ChangeNotifier {
  String _currentLanguage = 'ru';

  String get currentLanguage => _currentLanguage;
  bool get isRussian => _currentLanguage == 'ru';
  bool get isKyrgyz => _currentLanguage == 'kg';

  void setLanguage(String language) {
    if (language == 'ru' || language == 'kg') {
      _currentLanguage = language;
      notifyListeners();
    }
  }

  String translate(String key) {
    final translations = _translations[key];
    if (translations == null) return key;
    return translations[_currentLanguage] ?? key;
  }

  static const Map<String, Map<String, String>> _translations = {
    'app_name': {'ru': 'alertme', 'kg': 'alertme'},
    'welcome': {'ru': 'Добро пожаловать', 'kg': 'Кош келиңиз'},
    'onboarding_title_1': {'ru': 'Ваша безопасность', 'kg': 'Сиздин коопсуздугуңуз'},
    'onboarding_desc_1': {'ru': 'Один жест - и помощь уже в пути', 'kg': 'Бир жест менен жардам жолдо'},
    'onboarding_title_2': {'ru': 'Доверенные контакты', 'kg': 'Ишенимдүү байланыштар'},
    'onboarding_desc_2': {'ru': 'Добавьте близких людей для экстренных случаев', 'kg': 'Өзгөчө учурлар үчүн жакындарыңызды кошуңуз'},
    'onboarding_title_3': {'ru': 'Всегда на связи', 'kg': 'Ар дайым байланышта'},
    'onboarding_desc_3': {'ru': 'Быстрое реагирование в любой ситуации', 'kg': 'Каалаган учурда тез жооп'},
    'get_started': {'ru': 'Начать', 'kg': 'Баштоо'},
    'phone_number': {'ru': 'Номер телефона', 'kg': 'Телефон номери'},
    'enter_phone': {'ru': 'Введите номер телефона', 'kg': 'Телефон номерин киргизиңиз'},
    'send_code': {'ru': 'Отправить код', 'kg': 'Код жөнөтүү'},
    'verify_code': {'ru': 'Введите код', 'kg': 'Кодду киргизиңиз'},
    'verification_sent': {'ru': 'Код отправлен на', 'kg': 'Код жөнөтүлдү'},
    'verify': {'ru': 'Подтвердить', 'kg': 'Ырастоо'},
    'sos': {'ru': 'SOS', 'kg': 'SOS'},
    'hold_for_sos': {'ru': 'Удерживайте для SOS', 'kg': 'SOS үчүн кармап туруңуз'},
    'sos_activated': {'ru': 'SOS активирован', 'kg': 'SOS иштетилди'},
    'sending_alert': {'ru': 'Отправка сигнала...', 'kg': 'Сигнал жөнөтүлүүдө...'},
    'recording_audio': {'ru': 'Запись аудио', 'kg': 'Аудио жаздыруу'},
    'cancel': {'ru': 'Отменить', 'kg': 'Жокко чыгаруу'},
    'contacts': {'ru': 'Контакты', 'kg': 'Байланыштар'},
    'add_contact': {'ru': 'Добавить контакт', 'kg': 'Байланыш кошуу'},
    'emergency_contacts': {'ru': 'Экстренные контакты', 'kg': 'Өзгөчө учурдагы байланыштар'},
    'no_contacts': {'ru': 'Нет контактов', 'kg': 'Байланыштар жок'},
    'add_first_contact': {'ru': 'Добавьте первый контакт', 'kg': 'Биринчи байланышты кошуңуз'},
    'name': {'ru': 'Имя', 'kg': 'Аты'},
    'save': {'ru': 'Сохранить', 'kg': 'Сактоо'},
    'delete': {'ru': 'Удалить', 'kg': 'Өчүрүү'},
    'safety_timer': {'ru': 'Таймер безопасности', 'kg': 'Коопсуздук таймери'},
    'set_timer': {'ru': 'Установить таймер', 'kg': 'Таймерди коюу'},
    'timer_active': {'ru': 'Таймер активен', 'kg': 'Таймер иштеп жатат'},
    'minutes': {'ru': 'минут', 'kg': 'мүнөт'},
    'settings': {'ru': 'Настройки', 'kg': 'Жөндөөлөр'},
    'profile': {'ru': 'Профиль', 'kg': 'Профиль'},
    'language': {'ru': 'Язык', 'kg': 'Тил'},
    'subscription': {'ru': 'Подписка', 'kg': 'Жазылуу'},
    'notifications': {'ru': 'Уведомления', 'kg': 'Билдирмелер'},
    'logout': {'ru': 'Выйти', 'kg': 'Чыгуу'},
    'free': {'ru': 'Бесплатно', 'kg': 'Акысыз'},
    'premium': {'ru': 'Premium', 'kg': 'Premium'},
    'upgrade_to_premium': {'ru': 'Обновить до Premium', 'kg': 'Premium чейин жаңыртуу'},
    'premium_features': {'ru': 'Возможности Premium', 'kg': 'Premium мүмкүнчүлүктөр'},
    'unlimited_contacts': {'ru': 'Неограниченные контакты', 'kg': 'Чексиз байланыштар'},
    'location_history': {'ru': 'История местоположений', 'kg': 'Жайгашкан жердин тарыхы'},
    'subscribe': {'ru': 'Оформить подписку', 'kg': 'Жазылуу'},
    'home': {'ru': 'Главная', 'kg': 'Башкы'},
    'timer': {'ru': 'Таймер', 'kg': 'Таймер'},
    'contact_limit_reached': {'ru': 'Достигнут лимит контактов', 'kg': 'Байланыштар лимити толду'},
    'upgrade_for_more': {'ru': 'Обновитесь до Premium для большего', 'kg': 'Көбүрөөк үчүн Premium чейин жаңыртыңыз'},
    'sign_in': {'ru': 'Войти', 'kg': 'Кирүү'},
    'create_account': {'ru': 'Создать аккаунт', 'kg': 'Каттоо түзүү'},
    'welcome_back': {'ru': 'С возвращением!', 'kg': 'Кайрадан кош келиңиз!'},
    'password': {'ru': 'Пароль', 'kg': 'Сырсөз'},
    'confirm_password': {'ru': 'Подтвердите пароль', 'kg': 'Сырсөздү тастыктаңыз'},
    'continue': {'ru': 'Продолжить', 'kg': 'Улантуу'},
  };
}
