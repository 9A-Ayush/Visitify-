import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'route_helper.dart';
import 'services/auth_provider.dart';
import 'services/navigation_observer.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Visitify',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routes: RouteHelper.getRoutes(context),
      initialRoute: '/',
      navigatorObservers: [ScreenStateNavigationObserver()],
    );
  }
}
