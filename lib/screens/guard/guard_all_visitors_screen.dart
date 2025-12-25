import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';

class GuardAllVisitorsScreen extends StatefulWidget {
  const GuardAllVisitorsScreen({Key? key}) : super(key: key);

  @override
  State<GuardAllVisitorsScreen> createState() => _GuardAllVisitorsScreenState();
}

class _GuardAllVisitorsScreenState extends State<GuardAllVisitorsScreen> {
  String _selectedFilter = 'all';
  final List<String> _statusFilters = [
    'all',
    'pending',
    'approved',
    'denied',
    'checked_in',
    'checked_out',
  ];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
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
                        'All Visitors',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.filter_list, color: Colors.white),
                      onSelected: (value) => setState(() => _selectedFilter = value),
                      itemBuilder: (context) => _statusFilters.map((filter) {
                        return PopupMenuItem(
                          value: filter,
                          child: Row(
                            children: [
                              Icon(
                                _selectedFilter == filter
                                    ? Icons.check
                                    : Icons.circle_outlined,
                                size: 18,
                                color: _selectedFilter == filter
                                    ? AppTheme.primary
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(filter.toUpperCase()),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
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
                      return Center(
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    final allVisitors = snapshot.data?.docs ?? [];

                    // Filter by status
                    final statusFilteredVisitors = _selectedFilter == 'all'
                        ? allVisitors
                        : allVisitors.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return (data['status'] ?? '') == _selectedFilter;
                          }).toList();

                    // Search filter
                    final filteredVisitors =
                        statusFilteredVisitors.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name =
                          (data['name'] ?? '').toString().toLowerCase();
                      final phone =
                          (data['phone'] ?? '').toString().toLowerCase();
                      final flat =
                          (data['visiting_flat'] ?? '').toString().toLowerCase();
                      return name.contains(_searchQuery) ||
                          phone.contains(_searchQuery) ||
                          flat.contains(_searchQuery);
                    }).toList();

                    // Sort by entry_time (newest first)
                    filteredVisitors.sort((a, b) {
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

                    if (filteredVisitors.isEmpty) return _buildEmptyState();

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

  // Visitor Card
  Widget _buildVisitorCard(String visitorId, Map<String, dynamic> data) {
    final status = (data['status'] ?? 'pending').toString();
    final entryTime = data['entry_time'] as Timestamp?;
    final checkInTime = data['check_in_time'] as Timestamp?;

    Color statusColor = AppTheme.warning;
    IconData statusIcon = Icons.pending;
    String statusText = status.toUpperCase();

    switch (status) {
      case 'approved':
        statusColor = AppTheme.success;
        statusIcon = Icons.check_circle;
        break;
      case 'denied':
        statusColor = AppTheme.error;
        statusIcon = Icons.cancel;
        break;
      case 'checked_in':
        statusColor = AppTheme.primary;
        statusIcon = Icons.login;
        break;
      case 'checked_out':
        statusColor = AppTheme.secondary;
        statusIcon = Icons.logout;
        break;
      case 'pending':
        statusColor = AppTheme.warning;
        statusIcon = Icons.pending;
        statusText = 'AWAITING APPROVAL';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.cardRadius,
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
                CircleAvatar(
                  radius: 26,
                  backgroundColor: statusColor.withOpacity(0.1),
                  backgroundImage: data['photo_url'] != null
                      ? NetworkImage(data['photo_url'])
                      : null,
                  child: data['photo_url'] == null
                      ? Icon(statusIcon, color: statusColor, size: 28)
                      : null,
                ),
                const SizedBox(width: 12),

                // Visitor Info
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
                          const Icon(Icons.home, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Flat: ${data['visiting_flat'] ?? 'Unknown'}',
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

                // Status Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    statusText,
                    style: AppTheme.caption.copyWith(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Contact + Purpose
            Row(
              children: [
                Icon(Icons.phone, size: 16, color: AppTheme.textSecondary),
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
                const SizedBox(width: 16),
                Icon(Icons.info_outline, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    data['purpose'] ?? 'No purpose',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Time Information
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entryTime != null
                        ? 'Logged: ${_formatDateTime(entryTime.toDate())}'
                        : 'No entry time',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (checkInTime != null) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.login, size: 16, color: AppTheme.success),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'In: ${_formatDateTime(checkInTime.toDate())}',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.success,
                      ),
                      overflow: TextOverflow.ellipsis,
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

  // Empty State
  Widget _buildEmptyState() {
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
                  ? 'No ${_selectedFilter == 'all' ? '' : _selectedFilter} visitors found'
                  : 'No visitors found matching search',
              style: AppTheme.headingSmall.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Visitors will appear here once they register',
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}