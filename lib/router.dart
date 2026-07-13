import 'package:flutter/material.dart';

/// AppRouter is a class that manages the routing of the application.
/// It is responsible for generating the routes and handling navigation between different screens.
///
class AppRouter {
  AppRouter();

  /// Generates a route based on the given [RouteSettings].
  /// This method is called when a named route is pushed onto the navigator.
  final List<String> _routeHistory = <String>[];

  /// Generates a route based on the given [RouteSettings].
  /// This method is called when a named route is pushed onto the navigator.
  Route<dynamic> onGenerateRoute(RouteSettings settings) {
    Widget? page;
    const Duration transitionDuration = Duration(milliseconds: 30);
    const Duration reverseTransitionDuration = Duration(milliseconds: 30);

    switch (settings.name) {}

    /// Return PageRoute with Fade Transition for navigation
    /// and include route settings for history tracking
    return PageRouteBuilder<dynamic>(
      settings: settings, // add settings for route has name track history
      pageBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) => page!,
      transitionsBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) => FadeTransition(opacity: animation, child: child),
      transitionDuration: transitionDuration,
      reverseTransitionDuration: reverseTransitionDuration,
    );
  }

  // method สำหรับ handle pop
  /// เมื่อมีการ pop route จะลบ route นั้นออกจาก history
  void onRoutePop(String? routeName) {
    if (routeName != null && _routeHistory.isNotEmpty) {
      // ลบ route ที่ถูก pop ออกจาก history
      if (_routeHistory.last == routeName) {
        _routeHistory.removeLast();
      }
    }
  }

  /// เมื่อมีการ push route จะเพิ่ม route นั้นเข้าไปใน history
  void onRoutePush(String? routeName) {
    if (routeName != null) {
      // เช็คไม่ให้เพิ่ม route ซ้ำ (ถ้า route ล่าสุดเหมือนกับที่จะเพิ่ม)
      if (_routeHistory.isEmpty || _routeHistory.last != routeName) {
        _routeHistory.add(routeName);
      }
    }
  }

  // get List Route History
  // return List<String> of route history
  List<String> getRouteHistory() {
    // coreLog.debug(message: 'Route History: $_routeHistory');
    return List<String>.from(_routeHistory);
  }

  // get currentRoute
  // return current route name
  String? get currentRoute {
    if (_routeHistory.isNotEmpty) {
      return _routeHistory.last;
    }
    return null;
  }

  // get previous route
  // return previous route name
  String? get previousRoute {
    if (_routeHistory.length > 1) {
      return _routeHistory[_routeHistory.length - 2];
    }
    return null;
  }

  // clear route history
  // clear all route history
  void clearRouteHistory() {
    _routeHistory.clear();
    // coreLog.debug(message: 'Route History cleared');
  }
}
