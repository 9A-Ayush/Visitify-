import 'package:flutter/material.dart';
import '../../models/visitor.dart';
import '../../theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/notification_service.dart';

class VisitorDetailsScreen extends StatelessWidget {
  final Visitor visitor;

  const VisitorDetailsScreen({Key? key, required this.visitor})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              _buildAppBar(context),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      
                      // Visitor Photo
                      _buildVisitorPhoto(context),
                      const SizedBox(height: 24),
                      
                      // Visitor Information
                      _buildInfoCard(context),
                      const SizedBox(height: 16),
                      
                      // Visit Details
                      _buildVisitDetailsCard(context),
                      const SizedBox(height: 16),
                      
                      // Status Card
                      _buildStatusCard(context),
                      const SizedBox(height: 24),
                      
                      // Action Buttons (if pending)
                      if (visitor.status == 'pending')
                        _buildActionButtons(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const Expanded(
            child: Text(
              'Visitor Details',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }


  Widget _buildVisitorPhoto(BuildContext context) {
    // Debug: Print photo URL
    print('DEBUG: Visitor photo URL: ${visitor.photoUrl}');
    
    return Center(
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.softShadow,
          border: Border.all(
            color: _getStatusColor(visitor.status).withOpacity(0.3),
            width: 3,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(17),
          child: visitor.photoUrl != null && visitor.photoUrl!.isNotEmpty
              ? Image.network(
                  visitor.photoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    print('DEBUG: Error loading image: $error');
                    return _buildDefaultAvatar();
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      print('DEBUG: Image loaded successfully');
                      return child;
                    }
                    print('DEBUG: Loading image... ${loadingProgress.cumulativeBytesLoaded} / ${loadingProgress.expectedTotalBytes}');
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        color: AppTheme.primary,
                      ),
                    );
                  },
                )
              : _buildDefaultAvatar(),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getStatusColor(visitor.status).withOpacity(0.3),
            _getStatusColor(visitor.status).withOpacity(0.1),
          ],
        ),
      ),
      child: Icon(
        Icons.person,
        size: 100,
        color: _getStatusColor(visitor.status),
      ),
    );
  }


  Widget _buildInfoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.cardRadius,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text('Visitor Information', style: AppTheme.headingSmall),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildInfoRow(
            Icons.badge_outlined,
            'Name',
            visitor.name,
            AppTheme.primary,
          ),
          const SizedBox(height: 12),
          
          _buildInfoRow(
            Icons.phone_outlined,
            'Phone Number',
            visitor.phone,
            AppTheme.success,
          ),
          
          if (visitor.hostName != null && visitor.hostName!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.person_outline,
              'Host Name',
              visitor.hostName!,
              AppTheme.accent,
            ),
          ],
        ],
      ),
    );
  }


  Widget _buildVisitDetailsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.cardRadius,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text('Visit Details', style: AppTheme.headingSmall),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildInfoRow(
            Icons.home_outlined,
            'Visiting Flat',
            visitor.visitingFlat,
            AppTheme.primary,
          ),
          const SizedBox(height: 12),
          
          _buildInfoRow(
            Icons.description_outlined,
            'Purpose',
            visitor.purpose ?? 'Not specified',
            AppTheme.secondary,
          ),
          const SizedBox(height: 12),
          
          _buildInfoRow(
            Icons.directions_car_outlined,
            'Vehicle Type',
            visitor.vehicleType ?? 'None',
            AppTheme.warning,
          ),
          const SizedBox(height: 12),
          
          _buildInfoRow(
            Icons.access_time,
            'Entry Time',
            _formatDateTime(visitor.entryTime),
            AppTheme.accent,
          ),
          
          if (visitor.exitTime != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.logout,
              'Exit Time',
              _formatDateTime(visitor.exitTime!),
              AppTheme.error,
            ),
          ],
        ],
      ),
    );
  }


  Widget _buildStatusCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.cardRadius,
        boxShadow: AppTheme.cardShadow,
        border: Border.all(
          color: _getStatusColor(visitor.status).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor(visitor.status).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getStatusIcon(visitor.status),
              size: 48,
              color: _getStatusColor(visitor.status),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Status: ${visitor.status.toUpperCase()}',
            style: AppTheme.headingMedium.copyWith(
              color: _getStatusColor(visitor.status),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getStatusMessage(visitor.status),
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }


  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Deny Button
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: AppTheme.buttonRadius,
            border: Border.all(color: AppTheme.error, width: 2),
          ),
          child: OutlinedButton.icon(
            onPressed: () => _updateVisitorStatus(context, 'denied'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.error,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: AppTheme.buttonRadius,
              ),
            ),
            icon: const Icon(Icons.close),
            label: Text(
              'Deny Entry',
              style: AppTheme.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // Approve Button
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.success, AppTheme.success.withOpacity(0.8)],
            ),
            borderRadius: AppTheme.buttonRadius,
            boxShadow: [
              BoxShadow(
                color: AppTheme.success.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: () => _updateVisitorStatus(context, 'approved'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: AppTheme.buttonRadius,
              ),
            ),
            icon: const Icon(Icons.check, color: Colors.white),
            label: Text(
              'Approve Entry',
              style: AppTheme.bodyLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTheme.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppTheme.success;
      case 'denied':
        return AppTheme.error;
      case 'pending':
      default:
        return AppTheme.warning;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle;
      case 'denied':
        return Icons.cancel;
      case 'pending':
      default:
        return Icons.pending;
    }
  }

  String _getStatusMessage(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'This visitor has been approved for entry';
      case 'denied':
        return 'Entry has been denied for this visitor';
      case 'pending':
      default:
        return 'Waiting for your approval decision';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }


  Future<void> _updateVisitorStatus(
      BuildContext context, String status) async {
    try {
      // Update visitor status
      await FirebaseFirestore.instance
          .collection('visitors')
          .doc(visitor.id)
          .update({'status': status});

      // Send notification to guard
      await NotificationService.sendVisitorStatusNotification(
        visitorId: visitor.id,
        visitorName: visitor.name,
        status: status,
        flatNo: visitor.visitingFlat,
        hostName: visitor.hostName ?? '',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Visitor ${status == 'approved' ? 'approved' : 'denied'} successfully!',
            ),
            backgroundColor:
                status == 'approved' ? AppTheme.success : AppTheme.error,
          ),
        );

        // Go back to visitor management screen
        Navigator.pop(context, true); // Return true to indicate update
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating visitor status: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }
}
