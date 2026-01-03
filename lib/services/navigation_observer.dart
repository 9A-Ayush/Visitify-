import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screen_state_service.dart';
import 'auth_service.dart';

class ScreenStateNavigationObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _saveCurrentRoute(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _saveCurrentRoute(newRoute);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      _saveCurrentRoute(previousRoute);
    }
  }

  void _saveCurrentRoute(Route<dynamic> route) async {
    if (route.settings.name != null) {
      final routeName = route.settings.name!;
      
      // Get current user context
      String? userRole;
      String? userStatus;
      
      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          final appUser = await AuthService().getAppUser();
          userRole = appUser?.role;
          userStatus = appUser?.status;
        }
      } catch (e) {
        print('NavigationObserver: Error getting user context: $e');
      }
      
      // Only save valid routes that we want to restore to
      if (ScreenStateService.isValidRestoreRoute(routeName, userRole: userRole, userStatus: userStatus)) {
        final arguments = route.settings.arguments;
        Map<String, dynamic>? argsMap;
        
        if (arguments is Map<String, dynamic>) {
          argsMap = arguments;
        }
        
        ScreenStateService.saveLastScreen(
          routeName, 
          arguments: argsMap,
          userRole: userRole,
          userStatus: userStatus,
        );
      }
    }
  }
}