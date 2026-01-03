import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../services/communication_service.dart';
import '../screens/common/contact_selection_screen.dart';
import '../screens/common/chat_list_screen.dart';
import '../theme/app_theme.dart';

class CommunicationFAB extends StatefulWidget {
  const CommunicationFAB({super.key});

  @override
  State<CommunicationFAB> createState() => _CommunicationFABState();
}

class _CommunicationFABState extends State<CommunicationFAB>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.appUser;

    if (currentUser == null) {
      return const SizedBox.shrink();
    }

    // Screen scaling helpers
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;
    final textScale = MediaQuery.of(context).textScaleFactor;

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Backdrop
        if (_isExpanded)
          GestureDetector(
            onTap: _toggleExpanded,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: AppTheme.textPrimary.withOpacity(0.3),
            ),
          ),

        // Action Buttons
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Emergency Broadcast (Admin only)
                if (currentUser.role == 'admin' && _isExpanded)
                  _buildActionButton(
                    label: "Emergency Broadcast",
                    color: AppTheme.error,
                    icon: Icons.emergency,
                    onPressed: _showEmergencyBroadcast,
                    textSize: 12 * textScale,
                    bottomMargin: 16 * h / 800,
                  ),

                // View All Chats
                if (_isExpanded)
                  _buildActionButton(
                    label: "All Conversations",
                    color: AppTheme.primary,
                    icon: Icons.chat_bubble,
                    onPressed: () {
                      _toggleExpanded();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChatListScreen(),
                        ),
                      );
                    },
                    textSize: 12 * textScale,
                    bottomMargin: 16 * h / 800,
                  ),

                // Chat with all
                if (_isExpanded)
                  _buildActionButton(
                    label: "Chat with all",
                    color: AppTheme.accent,
                    icon: Icons.groups,
                    onPressed: () {
                      _toggleExpanded();
                      Navigator.pushNamed(context, '/simple_chat');
                    },
                    textSize: 12 * textScale,
                    bottomMargin: 16 * h / 800,
                  ),

                // New Chat
                if (_isExpanded)
                  _buildActionButton(
                    label: "New Chat",
                    color: AppTheme.success,
                    icon: Icons.person_add,
                    onPressed: () {
                      _toggleExpanded();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const ContactSelectionScreen(),
                        ),
                      );
                    },
                    textSize: 12 * textScale,
                    bottomMargin: 16 * h / 800,
                  ),

                // Main FAB
                StreamBuilder<int>(
                  stream: CommunicationService.getUnreadMessageCount(
                    currentUser.uid,
                  ),
                  builder: (context, snapshot) {
                    final unreadCount = snapshot.data ?? 0;

                    return Stack(
                      children: [
                        FloatingActionButton(
                          heroTag: "main_communication",
                          onPressed: _toggleExpanded,
                          backgroundColor: AppTheme.success,
                          child: AnimatedRotation(
                            turns: _isExpanded ? 0.125 : 0,
                            duration: const Duration(milliseconds: 300),
                            child: Icon(
                              _isExpanded ? Icons.close : Icons.chat,
                              color: AppTheme.surface,
                              size: 24 * (w / 400),
                            ),
                          ),
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: EdgeInsets.all(2 * w / 400),
                              decoration: BoxDecoration(
                                color: AppTheme.error,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              constraints: BoxConstraints(
                                minWidth: 20 * w / 400,
                                minHeight: 20 * w / 800,
                              ),
                              child: Text(
                                unreadCount > 99 ? '99+' : '$unreadCount',
                                style: TextStyle(
                                  color: AppTheme.surface,
                                  fontSize: 10 * textScale,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onPressed,
    required double textSize,
    required double bottomMargin,
  }) {
    return Transform.scale(
      scale: _animation.value,
      child: Opacity(
        opacity: _animation.value,
        child: Container(
          margin: EdgeInsets.only(bottom: bottomMargin),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: AppTheme.surface,
                    fontWeight: FontWeight.w600,
                    fontSize: textSize,
                  ),
                ),
              ),
              SizedBox(width: 12 * MediaQuery.of(context).size.width / 400),
              FloatingActionButton(
                heroTag: label,
                onPressed: onPressed,
                backgroundColor: color,
                child: Icon(
                  icon,
                  color: AppTheme.surface,
                  size: 22 * MediaQuery.of(context).size.width / 400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEmergencyBroadcast() {
    _toggleExpanded();

    showDialog(
      context: context,
      builder: (context) {
        final textScale = MediaQuery.of(context).textScaleFactor;
        final w = MediaQuery.of(context).size.width;
        final h = MediaQuery.of(context).size.height;

        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.emergency, color: AppTheme.error, size: 24 * (w / 400)),
              SizedBox(width: 8 * (w / 400)),
              Text(
                'Emergency Broadcast',
                style: TextStyle(fontSize: 16 * textScale),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Send an emergency message to all users in the society.',
                  style: TextStyle(fontSize: 14 * textScale),
                ),
                SizedBox(height: 16 * (h / 800)),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Emergency Message',
                    border: OutlineInputBorder(),
                    hintText: 'Enter emergency details...',
                  ),
                  maxLines: 3,
                  onChanged: (value) {
                    // Store the message
                  },
                ),
                SizedBox(height: 16 * (h / 800)),
                Text(
                  'Select recipients:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14 * textScale,
                  ),
                ),
                SizedBox(height: 8 * (h / 800)),
                Text(
                  'Admin can broadcast to: Vendors, Residents, Guards',
                  style: TextStyle(
                    fontSize: 12 * textScale,
                    color: AppTheme.textSecondary,
                  ),
                ),
                SizedBox(height: 8 * (h / 800)),
                Wrap(
                  spacing: 8 * (w / 400),
                  children: [
                    FilterChip(
                      label: const Text('Vendors'),
                      selected: true,
                      onSelected: (selected) {},
                    ),
                    FilterChip(
                      label: const Text('Residents'),
                      selected: true,
                      onSelected: (selected) {},
                    ),
                    FilterChip(
                      label: const Text('Guards'),
                      selected: true,
                      onSelected: (selected) {},
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(fontSize: 14 * textScale),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Send emergency broadcast
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Emergency broadcast sent!'),
                    backgroundColor: AppTheme.error,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                foregroundColor: AppTheme.surface,
              ),
              child: Text(
                'Send Emergency',
                style: TextStyle(fontSize: 14 * textScale),
              ),
            ),
          ],
        );
      },
    );
  }
}
