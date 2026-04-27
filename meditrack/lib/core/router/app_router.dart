import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/local/app_database.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/logs/screens/intake_log_screen.dart';
import '../../features/medications/screens/medication_form_screen.dart';
import '../../features/medications/screens/medications_screen.dart';
import '../../features/reminders/screens/reminders_screen.dart';
import '../../features/shell/screens/shell_screen.dart';
import '../../features/profile/screens/profile_screen.dart';

class AppRouter {
  final AuthProvider authProvider;

  AppRouter(this.authProvider);

  late final router = GoRouter(
    initialLocation: '/home',
    refreshListenable: authProvider,
    redirect: (BuildContext context, GoRouterState state) {
      final isLoggedIn = authProvider.isLoggedIn;
      final isOnAuthScreen =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isLoggedIn && !isOnAuthScreen) return '/login';
      if (isLoggedIn && isOnAuthScreen) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ShellScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (_, __) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/medications',
                builder: (_, __) => const MedicationsScreen(),
                routes: [
                  GoRoute(
                    path: 'add',
                    builder: (_, __) => const MedicationFormScreen(),
                  ),
                  GoRoute(
                    path: 'edit',
                    builder: (_, state) => MedicationFormScreen(
                      medication: state.extra as Medication?,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reminders',
                builder: (_, __) => const RemindersScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/logs',
                builder: (_, __) => const IntakeLogScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, __) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
