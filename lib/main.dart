import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_theme.dart';
import 'notes_provider.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor:                   Colors.transparent,
    statusBarIconBrightness:          Brightness.light,
    systemNavigationBarColor:         AppColors.bg,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(
    ChangeNotifierProvider(
      create: (_) => NotesProvider(),
      child: const NotevoApp(),
    ),
  );
}

class NotevoApp extends StatelessWidget {
  const NotevoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData.dark();
    return MaterialApp(
      title: 'Notevo',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: base.colorScheme.copyWith(
          surface:   AppColors.bg,
          primary:   AppColors.colorDoing,
          secondary: AppColors.colorDone,
        ),
        textTheme: GoogleFonts.dmSansTextTheme(base.textTheme).apply(
          bodyColor:    AppColors.fg,
          displayColor: AppColors.fg,
        ),
        pageTransitionsTheme: PageTransitionsTheme(
          builders: const {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS:     ZoomPageTransitionsBuilder(),
            TargetPlatform.windows: ZoomPageTransitionsBuilder(),
          },
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
