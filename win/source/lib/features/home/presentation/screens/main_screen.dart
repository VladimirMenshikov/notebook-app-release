import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notebook_app/core/storage/local_storage.dart';
import 'package:notebook_app/core/update/update_prompt.dart';
import 'package:notebook_app/features/groups/presentation/providers/groups_providers.dart';
import 'package:notebook_app/features/notes/presentation/providers/notes_providers.dart';
import 'package:notebook_app/features/notes/presentation/screens/notes_list_screen.dart';
import 'package:notebook_app/features/tasks/presentation/providers/tasks_providers.dart';
import 'package:notebook_app/features/tasks/presentation/screens/tasks_list_screen.dart';
import 'package:notebook_app/features/questions/presentation/providers/questions_providers.dart';
import 'package:notebook_app/features/questions/presentation/screens/questions_list_screen.dart';
import 'package:notebook_app/features/wishes/presentation/providers/wishes_providers.dart';
import 'package:notebook_app/features/wishes/presentation/screens/wishes_list_screen.dart';
import 'package:notebook_app/features/profile/presentation/screens/profile_screen.dart';

final activeTabProvider = StateProvider<int>((ref) => 0);

const _tabKeys = ['notes', 'tasks', 'questions', 'wishes', 'profile'];

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkForUpdateAndPrompt(context, ref, silent: true);
      // Загружаем группы и восстанавливаем контекст.
      ref.read(groupsProvider.notifier).load();
    });
  }

  /// Перезагрузить содержимое выбранной вкладки (авто-обновление при входе).
  void _reloadTab(int index) {
    switch (_tabKeys[index]) {
      case 'notes':
        ref.read(notesProvider.notifier).loadNotes(refresh: true);
        break;
      case 'tasks':
        ref.read(tasksProvider.notifier).loadTasks(refresh: true);
        break;
      case 'questions':
        ref.read(questionsProvider.notifier).loadQuestions(refresh: true);
        break;
      case 'wishes':
        ref.read(wishesProvider.notifier).loadWishes(refresh: true);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeTab = ref.watch(activeTabProvider);

    return Scaffold(
      body: IndexedStack(
        index: activeTab,
        children: const [
          NotesTab(),
          TasksTab(),
          QuestionsTab(),
          WishesTab(),
          ProfileTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: activeTab,
        onDestinationSelected: (index) async {
          ref.read(activeTabProvider.notifier).state = index;
          _reloadTab(index);
          await LocalStorage().setLastActiveTab(_tabKeys[index]);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.note_outlined),
            selectedIcon: Icon(Icons.note),
            label: 'Заметки',
          ),
          NavigationDestination(
            icon: Icon(Icons.task_outlined),
            selectedIcon: Icon(Icons.task),
            label: 'Задачи',
          ),
          NavigationDestination(
            icon: Icon(Icons.help_outline),
            selectedIcon: Icon(Icons.help),
            label: 'Вопросы',
          ),
          NavigationDestination(
            icon: Icon(Icons.card_giftcard_outlined),
            selectedIcon: Icon(Icons.card_giftcard),
            label: 'Желания',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }
}

class NotesTab extends StatelessWidget {
  const NotesTab({super.key});

  @override
  Widget build(BuildContext context) => const NotesListScreen();
}

class TasksTab extends StatelessWidget {
  const TasksTab({super.key});

  @override
  Widget build(BuildContext context) => const TasksListScreen();
}

class QuestionsTab extends StatelessWidget {
  const QuestionsTab({super.key});

  @override
  Widget build(BuildContext context) => const QuestionsListScreen();
}

class WishesTab extends StatelessWidget {
  const WishesTab({super.key});

  @override
  Widget build(BuildContext context) => const WishesListScreen();
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) => const ProfileScreen();
}
