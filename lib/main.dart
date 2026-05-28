import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'state/detector_state.dart';
import 'ui/screens/dashboard_screen.dart';

void main() {
  // Ensure Flutter engine is initialized before binding services
  WidgetsFlutterBinding.ensureInitialized();

  // Create single instance of detector state to persist across hot restarts
  final detectorState = DetectorState();

  // Configure high-tech fullscreen status and navigation bar styling
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF07080D),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Lock mobile orientation in portrait mode for scanning consistency
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(MyApp(state: detectorState));
  });
}

class MyApp extends StatefulWidget {
  final DetectorState state;

  const MyApp({
    super.key,
    required this.state,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void dispose() {
    // Correctly release state and stream listeners when app is terminated
    widget.state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EMF Scanner PRO',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF07080D),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00F2FE),
          secondary: Color(0xFF00FF87),
          surface: Color(0xFF0F1019),
          error: Color(0xFFFF0055),
        ),
        useMaterial3: true,
      ),
      home: DashboardScreen(state: widget.state),
    );
  }
}
