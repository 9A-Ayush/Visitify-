import 'package:flutter/material.dart';
import 'services/screen_state_service.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/login_phone_screen.dart';
import 'screens/auth/admin_invite_screen.dart';
import 'screens/auth/profile_completion_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/resident/resident_home_screen.dart';
import 'screens/admin/admin_home_screen.dart';
import 'screens/guard/guard_home_screen.dart';
import 'screens/resident/add_home_screen.dart';
import 'screens/resident/awaiting_approval_screen.dart';
import 'screens/admin/admin_pending_requests_screen.dart';
import 'screens/resident/visitor_management_screen.dart';
import 'screens/resident/complaints_screen.dart';
import 'screens/resident/amenities_screen.dart';
import 'screens/resident/payments_screen.dart';
import 'screens/resident/chat_screen.dart';
import 'screens/resident/announcements_screen.dart';
import 'screens/admin/admin_user_management_screen.dart';
import 'screens/admin/admin_visitor_management_screen.dart';
import 'screens/admin/admin_announcements_screen.dart';
import 'screens/admin/admin_complaints_screen.dart';

import 'screens/guard/guard_visitor_log_screen.dart';
import 'screens/guard/guard_preapproved_visitors_screen.dart';
import 'screens/guard/guard_all_visitors_screen.dart';
import 'screens/guard/guard_qr_scanner_screen.dart';

import 'screens/common/profile_edit_screen.dart';
import 'screens/common/profile_screen.dart';
import 'screens/admin/admin_notifications_screen.dart';
import 'screens/admin/admin_analytics_screen.dart';
import 'screens/common/contact_selection_screen.dart';
import 'screens/common/chat_list_screen.dart';
import 'screens/common/simple_chat_screen.dart';
import 'screens/resident/qr_invitation_screen.dart';
import 'screens/resident/qr_invitations_list_screen.dart';
import 'screens/resident/quick_qr_generator_screen.dart';
import 'screens/visitor/qr_scanner_screen.dart';
import 'screens/visitor/visitor_entry_screen.dart';
import 'screens/common/notifications_screen.dart';



class RouteHelper {
  static Map<String, WidgetBuilder> getRoutes(BuildContext context) => {
    '/': (context) => const SplashScreen(),
    '/onboarding': (context) => const OnboardingScreen(),
    '/welcome': (context) => const WelcomeScreen(),
    '/login': (context) => const LoginScreen(),
    '/register': (context) => const RegisterScreen(),
    '/login_phone': (context) => const LoginPhoneScreen(),
    '/admin_invite': (context) => const AdminInviteScreen(),
    '/profile_completion':
        (context) => const ProfileCompletionScreen(role: 'resident'),
    '/forgot_password': (context) => const ForgotPasswordScreen(),
    '/resident_home': (context) => const ResidentHomeScreen(),
    '/admin_home': (context) => const AdminHomeScreen(),
    '/guard_home': (context) => const GuardHomeScreen(),
    '/add_home': (context) => const AddHomeScreen(),
    '/awaiting_approval': (context) => const AwaitingApprovalScreen(),
    '/admin_pending_requests': (context) => const AdminPendingRequestsScreen(),
    '/visitor_management': (context) => const VisitorManagementScreen(),
    '/complaints': (context) => const ComplaintsScreen(),
    '/amenities': (context) => const AmenitiesScreen(),
    '/payments': (context) => const PaymentsScreen(),
    '/chat': (context) => const ChatScreen(),
    '/announcements': (context) => const AnnouncementsScreen(),
    '/admin_user_management': (context) => const AdminUserManagementScreen(),
    '/admin_announcements': (context) => const AdminAnnouncementsScreen(),
    '/admin_complaints': (context) => const AdminComplaintsScreen(),
    '/admin_visitor_management': (context) => const AdminVisitorManagementScreen(),
    '/guard_visitor_log': (context) => const GuardVisitorLogScreen(),
    '/guard_preapproved_visitors': (context) => const GuardPreapprovedVisitorsScreen(),
    '/guard_chat': (context) => const ChatScreen(),
    '/guard_all_visitors': (context) => const GuardAllVisitorsScreen(),
    '/guard_qr_scanner': (context) => const GuardQRScannerScreen(),

    '/profile': (context) => const ProfileScreen(),
    '/profile_edit': (context) => const ProfileEditScreen(),

    '/admin_notifications': (context) => const AdminNotificationsScreen(),
    '/admin_analytics': (context) => const AdminAnalyticsScreen(),
    '/contact_selection': (context) => const ContactSelectionScreen(),
    '/chat_list': (context) => const ChatListScreen(),
    '/simple_chat': (context) => const SimpleChatScreen(),
    '/qr_invitation': (context) => const QRInvitationScreen(),
    '/qr_invitations_list': (context) => const QRInvitationsListScreen(),
    '/quick_qr_generator': (context) => const QuickQRGeneratorScreen(),
    '/qr_scanner': (context) => const QRScannerScreen(),
    '/visitor_entry': (context) => const VisitorEntryScreen(),
    '/notifications': (context) => const NotificationsScreen(),

  };

