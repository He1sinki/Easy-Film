import 'package:easy_film/app/router/app_router.dart';
import 'package:easy_film/app/theme/app_theme.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EasyFilmApp());
}

class EasyFilmApp extends StatelessWidget {
  const EasyFilmApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = AppRouter.build();
    return MaterialApp.router(
      title: 'Easy Film',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
    );
  }
}
