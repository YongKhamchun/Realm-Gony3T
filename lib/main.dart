import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:realm_gony3t/realm_gony3T.dart';
import 'package:realm_gony3t/router.dart';

void main() {
  _installMacOsKeyboardAssertionWorkaround();
  runApp(const ProviderScope(child: MyApp()));
}

void _installMacOsKeyboardAssertionWorkaround() {
  if (!kDebugMode || defaultTargetPlatform != TargetPlatform.macOS) {
    return;
  }

  final FlutterExceptionHandler? previous = FlutterError.onError;

  FlutterError.onError = (FlutterErrorDetails details) {
    final String message = details.exceptionAsString();

    if (message.contains('A KeyDownEvent is dispatched') &&
        message.contains('physical key is already pressed')) {
      debugPrint('[Keyboard] Ignored known macOS key sync assertion: $message');
      return;
    }

    if (previous != null) {
      previous(details);
      return;
    }

    FlutterError.presentError(details);
  };
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Flutter Demo',
      themeMode: themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      initialRoute: HomePage.routeName,
      onGenerateRoute: appRouter.onGenerateRoute,
    );
  }
}
