import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'providers/news_provider.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_signup_screen.dart';
import 'theme/app_theme.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('[DotEnv] Notice: .env file could not be loaded ($e). Using default AppConfig.');
  }

  final prefs = await SharedPreferences.getInstance();
  final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

  final authService = AuthService();
  await authService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NewsProvider()),
        ChangeNotifierProvider.value(value: authService),
      ],
      child: PowerNewsApp(showOnboarding: !hasSeenOnboarding),
    ),
  );
}

class PowerNewsApp extends StatelessWidget {
  final bool showOnboarding;

  const PowerNewsApp({
    super.key,
    this.showOnboarding = false,
  });

  @override
  Widget build(BuildContext context) {
    final newsProvider = context.watch<NewsProvider>();
    final auth = context.watch<AuthService>();

    Widget initialScreen;
    if (showOnboarding) {
      initialScreen = const OnboardingScreen();
    } else if (!auth.isAuthenticated && !auth.isGuest) {
      initialScreen = const LoginSignUpScreen();
    } else {
      initialScreen = const HomeScreen();
    }

    return MaterialApp(
      title: 'PowerNews',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: newsProvider.themeMode,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.of(context).textScaler.clamp(
              minScaleFactor: 0.9,
              maxScaleFactor: 1.15,
            ),
          ),
          child: child!,
        );
      },
      home: initialScreen,
    );
  }
}
