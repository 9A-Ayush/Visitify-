import 'package:flutter/material.dart';
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
    // '/admin_user_management': (context) => const AdminUserManagementScreen(),
    '/admin_announcements': (context) => const AdminAnnouncementsScreen(),
    '/admin_complaints': (context) => const AdminComplaintsScreen(),
    '/admin_visitor_management':
        (context) => const AdminUserManagementScreen(),
    '/guard_visitor_log': (context) => const GuardVisitorLogScreen(),
    '/guard_preapproved_visitors':
        (context) => const GuardPreapprovedVisitorsScreen(),
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

  static void routeUser(
    BuildContext context,
    String role,
    bool profileComplete, {
    String? status,
  }) {
    // If no role is provided, user is not properly authenticated - go to login
    if (role.isEmpty) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    // Handle resident-specific routing
    if (role == 'resident') {
      if (!profileComplete) {
        // Resident needs to add home details
        Navigator.pushReplacementNamed(context, '/add_home');
        return;
      } else if (status == 'pending') {
        // Resident is waiting for admin approval
        Navigator.pushReplacementNamed(context, '/awaiting_approval');
        return;
      } else if (status == 'approved') {
        // Resident is approved - go to home
        Navigator.pushReplacementNamed(context, '/resident_home');
        return;
      } else {
        // Resident status is not set properly - go to awaiting approval
        Navigator.pushReplacementNamed(context, '/awaiting_approval');
        return;
      }
    }

    // Handle other roles (admin, guard)
    if (!profileComplete) {
      // Profile not complete - go to profile completion screen
      Navigator.pushReplacementNamed(
        context,
        '/profile_completion',
        arguments: {'role': role},
      );
      return;
    }

    // Profile is complete - route to appropriate home screen
    switch (role) {
      case 'admin':
        Navigator.pushReplacementNamed(context, '/admin_home');
        break;
      case 'guard':
        Navigator.pushReplacementNamed(context, '/guard_home');
        break;
      default:
        // Unknown role - go to login
        Navigator.pushReplacementNamed(context, '/login');
    }
  }
}
