import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/visitor.dart';
import '../../services/auth_provider.dart';
import '../../services/notification_service.dart';
import 'package:provider/provider.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/responsive_widgets.dart';
import 'qr_invitation_screen.dart';
import 'qr_invitations_list_screen.dart';
import 'visitor_details_screen.dart';

class VisitorManagementScreen extends StatefulWidget {
  const VisitorManagementScreen({Key? key}) : super(key: key);

  @override
  State<VisitorManagementScreen> createState() =>
      _VisitorManagementScreenState();
}

class _VisitorManagementScreenState extends State<VisitorManagementScreen> {
  String selectedFilter = 'pending';

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.appUser;

    return ResponsiveScaffold(
      title: 'Visitor Management',
      body: SafeArea(
        child: Column(
          children: [
            // QR Invitation Actions
            Container(
              color: Colors.white,
              padding: ResponsiveUtils.getResponsivePadding(context),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const QRInvitationScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.qr_code),
                      label: const Text('Generate QR'),
                    ),
                  ),
                  SizedBox(width: ResponsiveUtils.getSpacing(context, size: 'sm')),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const QRInvitationsListScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.list),
                      label: const Text('My QR Codes'),
                    ),
                  ),
                ],
              ),
            ),
            // Filter Tabs
            Container(
              color: Colors.white,
              padding: ResponsiveUtils.getResponsivePadding(context)
                  .copyWith(top: 0, bottom: 0),
              child: Row(
                children: [
                  Expanded(child: _buildFilterTab('Pending', 'pending')),
                  Expanded(child: _buildFilterTab('Approved', 'approved')),
                  Expanded(child: _buildFilterTab('Denied', 'denied')),
                ],
              ),
            ),

            // Visitors List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('visitors')
                    .where('visiting_flat', isEqualTo: user?.flatNo)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: Text('No data available'));
                  }

                  // Filter visitors in memory
                  final filteredDocs = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['status'] == selectedFilter;
                  }).toList();

                  // Sort by entry_time descending
                  filteredDocs.sort((a, b) {
                    final aTime =
                        (a.data() as Map<String, dynamic>)['entry_time']
                            as Timestamp?;
                    final bTime =
                        (b.data() as Map<String, dynamic>)['entry_time']
                            as Timestamp?;
                    if (aTime == null && bTime == null) return 0;
                    if (aTime == null) return 1;
                    if (bTime == null) return -1;
                    return bTime.compareTo(aTime);
                  });

                  if (filteredDocs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size:
                                ResponsiveUtils.getIconSize(context, size: 'xl'),
                            color: Colors.grey.shade400,
                          ),
                          SizedBox(
                              height:
                                  ResponsiveUtils.getSpacing(context, size: 'md')),
                          Text(
                            'No $selectedFilter visitors',
                            style: ResponsiveUtils.getBodyStyle(context)
                                .copyWith(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: ResponsiveUtils.getResponsivePadding(context),
                    itemCount: filteredDocs.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      final doc = filteredDocs[index];
                      final visitor = Visitor.fromMap(
                        doc.data() as Map<String, dynamic>,
                        doc.id,
                      );
                      return _buildVisitorCard(visitor);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(String title, String filter) {
    final isSelected = selectedFilter == filter;
    return GestureDetector(
      onTap: () => setState(() => selectedFilter = filter),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: ResponsiveUtils.getSpacing(context, size: 'md'),
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFF4CAF50) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: ResponsiveUtils.getBodyStyle(context).copyWith(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? const Color(0xFF4CAF50) : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildVisitorCard(Visitor visitor) {
    return GestureDetector(
      onTap: () async {
        // Navigate to visitor details screen
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VisitorDetailsScreen(visitor: visitor),
          ),
        );
        
        // Refresh if visitor was updated
        if (result == true && mounted) {
          setState(() {});
        }
      },
      child: Container(
        margin: EdgeInsets.only(
          bottom: ResponsiveUtils.getSpacing(context, size: 'sm'),
        ),
        padding: ResponsiveUtils.getResponsivePadding(context),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Builder(
                builder: (context) {
                  // Debug logging
                  print('DEBUG VM: Visitor ${visitor.name} - photoUrl: ${visitor.photoUrl}');
                  
                  return CircleAvatar(
                    radius: ResponsiveUtils.getIconSize(context, size: 'lg') / 2,
                    backgroundColor:
                        _getStatusColor(visitor.status).withOpacity(0.1),
                    backgroundImage: visitor.photoUrl != null && visitor.photoUrl!.isNotEmpty
                        ? NetworkImage(visitor.photoUrl!)
                        : null,
                    child: visitor.photoUrl == null || visitor.photoUrl!.isEmpty
                        ? Icon(
                            Icons.person,
                            color: _getStatusColor(visitor.status),
                            size: ResponsiveUtils.getIconSize(context, size: 'md'),
                          )
                        : null,
                  );
                },
              ),
              SizedBox(width: ResponsiveUtils.getSpacing(context, size: 'sm')),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      visitor.name,
                      style: ResponsiveUtils.getBodyStyle(context)
                          .copyWith(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      visitor.phone,
                      style: ResponsiveUtils.getCaptionStyle(context)
                          .copyWith(color: Colors.grey.shade600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _buildStatusChip(visitor.status),
            ],
          ),
          SizedBox(height: ResponsiveUtils.getSpacing(context, size: 'sm')),
          Text(
            'Entry Time: ${_formatDateTime(visitor.entryTime)}',
            style: ResponsiveUtils.getCaptionStyle(context)
                .copyWith(color: Colors.grey.shade600),
          ),

          if (visitor.status == 'pending') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _updateVisitorStatus(visitor.id, 'denied'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Deny'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _updateVisitorStatus(visitor.id, 'approved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: _getStatusColor(status),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'denied':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _updateVisitorStatus(String visitorId, String status) async {
    try {
      // Get visitor details first
      final visitorDoc = await FirebaseFirestore.instance
          .collection('visitors')
          .doc(visitorId)
          .get();
      
      if (!visitorDoc.exists) {
        throw Exception('Visitor not found');
      }

      final visitor = Visitor.fromMap(visitorDoc.data()!, visitorDoc.id);

      // Update visitor status
      await FirebaseFirestore.instance
          .collection('visitors')
          .doc(visitorId)
          .update({'status': status});

      // Send notification to guard about status update
      await NotificationService.sendVisitorStatusNotification(
        visitorId: visitorId,
        visitorName: visitor.name,
        status: status,
        flatNo: visitor.visitingFlat,
        hostName: visitor.hostName ?? '',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Visitor ${status == 'approved' ? 'approved' : 'denied'} successfully. Guard has been notified.',
          ),
          backgroundColor: status == 'approved' ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating visitor status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
