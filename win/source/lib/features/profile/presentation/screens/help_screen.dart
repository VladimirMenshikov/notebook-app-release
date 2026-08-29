import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Документация'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: const [
          _HelpSection(
            icon: Icons.login,
            title: 'Регистрация и вход',
            items: [
              'При регистрации укажите email и пароль (не короче 6 символов). '
                  'На почту придёт письмо с 6-значным кодом подтверждения — '
                  'введите его в приложении, выберите аватар и имя.',
              'Для входа используйте тот же email и пароль. Если на устройстве '
                  'уже был выполнен вход и включён отпечаток пальца — на экране '
                  'входа появится кнопка «Войти по отпечатку».',
            ],
          ),
          _HelpSection(
            icon: Icons.note_alt_outlined,
            title: 'Заметки',
            items: [
              'Кнопка «Новая заметка» внизу экрана — заголовок и текст.',
              'Нажмите на заметку, чтобы отредактировать.',
              'Звёздочка добавляет заметку в избранное.',
              'Смахните заметку влево, чтобы удалить (с подтверждением).',
              'Поиск ищет по заголовку и содержимому заметки.',
            ],
          ),
          _HelpSection(
            icon: Icons.task_alt_outlined,
            title: 'Задачи',
            items: [
              'При создании задачи можно указать приоритет (низкий/средний/'
                  'высокий) и срок выполнения.',
              'Отметьте галочку слева, чтобы отметить задачу выполненной.',
              'Вкладки-фильтры сверху: «Все», «Активные», «Выполненные».',
            ],
          ),
          _HelpSection(
            icon: Icons.help_outline,
            title: 'Вопросы',
            items: [
              'Создайте вопрос и, при необходимости, сразу впишите ответ — '
                  'или вернитесь и добавьте его позже, отредактировав вопрос.',
              'Фильтр сверху разделяет вопросы «Без ответа» и «С ответом».',
            ],
          ),
          _HelpSection(
            icon: Icons.sync,
            title: 'Синхронизация между устройствами',
            items: [
              'Все данные хранятся на сервере и доступны с любого устройства, '
                  'где вы вошли в свой аккаунт.',
              'Приложение подгружает список один раз при открытии экрана — '
                  'если добавили запись с другого устройства, нажмите значок '
                  'обновления в верхней панели (или потяните список вниз).',
            ],
          ),
          _HelpSection(
            icon: Icons.person_outline,
            title: 'Профиль',
            items: [
              'На вкладке «Профиль» — имя, аватар и статистика (сколько '
                  'заметок/задач/вопросов создано).',
              '«Установить на телефон» — QR-код и ссылка для установки '
                  'приложения на другое Android-устройство.',
            ],
          ),
          _HelpSection(
            icon: Icons.security,
            title: 'Безопасность',
            items: [
              'Двухфакторная аутентификация (2FA) — Настройки → Безопасность.',
              'Вход по отпечатку пальца доступен на Android, если у '
                  'устройства есть датчик биометрии — включается там же.',
            ],
          ),
          _HelpSection(
            icon: Icons.system_update_outlined,
            title: 'Обновления (Android)',
            items: [
              'При запуске приложение само проверяет, есть ли новая версия, '
                  'и предлагает установить её поверх текущей — данные и '
                  'сессия сохраняются, переустанавливать всё приложение не '
                  'нужно.',
              'Проверить вручную можно в Настройках → О приложении → '
                  '«Проверить обновления».',
            ],
          ),
        ],
      ),
    );
  }
}

class _HelpSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> items;

  const _HelpSection({
    required this.icon,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ExpansionTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        children: items
            .map(
              (text) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  '),
                    Expanded(child: Text(text)),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
