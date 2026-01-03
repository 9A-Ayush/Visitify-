import 'package:shared_preferences/shared_preferences.dart';

class ScreenStateService {
  static const String _lastScreenKey = 'last_screen';
  static const String _lastScreenArgsKey = 'last_screen_args';
  static const String _userRoleKey = 'user_role';
  static const String _userStatusKey = 'user_status';

  // Save the current screen route with user context
  static Future<void> saveLastScreen(String route, {
    Map<String, dynamic>? arguments,
    String? userRole,
    String? userStatus,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastScreenKey, route);
      
      if (arguments != null) {
        // Convert arguments to a simple string format for storage
        final argsString = arguments.entries
            .map((e) => '${e.key}:${e.value}')
            .join(',');
        await prefs.setString(_lastScreenArgsKey, argsString);
      } else {
        await prefs.remove(_lastScreenArgsKey);
      }
      
      // Save user context for validation
      if (userRole != null) {
        await prefs.setString(_userRoleKey, userRole);
      }
      if (userStatus != null) {
        await prefs.setString(_userStatusKey, userStatus);
      }
      
      print('ScreenStateService: Saved screen: $route, Role: $userRole, Status: $userStatus');
    } catch (e) {
      print('ScreenStateService: Error saving screen state: $e');
    }
  }

  // Get the last saved screen route
  static Future<String?> getLastScreen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final screen = prefs.getString(_lastScreenKey);
      print('ScreenStateService: Retrieved screen: $screen');
      return screen;
    } catch (e) {
      print('ScreenStateService: Error getting last screen: $e');
      return null;
    }
  }

  // Get the last saved screen arguments
  static Future<Map<String, dynamic>?> getLastScreenArguments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final argsString = prefs.getString(_lastScreenArgsKey);
      
      if (argsString == null || argsString.isEmpty) return null;
      
      final Map<String, dynamic> args = {};
      final pairs = argsString.split(',');
      for (final pair in pairs) {
        final keyValue = pair.split(':');
        if (keyValue.length == 2) {
          args[keyValue[0]] = keyValue[1];
        }
      }
      return args;
    } catch (e) {
      print('ScreenStateService: Error getting screen arguments: $e');
      return null;
    }
  }

  // Get saved user context
  static Future<Map<String, String?>> getSavedUserContext() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'role': prefs.getString(_userRoleKey),
        'status': prefs.getString(_userStatusKey),
      };
    } catch (e) {
      print('ScreenStateService: Error getting user context: $e');
      return {'role': null, 'status': null};
    }
  }

  // Clear the saved screen state
  static Future<void> clearLastScreen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastScreenKey);
      await prefs.remove(_lastScreenArgsKey);
      await prefs.remove(_userRoleKey);
      await prefs.remove(_userStatusKey);
      print('ScreenStateService: Cleared all screen state');
    } catch (e) {
      print('ScreenStateService: Error clearing screen state: $e');
    }
  }

  // Check if a route is a valid screen to restore to
  static bool isValidRestoreRoute(String route, {String? userRole, String? userStatus}) {
    // Don't restore to auth screens, splash, or onboarding
    const invalidRoutes = [
      '/',
      '/onboarding',
      '/welcome',
      '/login',
      '/register',
      '/login_phone',
      '/admin_invite',
      '/profile_completion',
      '/forgot_password',
      '/add_home',
      '/awaiting_approval',
    ];
    
    if (invalidRoutes.contains(route)) {
      print('ScreenStateService: Route $route is in invalid routes list');
      return false;
    }
    
    // Validate route matches user role
    if (userRole != null) {
      if (userRole == 'admin' && !route.startsWith('/admin')) {
        print('ScreenStateService: Admin user cannot access non-admin route: $route');
        return false;
      }
      if (userRole == 'guard' && !route.startsWith('/guard')) {
        print('ScreenStateService: Guard user cannot access non-guard route: $route');
        return false;
      }
      if (userRole == 'resident' && !route.startsWith('/resident')) {
        print('ScreenStateService: Resident user cannot access non-resident route: $route');
        return false;
      }
    }
    
    print('ScreenStateService: Route $route is valid for restore');
    return true;
  }

  // Get the appropriate home screen for a user role
  static String getHomeScreenForRole(String role) {
    switch (role) {
      case 'admin':
        return '/admin_home';
      case 'guard':
        return '/guard_home';
      case 'resident':
        return '/resident_home';
      default:
        return '/welcome';
    }
  }
}