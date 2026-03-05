import 'package:easy_film/features/filebrowser/presentation/filebrowser_screen.dart';
import 'package:easy_film/features/qbittorrent/presentation/qbittorrent_screen.dart';
import 'package:easy_film/features/settings/presentation/settings_screen.dart';
import 'package:easy_film/features/ygg/presentation/ygg_search_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');
final _fbBranchKey = GlobalKey<NavigatorState>(debugLabel: 'filebrowser');
final _qbBranchKey = GlobalKey<NavigatorState>(debugLabel: 'qbittorrent');
final _yggBranchKey = GlobalKey<NavigatorState>(debugLabel: 'ygg');

class AppRouter {
  static GoRouter build() {
    return GoRouter(
      initialLocation: '/filebrowser',
      routes: [
        GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
        StatefulShellRoute.indexedStack(
          parentNavigatorKey: null,
          builder: (context, state, navigationShell) =>
              _Shell(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(
              navigatorKey: _fbBranchKey,
              routes: [
                GoRoute(
                  path: '/filebrowser',
                  builder: (_, __) => const FilebrowserScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              navigatorKey: _qbBranchKey,
              routes: [
                GoRoute(
                  path: '/qbittorrent',
                  builder: (_, __) => const QbittorrentScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              navigatorKey: _yggBranchKey,
              routes: [
                GoRoute(
                  path: '/ygg',
                  builder: (_, __) => const YggSearchScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder_rounded),
            label: 'Films',
          ),
          NavigationDestination(
            icon: Icon(Icons.downloading_outlined),
            selectedIcon: Icon(Icons.downloading_rounded),
            label: 'Torrents',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search_rounded),
            label: 'Recherche',
          ),
        ],
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}
