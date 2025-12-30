import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'firebase_options.dart';
import 'theme/admin_theme.dart';
import 'providers/admin_auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';

// Global navigator key for navigation from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    rethrow;
  }

  // Initialize admin auth provider
  if (Firebase.apps.isNotEmpty) {
    adminAuthProvider.initialize();
  }

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AdminTheme.backgroundPrimary,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const StrameAdminApp());
}

class StrameAdminApp extends StatelessWidget {
  const StrameAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider.value(value: adminAuthProvider)],
      child: MaterialApp(
        title: 'Strame Admin Panel',
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        theme: AdminTheme.darkTheme,

        // Responsive framework
        builder:
            (context, child) => ResponsiveBreakpoints.builder(
              child: child!,
              breakpoints: [
                const Breakpoint(start: 0, end: 450, name: MOBILE),
                const Breakpoint(start: 451, end: 800, name: TABLET),
                const Breakpoint(start: 801, end: 1920, name: DESKTOP),
                const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
              ],
            ),

        home: const AuthWrapper(),

        // Routes
        routes: {
          '/login': (context) => const LoginScreen(),
          '/dashboard': (context) => const DashboardScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminAuthProvider>(
      builder: (context, authProvider, child) {
        print('🔄 [AuthWrapper] Building AuthWrapper...');
        print('📊 [AuthWrapper] isLoading: ${authProvider.isLoading}');
        print(
          '🔐 [AuthWrapper] isAuthenticated: ${authProvider.isAuthenticated}',
        );
        print(
          '👤 [AuthWrapper] currentAdmin: ${authProvider.currentAdmin?.email ?? "null"}',
        );
        print(
          '❌ [AuthWrapper] errorMessage: ${authProvider.errorMessage ?? "none"}',
        );

        // Show loading screen while initializing
        if (authProvider.isLoading) {
          print('⏳ [AuthWrapper] Showing LoadingScreen');
          return const LoadingScreen();
        }

        // Show dashboard if authenticated
        if (authProvider.isAuthenticated) {
          print('✅ [AuthWrapper] Showing DashboardScreen');
          return const DashboardScreen();
        }

        // Show login screen if not authenticated
        print('🔐 [AuthWrapper] Showing LoginScreen');
        return const LoginScreen();
      },
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AdminTheme.backgroundGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo or brand icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: AdminTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(AdminTheme.radiusXl),
                  boxShadow: AdminTheme.cardShadow,
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  size: 60,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: AdminTheme.spacingXl),

              // App title
              Text(
                'Strame Admin Panel',
                style: AdminTheme.headlineLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: AdminTheme.spacingSm),

              Text(
                'High-Level Dashboard',
                style: AdminTheme.bodyLarge.copyWith(
                  color: AdminTheme.textSecondary,
                ),
              ),

              const SizedBox(height: AdminTheme.spacingXl),

              // Loading indicator
              Container(
                width: 60,
                height: 60,
                padding: const EdgeInsets.all(AdminTheme.spacingMd),
                decoration: BoxDecoration(
                  color: AdminTheme.cardDark.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
                  border: Border.all(
                    color: AdminTheme.borderColor.withOpacity(0.3),
                  ),
                ),
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AdminTheme.primaryPurple,
                  ),
                  strokeWidth: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