  static Future<void> routeUser(
    BuildContext context,
    String role,
    bool profileComplete, {
    String? status,
  }) async {
    print('RouteHelper: routeUser called - Role: $role, ProfileComplete: $profileComplete, Status: $status');
    
    // If no role is provided, user is not properly authenticated - go to login
    if (role.isEmpty) {
      print('RouteHelper: No role provided, going to login');
      await ScreenStateService.clearLastScreen();
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    // Handle resident-specific routing
    if (role == 'resident') {
      if (!profileComplete) {
        print('RouteHelper: Resident profile incomplete, going to add_home');
        await ScreenStateService.clearLastScreen();
        // Resident needs to add home details
        Navigator.pushReplacementNamed(context, '/add_home');
        return;
      } else if (status == 'pending') {
        print('RouteHelper: Resident status pending, going to awaiting_approval');
        await ScreenStateService.clearLastScreen();
        // Resident is waiting for admin approval
        Navigator.pushReplacementNamed(context, '/awaiting_approval');
        return;
      } else if (status != 'approved') {
        print('RouteHelper: Resident status unclear ($status), going to awaiting_approval');
        await ScreenStateService.clearLastScreen();
        // Resident status is not set properly - go to awaiting approval
        Navigator.pushReplacementNamed(context, '/awaiting_approval');
        return;
      }
    }

    // Handle other roles (admin, guard)
    if (!profileComplete) {
      print('RouteHelper: Profile incomplete for role $role, going to profile_completion');
      await ScreenStateService.clearLastScreen();
      // Profile not complete - go to profile completion screen
      Navigator.pushReplacementNamed(
        context,
        '/profile_completion',
        arguments: {'role': role},
      );
      return;
    }

    // User is properly authenticated and has complete profile
    print('RouteHelper: User is properly authenticated, checking for last screen...');
    
    // Try to restore their last screen
    final lastScreen = await ScreenStateService.getLastScreen();
    final lastScreenArgs = await ScreenStateService.getLastScreenArguments();
    final savedUserContext = await ScreenStateService.getSavedUserContext();

    print('RouteHelper: Last screen: $lastScreen, Args: $lastScreenArgs');
    print('RouteHelper: Saved user context: $savedUserContext');
    print('RouteHelper: Current user - Role: $role, Status: $status');

    // Validate that saved context matches current user
    bool contextMatches = savedUserContext['role'] == role && 
                         savedUserContext['status'] == status;
    
    if (lastScreen != null && 
        contextMatches && 
        ScreenStateService.isValidRestoreRoute(lastScreen, userRole: role, userStatus: status)) {
      print('RouteHelper: Restoring to last screen: $lastScreen');
      // Restore to last screen
      if (lastScreenArgs != null) {
        Navigator.pushReplacementNamed(context, lastScreen, arguments: lastScreenArgs);
      } else {
        Navigator.pushReplacementNamed(context, lastScreen);
      }
      return;
    }

    // No valid last screen or context mismatch, go to appropriate home screen
    print('RouteHelper: Going to home screen for role: $role (Context match: $contextMatches)');
    switch (role) {
      case 'admin':
        print('RouteHelper: Going to admin_home');
        Navigator.pushReplacementNamed(context, '/admin_home');
        break;
      case 'guard':
        print('RouteHelper: Going to guard_home');
        Navigator.pushReplacementNamed(context, '/guard_home');
        break;
      case 'resident':
        print('RouteHelper: Going to resident_home');
        Navigator.pushReplacementNamed(context, '/resident_home');
        break;
      default:
        print('RouteHelper: Unknown role ($role), going to login');
        await ScreenStateService.clearLastScreen();
        // Unknown role - go to login
        Navigator.pushReplacementNamed(context, '/login');
    }
  }
}
