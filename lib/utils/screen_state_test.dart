// Simple test utility to verify screen state service functionality
import '../services/screen_state_service.dart';

class ScreenStateTest {
  static Future<void> testScreenStatePersistence() async {
    print('Testing Screen State Service...');
    
    // Test saving and retrieving a screen
    await ScreenStateService.saveLastScreen('/admin_home');
    final savedScreen = await ScreenStateService.getLastScreen();
    print('Saved screen: /admin_home, Retrieved: $savedScreen');
    
    // Test saving with arguments
    await ScreenStateService.saveLastScreen('/profile', arguments: {'userId': '123'});
    final savedScreenWithArgs = await ScreenStateService.getLastScreen();
    final savedArgs = await ScreenStateService.getLastScreenArguments();
    print('Saved screen with args: /profile, Retrieved: $savedScreenWithArgs, Args: $savedArgs');
    
    // Test route validation
    final isValidHome = ScreenStateService.isValidRestoreRoute('/admin_home');
    final isValidLogin = ScreenStateService.isValidRestoreRoute('/login');
    print('Is /admin_home valid for restore: $isValidHome');
    print('Is /login valid for restore: $isValidLogin');
    
    // Test home screen for role
    final adminHome = ScreenStateService.getHomeScreenForRole('admin');
    final residentHome = ScreenStateService.getHomeScreenForRole('resident');
    print('Admin home screen: $adminHome');
    print('Resident home screen: $residentHome');
    
    // Clear state
    await ScreenStateService.clearLastScreen();
    final clearedScreen = await ScreenStateService.getLastScreen();
    print('After clearing, screen: $clearedScreen');
    
    print('Screen State Service test completed!');
  }
}