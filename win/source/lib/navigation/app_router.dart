import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_email_screen.dart';
import '../features/auth/presentation/screens/verify_email_screen.dart';
import '../features/auth/presentation/screens/profile_setup_screen.dart';
import '../features/home/presentation/screens/main_screen.dart';
import '../features/home/presentation/screens/download_screen.dart';
import '../features/notes/presentation/screens/note_editor_screen.dart';
import '../features/groups/presentation/screens/group_management_screen.dart';
import '../features/groups/presentation/screens/my_invitations_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/profile/presentation/screens/settings_screen.dart';
import '../features/profile/presentation/screens/help_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    routes: [
      // Auth routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register-email',
        name: 'register-email',
        builder: (context, state) => const RegisterEmailScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        name: 'verify-email',
        builder: (context, state) => const VerifyEmailScreen(),
      ),
      GoRoute(
        path: '/profile-setup',
        name: 'profile-setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      
      // Main shell with navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => child,
        routes: [
          // Main tabs
          GoRoute(
            path: '/main',
            name: 'main',
            builder: (context, state) => const MainScreen(),
          ),
          
          // Notes
          GoRoute(
            path: '/notes',
            name: 'notes',
            builder: (context, state) => const MainScreen(),
          ),
          GoRoute(
            path: '/note/:id',
            name: 'note-editor',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return NoteEditorScreen(noteId: id);
            },
          ),
          
          // Tasks
          GoRoute(
            path: '/tasks',
            name: 'tasks',
            builder: (context, state) => const MainScreen(),
          ),
          
          // Questions
          GoRoute(
            path: '/questions',
            name: 'questions',
            builder: (context, state) => const MainScreen(),
          ),

          // Wishes
          GoRoute(
            path: '/wishes',
            name: 'wishes',
            builder: (context, state) => const MainScreen(),
          ),

          // Groups
          GoRoute(
            path: '/groups/:id',
            name: 'group-management',
            builder: (context, state) => GroupManagementScreen(
              groupId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/invitations',
            name: 'invitations',
            builder: (context, state) => const MyInvitationsScreen(),
          ),

          // Profile
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          
          // Settings
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          
          // Download
          GoRoute(
            path: '/download',
            name: 'download',
            builder: (context, state) => const DownloadScreen(),
          ),

          // Help / usage guide
          GoRoute(
            path: '/help',
            name: 'help',
            builder: (context, state) => const HelpScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Страница не найдена: ${state.error}'),
      ),
    ),
  );
}
