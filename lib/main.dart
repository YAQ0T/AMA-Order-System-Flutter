import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'src/config/app_colors.dart';
import 'src/config/api_config.dart';
import 'src/screens/auth/login_page.dart';
import 'src/screens/auth/pending_page.dart';
import 'src/screens/auth/signup_page.dart';
import 'src/screens/dashboard/role_dashboard.dart';
import 'src/services/api_client.dart';
import 'src/state/auth_notifier.dart';
import 'src/state/order_notifier.dart';
import 'src/state/admin_notifier.dart';
import 'src/state/notification_notifier.dart';

void main() {
  // Only install permissive overrides for non-web builds; HttpClient is unsupported on web.
  if (!kIsWeb && ApiConfig.allowBadCertificates) {
    HttpOverrides.global = PermissiveHttpOverrides();
  }
  final apiClient = ApiClient();

  runApp(AMAOrderApp(apiClient: apiClient));
}

class AMAOrderApp extends StatelessWidget {
  const AMAOrderApp({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthNotifier>(
          create: (_) => AuthNotifier(apiClient),
        ),
        ChangeNotifierProxyProvider<AuthNotifier, OrderNotifier>(
          create: (_) => OrderNotifier(apiClient),
          update: (_, auth, orders) {
            final notifier = orders ?? OrderNotifier(apiClient);
            notifier.handleAuthChanged(auth);
            return notifier;
          },
        ),
        ChangeNotifierProxyProvider<AuthNotifier, AdminNotifier>(
          create: (_) => AdminNotifier(apiClient),
          update: (_, auth, admin) {
            final notifier = admin ?? AdminNotifier(apiClient);
            if (auth.isAuthenticated && auth.user?.role == 'admin') {
              notifier.refreshAll();
            } else {
              notifier.reset();
            }
            return notifier;
          },
        ),
        ChangeNotifierProxyProvider<AuthNotifier, NotificationNotifier>(
          create: (_) => NotificationNotifier(apiClient),
          update: (_, auth, notif) {
            final notifier = notif ?? NotificationNotifier(apiClient);
            return notifier;
          },
        ),
      ],
      child: Consumer<AuthNotifier>(
        builder: (context, auth, _) {
          final lightTheme = _buildTheme(Brightness.light);
          final darkTheme = _buildTheme(Brightness.dark);
          final themeMode = auth.prefersDark ? ThemeMode.dark : ThemeMode.light;

          return MaterialApp(
            title: 'AMA Order System',
            debugShowCheckedModeBanner: false,
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: themeMode,
            home: _homeFor(auth),
            routes: {
              SignupPage.routeName: (_) => const SignupPage(),
            },
          );
        },
      ),
    );
  }

  Widget _homeFor(AuthNotifier auth) {
    if (auth.initializing) return const _SplashScreen();
    if (!auth.isAuthenticated) return const LoginPage();
    if (!auth.isApproved) return const PendingApprovalPage();
    return RoleDashboard(user: auth.user!);
  }

  TextTheme _boldTextTheme(TextTheme base) {
    TextStyle? bold(TextStyle? style) => style?.copyWith(fontWeight: FontWeight.w700);
    return base.copyWith(
      displayLarge: bold(base.displayLarge),
      displayMedium: bold(base.displayMedium),
      displaySmall: bold(base.displaySmall),
      headlineLarge: bold(base.headlineLarge),
      headlineMedium: bold(base.headlineMedium),
      headlineSmall: bold(base.headlineSmall),
      titleLarge: bold(base.titleLarge),
      titleMedium: bold(base.titleMedium),
      titleSmall: bold(base.titleSmall),
      bodyLarge: bold(base.bodyLarge),
      bodyMedium: bold(base.bodyMedium),
      bodySmall: bold(base.bodySmall),
      labelLarge: bold(base.labelLarge),
      labelMedium: bold(base.labelMedium),
      labelSmall: bold(base.labelSmall),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final seedColor = isDark ? AppColors.darkPrimary : const Color(0xFF2F7A72);
    final baseScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
    final surfaceBase = isDark ? AppColors.darkBackground : const Color(0xFFF4F6F5);
    final surfaceContainer = isDark ? AppColors.darkSurface : const Color(0xFFE7EFEE);
    final scheme = baseScheme.copyWith(
      primary: isDark ? AppColors.darkPrimary : baseScheme.primary,
      onPrimary: isDark ? AppColors.darkTextMain : baseScheme.onPrimary,
      primaryContainer: isDark ? AppColors.darkPrimary : baseScheme.primaryContainer,
      onPrimaryContainer: isDark ? AppColors.darkTextMain : baseScheme.onPrimaryContainer,
      secondary: isDark ? AppColors.darkAccent : baseScheme.secondary,
      onSecondary: isDark ? AppColors.darkTextMain : baseScheme.onSecondary,
      secondaryContainer: isDark ? AppColors.darkAccent : baseScheme.secondaryContainer,
      onSecondaryContainer: isDark ? AppColors.darkTextMain : baseScheme.onSecondaryContainer,
      tertiary: isDark ? AppColors.statusEnteredErp : baseScheme.tertiary,
      onTertiary: isDark ? AppColors.darkTextMain : baseScheme.onTertiary,
      tertiaryContainer: isDark
          ? AppColors.statusEnteredErp.withValues(alpha: 0.35)
          : baseScheme.tertiaryContainer,
      onTertiaryContainer: isDark ? AppColors.darkTextMain : baseScheme.onTertiaryContainer,
      surface: isDark ? AppColors.darkSurface : Colors.white,
      background: isDark ? AppColors.darkBackground : baseScheme.background,
      onBackground: isDark ? AppColors.darkTextMain : baseScheme.onBackground,
      onSurface: isDark ? AppColors.darkTextMain : baseScheme.onSurface,
      surfaceVariant: isDark ? AppColors.darkSurface : baseScheme.surfaceVariant,
      onSurfaceVariant: isDark ? AppColors.darkTextMuted : baseScheme.onSurfaceVariant,
      surfaceContainerHighest: surfaceContainer,
      surfaceContainerHigh: surfaceContainer,
      surfaceContainer: surfaceContainer,
      outline: isDark ? AppColors.darkTextMuted : baseScheme.outline,
      outlineVariant: isDark ? AppColors.darkGlassBorder : baseScheme.outlineVariant,
      error: isDark ? AppColors.statusError : baseScheme.error,
      onError: isDark ? AppColors.darkTextMain : baseScheme.onError,
      errorContainer:
          isDark ? AppColors.statusError.withValues(alpha: 0.2) : baseScheme.errorContainer,
      onErrorContainer: isDark ? AppColors.darkTextMain : baseScheme.onErrorContainer,
      surfaceTint: isDark ? AppColors.darkPrimary : baseScheme.surfaceTint,
    );

    final boldTextTheme =
        _boldTextTheme(ThemeData(colorScheme: scheme, useMaterial3: true).textTheme);

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      textTheme: boldTextTheme,
      primaryTextTheme: boldTextTheme.apply(
        bodyColor: scheme.onPrimary,
        displayColor: scheme.onPrimary,
      ),
      scaffoldBackgroundColor: surfaceBase,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        titleTextStyle: boldTextTheme.titleLarge?.copyWith(color: scheme.onSurface),
        toolbarTextStyle: boldTextTheme.bodyMedium?.copyWith(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 1.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkInputFill : scheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        selectedColor: scheme.primaryContainer,
        disabledColor: scheme.surfaceContainerHighest,
        labelStyle: boldTextTheme.labelMedium?.copyWith(color: scheme.onSurface),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          textStyle: boldTextTheme.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.secondary,
          foregroundColor: scheme.onSecondary,
          textStyle: boldTextTheme.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: boldTextTheme.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      dividerColor: scheme.outlineVariant,
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
