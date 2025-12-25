import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/qr_invitation.dart';
import '../../services/qr_service.dart';
import '../../services/auth_provider.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/responsive_widgets.dart';
import 'qr_invitation_screen.dart';

class QRInvitationsListScreen extends StatelessWidget {
  const QRInvitationsListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.appUser;

    return ResponsiveScaffold(
      title: 'My QR Invitations',
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const QRInvitationScreen(),
            ),
          );
        },
        backgroundColor: const Color(0xFF4CAF50),
        child: const Icon(Icons.qr_code, color: Colors.white),
      ),
      body: SafeArea(
        child: StreamBuilder<List<QRInvitation>>(
          stream: QRService.getHostInvitations(user?.uid ?? ''),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }

            final invitations = snapshot.data ?? [];

            if (invitations.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.qr_code_2,
                      size: ResponsiveUtils.getIconSize(context, size: 'xl'),
                      color: Colors.grey.shade400,
                    ),
                    SizedBox(height: ResponsiveUtils.getSpacing(context, size: 'md')),
                    Text(
                      'No QR invitations yet',
                      style: ResponsiveUtils.getBodyStyle(context)
                          .copyWith(color: Colors.grey.shade600),
                    ),
                    SizedBox(height: ResponsiveUtils.getSpacing(context, size: 'sm')),
                    Text(
                      'Tap the + button to create your first QR invitation',
                      style: ResponsiveUtils.getCaptionStyle(context)
                          .copyWith(color: Colors.grey.shade500),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: ResponsiveUtils.getResponsivePadding(context),
              itemCount: invitations.length,
              itemBuilder: (context, index) {
                final invitation = invitations[index];
                return _buildInvitationCard(context, invitation);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildInvitationCard(BuildContext context, QRInvitation invitation) {
    final isExpired = DateTime.now().isAfter(invitation.validUntil);
    final isActive = invitation.isActive && !isExpired;

    return Container(
      margin: EdgeInsets.only(
        bottom: ResponsiveUtils.getSpacing(context, size: 'sm'),
      ),
      child: Card(
        child: Padding(
          padding: ResponsiveUtils.getResponsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invitation.purpose,
                          style: ResponsiveUtils.getBodyStyle(context)
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: ResponsiveUtils.getSpacing(context, size: 'xs')),
                        Text(
                          'Created: ${_formatDateTime(invitation.createdAt)}',
                          style: ResponsiveUtils.getCaptionStyle(context)
                              .copyWith(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(context, invitation, isActive, isExpired),
                ],
              ),
              
              SizedBox(height: ResponsiveUtils.getSpacing(context, size: 'md')),
              
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      context,
                      'Valid Until',
                      _formatDateTime(invitation.validUntil),
                      Icons.schedule,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      context,
                      'Usage',
                      '${invitation.usedCount}/${invitation.maxVisitors}',
                      Icons.people,
                    ),
                  ),
                ],
              ),
              
              if (invitation.notes?.isNotEmpty == true) ...[
                SizedBox(height: ResponsiveUtils.getSpacing(context, size: 'sm')),
                Text(
                  'Notes: ${invitation.notes}',
                  style: ResponsiveUtils.getCaptionStyle(context)
                      .copyWith(color: Colors.grey.shade600),
                ),
              ],
              
              if (isActive) ...[
                SizedBox(height: ResponsiveUtils.getSpacing(context, size: 'md')),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showQRCode(context, invitation),
                        icon: const Icon(Icons.qr_code),
                        label: const Text('Show QR'),
                      ),
                    ),
                    SizedBox(width: ResponsiveUtils.getSpacing(context, size: 'sm')),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _deactivateInvitation(context, invitation),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.block),
                        label: const Text('Deactivate'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, QRInvitation invitation, bool isActive, bool isExpired) {
    String status;
    Color color;

    if (!invitation.isActive) {
      status = 'DEACTIVATED';
      color = Colors.grey;
    } else if (isExpired) {
      status = 'EXPIRED';
      color = Colors.red;
    } else if (invitation.usedCount >= invitation.maxVisitors) {
      status = 'USED UP';
      color = Colors.orange;
    } else {
      status = 'ACTIVE';
      color = const Color(0xFF4CAF50);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: ResponsiveUtils.getIconSize(context, size: 'sm'),
          color: Colors.grey.shade600,
        ),
        SizedBox(width: ResponsiveUtils.getSpacing(context, size: 'xs')),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: ResponsiveUtils.getCaptionStyle(context)
                    .copyWith(color: Colors.grey.shade600),
              ),
              Text(
                value,
                style: ResponsiveUtils.getCaptionStyle(context)
                    .copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showQRCode(BuildContext context, QRInvitation invitation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRInvitationScreen(),
      ),
    );
  }

  Future<void> _deactivateInvitation(BuildContext context, QRInvitation invitation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate Invitation'),
        content: const Text(
          'Are you sure you want to deactivate this QR invitation? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await QRService.deactivateInvitation(invitation.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitation deactivated successfully'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deactivating invitation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}