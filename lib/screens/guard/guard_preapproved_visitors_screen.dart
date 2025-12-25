import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../models/qr_invitation.dart';
import '../../services/qr_service.dart';

class GuardPreapprovedVisitorsScreen extends StatefulWidget {
  const GuardPreapprovedVisitorsScreen({Key? key}) : super(key: key);

  @override
  State<GuardPreapprovedVisitorsScreen> createState() =>
      _GuardPreapprovedVisitorsScreenState();
}

class _GuardPreapprovedVisitorsScreenState
    extends State<GuardPreapprovedVisitorsScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

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
              Container(
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
                        'Pre-approved Visitors',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),
              
              // Search Bar
              Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: AppTheme.cardRadius,
                  boxShadow: AppTheme.cardShadow,
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: AppTheme.inputDecoration(
                    labelText: 'Search visitors',
                    hintText: 'Search by name, phone, or flat...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) =>
                      setState(() => _searchQuery = value.toLowerCase()),
                ),
              ),

              // Visitors List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance.collection('visitors').snapshots(),
                  builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final allVisitors = snapshot.data?.docs ?? [];

                // Filter for approved visitors from yesterday onwards (in memory)
                final yesterday =
                    DateTime.now().subtract(const Duration(days: 1));
                final approvedVisitors = allVisitors.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = data['status'] ?? '';
                  final visitDate = data['visit_date'] as Timestamp?;

                  if (status != 'approved') return false;
                  if (visitDate == null) return true;
                  return visitDate.toDate().isAfter(yesterday);
                }).toList();

                // Sort by visit_date
                approvedVisitors.sort((a, b) {
                  final aDate =
                      (a.data() as Map<String, dynamic>)['visit_date']
                          as Timestamp?;
                  final bDate =
                      (b.data() as Map<String, dynamic>)['visit_date']
                          as Timestamp?;
                  if (aDate == null && bDate == null) return 0;
                  if (aDate == null) return 1;
                  if (bDate == null) return -1;
                  return aDate.compareTo(bDate);
                });

                // Apply search filter
                final filteredVisitors = approvedVisitors.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final phone = (data['phone'] ?? '').toString().toLowerCase();
                  final flat =
                      (data['visiting_flat'] ?? '').toString().toLowerCase();

                  return name.contains(_searchQuery) ||
                      phone.contains(_searchQuery) ||
                      flat.contains(_searchQuery);
                }).toList();

                if (filteredVisitors.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.people_outline, 
                              size: 64, 
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No pre-approved visitors today'
                                : 'No visitors found matching search',
                            style: AppTheme.headingSmall.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Pre-approved visitors will appear here',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filteredVisitors.length,
                  itemBuilder: (context, index) {
                    final visitor = filteredVisitors[index];
                    final data = visitor.data() as Map<String, dynamic>;
                    return _buildVisitorCard(visitor.id, data);
                  },
                );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVisitorCard(String visitorId, Map<String, dynamic> data) {
    final visitDate = data['visit_date'] as Timestamp?;
    final hasCheckedIn = data['checked_in'] == true;
    final checkInTime = data['check_in_time'] as Timestamp?;
    final qrCode = data['qr_code'] as String?;

    // If this is a QR visitor, show with QR invitation data
    if (qrCode != null) {
      return _buildQRVisitorCard(visitorId, data, qrCode, visitDate, hasCheckedIn, checkInTime);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.cardRadius,
        border: Border.all(
          color: hasCheckedIn ? AppTheme.success : AppTheme.primary.withOpacity(0.3),
          width: hasCheckedIn ? 2 : 1,
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                // Photo / Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: data['photo_url'] != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: Image.network(
                            data['photo_url'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.person, size: 30),
                          ),
                        )
                      : const Icon(Icons.person, size: 30),
                ),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['name'] ?? 'Unknown Visitor',
                        style: AppTheme.headingSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone,
                              size: 16, color: AppTheme.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              data['phone'] ?? 'No phone',
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Status badges
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // QR Code badge
                    if (data['qr_code'] != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.accent.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.qr_code,
                              size: 12,
                              color: AppTheme.accent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'QR',
                              style: AppTheme.caption.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    // Status badge
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: hasCheckedIn
                            ? AppTheme.success.withOpacity(0.1)
                            : AppTheme.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: hasCheckedIn
                              ? AppTheme.success.withOpacity(0.3)
                              : AppTheme.warning.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        hasCheckedIn ? 'CHECKED IN' : 'PENDING',
                        style: AppTheme.caption.copyWith(
                          fontWeight: FontWeight.bold,
                          color: hasCheckedIn ? AppTheme.success : AppTheme.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Visit details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.home, size: 16, color: AppTheme.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Visiting: ${data['visiting_flat'] ?? 'Unknown'}',
                          style: AppTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (data['purpose'] != null) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.info_outline,
                            size: 16, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            data['purpose'],
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      if (data['qr_code'] != null) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.qr_code,
                            size: 16, color: AppTheme.accent),
                        const SizedBox(width: 4),
                        Text(
                          'QR Entry',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.accent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ]
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.schedule,
                          size: 16, color: AppTheme.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          visitDate != null
                              ? 'Expected: ${_formatDateTime(visitDate.toDate())}'
                              : 'No visit time',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (data['vehicle_type'] != null &&
                          data['vehicle_type'] != 'None') ...[
                        const SizedBox(width: 8),
                        Icon(Icons.directions_car,
                            size: 16, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          data['vehicle_type'],
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                  if (hasCheckedIn && checkInTime != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.login,
                            size: 16, color: AppTheme.success),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Checked in: ${_formatDateTime(checkInTime.toDate())}',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.success,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Action buttons
            Row(
              children: [
                if (!hasCheckedIn) ...[
                  Expanded(
                    child: Container(
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
                        onPressed: () => _checkInVisitor(visitorId, data),
                        icon: const Icon(Icons.login, size: 18),
                        label: const Text('CHECK IN'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                              borderRadius: AppTheme.buttonRadius),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showVisitorDetails(data),
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('VIEW'),
                    style: AppTheme.secondaryButtonStyle,
                  ),
                ),
                if (hasCheckedIn) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.warning, AppTheme.warning.withOpacity(0.8)],
                        ),
                        borderRadius: AppTheme.buttonRadius,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.warning.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () => _checkOutVisitor(visitorId, data),
                        icon: const Icon(Icons.logout, size: 18),
                        label: const Text('CHECK OUT'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                              borderRadius: AppTheme.buttonRadius),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _checkInVisitor(String visitorId, Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance
          .collection('visitors')
          .doc(visitorId)
          .update({
        'checked_in': true,
        'check_in_time': FieldValue.serverTimestamp(),
        'status': 'checked_in',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${data['name']} checked in successfully'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error checking in visitor: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  void _checkOutVisitor(String visitorId, Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance
          .collection('visitors')
          .doc(visitorId)
          .update({
        'checked_out': true,
        'check_out_time': FieldValue.serverTimestamp(),
        'status': 'checked_out',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${data['name']} checked out successfully'),
          backgroundColor: AppTheme.warning,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error checking out visitor: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  void _showVisitorDetails(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(data['name'] ?? 'Visitor Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (data['photo_url'] != null) ...[
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: Image.network(
                      data['photo_url'],
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.person, size: 50),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              _buildDetailRow('Phone', data['phone'] ?? 'Not provided'),
              _buildDetailRow(
                  'Visiting Flat', data['visiting_flat'] ?? 'Not specified'),
              _buildDetailRow('Purpose', data['purpose'] ?? 'Not specified'),
              _buildDetailRow(
                  'Vehicle Type', data['vehicle_type'] ?? 'None'),
              if (data['qr_code'] != null)
                _buildDetailRow('Entry Method', 'QR Code (Auto-approved)'),
              if (data['visit_date'] != null)
                _buildDetailRow(
                    'Expected Time',
                    _formatDateTime(
                        (data['visit_date'] as Timestamp).toDate())),
              if (data['approved_by'] != null)
                _buildDetailRow('Approved By', data['approved_by']),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value, softWrap: true),
          ),
        ],
      ),
    );
  }

  Widget _buildQRVisitorCard(String visitorId, Map<String, dynamic> data, String qrCode, 
      Timestamp? visitDate, bool hasCheckedIn, Timestamp? checkInTime) {
    return FutureBuilder<QRInvitation?>(
      future: QRService.getQRInvitation(qrCode),
      builder: (context, qrSnapshot) {
        final qrInvitation = qrSnapshot.data;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: AppTheme.cardRadius,
            border: Border.all(
              color: hasCheckedIn ? AppTheme.success : AppTheme.accent.withOpacity(0.5),
              width: hasCheckedIn ? 2 : 2,
            ),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row with QR indicator
                Row(
                  children: [
                    // Photo / Avatar - prioritize QR invitation image
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: _buildVisitorPhoto(data, qrInvitation),
                    ),
                    const SizedBox(width: 12),

                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  data['name'] ?? 'Unknown Visitor',
                                  style: AppTheme.headingSmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // QR Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.accent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: AppTheme.accent.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.qr_code,
                                      size: 10,
                                      color: AppTheme.accent,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      'QR',
                                      style: AppTheme.caption.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.accent,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.phone,
                                  size: 16, color: AppTheme.textSecondary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  data['phone'] ?? 'No phone',
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: hasCheckedIn
                            ? AppTheme.success.withOpacity(0.1)
                            : AppTheme.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: hasCheckedIn
                              ? AppTheme.success.withOpacity(0.3)
                              : AppTheme.accent.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        hasCheckedIn ? 'CHECKED IN' : 'QR APPROVED',
                        style: AppTheme.caption.copyWith(
                          fontWeight: FontWeight.bold,
                          color: hasCheckedIn ? AppTheme.success : AppTheme.accent,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Visit details
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.home, size: 16, color: AppTheme.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Visiting: ${data['visiting_flat'] ?? 'Unknown'}',
                              style: AppTheme.bodyMedium.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (data['purpose'] != null) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.info_outline,
                                size: 16, color: AppTheme.textSecondary),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                data['purpose'],
                                style: AppTheme.bodyMedium.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.schedule,
                              size: 16, color: AppTheme.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              visitDate != null
                                  ? 'Expected: ${_formatDateTime(visitDate.toDate())}'
                                  : 'Auto-approved via QR',
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // QR Auto-approved indicator
                          Icon(Icons.verified,
                              size: 16, color: AppTheme.accent),
                          const SizedBox(width: 4),
                          Text(
                            'Auto-approved',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.accent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (hasCheckedIn && checkInTime != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.login,
                                size: 16, color: AppTheme.success),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Checked in: ${_formatDateTime(checkInTime.toDate())}',
                                style: AppTheme.bodyMedium.copyWith(
                                  color: AppTheme.success,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Action buttons
                Row(
                  children: [
                    if (!hasCheckedIn) ...[
                      Expanded(
                        child: Container(
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
                            onPressed: () => _checkInVisitor(visitorId, data),
                            icon: const Icon(Icons.login, size: 18),
                            label: const Text('CHECK IN'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: AppTheme.buttonRadius),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showQRVisitorDetails(data, qrInvitation),
                        icon: const Icon(Icons.visibility, size: 18),
                        label: const Text('VIEW'),
                        style: AppTheme.secondaryButtonStyle,
                      ),
                    ),
                    if (hasCheckedIn) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppTheme.warning, AppTheme.warning.withOpacity(0.8)],
                            ),
                            borderRadius: AppTheme.buttonRadius,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.warning.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () => _checkOutVisitor(visitorId, data),
                            icon: const Icon(Icons.logout, size: 18),
                            label: const Text('CHECK OUT'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: AppTheme.buttonRadius),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVisitorPhoto(Map<String, dynamic> data, QRInvitation? qrInvitation) {
    // Priority: QR invitation image > visitor photo > default icon
    if (qrInvitation?.imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Image.network(
          qrInvitation!.imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.person, size: 30),
        ),
      );
    } else if (data['photo_url'] != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Image.network(
          data['photo_url'],
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.person, size: 30),
        ),
      );
    } else {
      return const Icon(Icons.person, size: 30);
    }
  }

  void _showQRVisitorDetails(Map<String, dynamic> data, QRInvitation? qrInvitation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(data['name'] ?? 'QR Visitor Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Show QR invitation image if available
              if (qrInvitation?.imageUrl != null) ...[
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Expected Visitor (from QR)',
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.accent,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: Image.network(
                          qrInvitation!.imageUrl!,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.person, size: 50),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ] else if (data['photo_url'] != null) ...[
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: Image.network(
                      data['photo_url'],
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.person, size: 50),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              _buildDetailRow('Phone', data['phone'] ?? 'Not provided'),
              _buildDetailRow('Visiting Flat', data['visiting_flat'] ?? 'Not specified'),
              _buildDetailRow('Purpose', data['purpose'] ?? 'Not specified'),
              _buildDetailRow('Entry Method', 'QR Code (Auto-approved)'),
              if (qrInvitation != null) ...[
                _buildDetailRow('QR Host', qrInvitation.hostName),
                _buildDetailRow('QR Valid Until', _formatDateTime(qrInvitation.validUntil)),
                if (qrInvitation.notes?.isNotEmpty == true)
                  _buildDetailRow('QR Notes', qrInvitation.notes!),
              ],
              if (data['visit_date'] != null)
                _buildDetailRow('Expected Time', _formatDateTime((data['visit_date'] as Timestamp).toDate())),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
