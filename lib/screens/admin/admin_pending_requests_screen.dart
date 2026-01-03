import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';

class AdminPendingRequestsScreen extends StatefulWidget {
  const AdminPendingRequestsScreen({Key? key}) : super(key: key);

  @override
  State<AdminPendingRequestsScreen> createState() =>
      _AdminPendingRequestsScreenState();
}

class _AdminPendingRequestsScreenState
    extends State<AdminPendingRequestsScreen> {
  bool _isLoading = false;

  Future<void> _updateStatus(
    String uid,
    String status,
    Map<String, dynamic> userData,
  ) async {
    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'status': status,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'approved'
                ? 'Request approved for ${userData['name']}'
                : 'Request rejected for ${userData['name']}',
          ),
          backgroundColor: status == 'approved' ? AppTheme.success : AppTheme.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating status: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showRequestDetails(Map<String, dynamic> data, String uid) {
    final scale = MediaQuery.of(context).size.width * 0.04;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Request Details - ${data['name'] ?? 'Unknown'}',
          style: TextStyle(fontSize: scale * 1.1, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Name', data['name'] ?? 'N/A', scale),
              _buildDetailRow('Email', data['email'] ?? 'N/A', scale),
              _buildDetailRow('Phone', data['phone'] ?? 'N/A', scale),
              _buildDetailRow('Country', data['country'] ?? 'N/A', scale),
              _buildDetailRow('City', data['city'] ?? 'N/A', scale),
              _buildDetailRow('Society', data['society'] ?? 'N/A', scale),
              _buildDetailRow('Building', data['building'] ?? 'N/A', scale),
              _buildDetailRow('Flat Number', data['flat_no'] ?? 'N/A', scale),
              _buildDetailRow('Role', data['role'] ?? 'N/A', scale),
              _buildDetailRow('Status', data['status'] ?? 'N/A', scale),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(fontSize: scale)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateStatus(uid, 'rejected', data);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: Text('Reject',
                style: TextStyle(color: Colors.white, fontSize: scale)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateStatus(uid, 'approved', data);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
            child: Text('Approve',
                style: TextStyle(color: Colors.white, fontSize: scale)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, double scale) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: scale * 0.2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: scale * 5,
            child: Text(
              '$label:',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: scale * 0.9),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: scale * 0.9),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width * 0.04;

    return Scaffold(
      appBar: AppBar(
        title: Text('Pending Requests',
            style: TextStyle(fontSize: scale * 1.1)),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'resident')
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: scale * 4, color: AppTheme.error),
                  SizedBox(height: scale),
                  Text('Error: ${snapshot.error}',
                      style: TextStyle(fontSize: scale)),
                  SizedBox(height: scale),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: Text('Retry', style: TextStyle(fontSize: scale)),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: scale * 4, color: AppTheme.success),
                  SizedBox(height: scale),
                  Text(
                    'No Pending Requests',
                    style: TextStyle(
                      fontSize: scale * 1.2,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: scale * 0.5),
                  Text(
                    'All resident requests have been processed',
                    style: TextStyle(
                        fontSize: scale, color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          return Stack(
            children: [
              ListView.builder(
                padding: EdgeInsets.all(scale),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  final uid = docs[i].id;

                  return Card(
                    margin: EdgeInsets.only(bottom: scale * 0.8),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(scale),
                    ),
                    child: InkWell(
                      onTap: () => _showRequestDetails(data, uid),
                      borderRadius: BorderRadius.circular(scale),
                      child: Padding(
                        padding: EdgeInsets.all(scale),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppTheme.primary.withOpacity(0.1),
                                  radius: scale * 1.5,
                                  child: Text(
                                    (data['name'] ?? 'U')[0].toUpperCase(),
                                    style: TextStyle(
                                      fontSize: scale,
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(width: scale * 0.7),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['name'] ?? 'Unknown Name',
                                        style: TextStyle(
                                            fontSize: scale,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        data['email'] ?? 'No email',
                                        style: TextStyle(
                                            fontSize: scale * 0.9,
                                            color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: scale * 0.5,
                                      vertical: scale * 0.3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.warning.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(scale),
                                  ),
                                  child: Text(
                                    'PENDING',
                                    style: TextStyle(
                                      fontSize: scale * 0.8,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.warning,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: scale),
                            Container(
                              padding: EdgeInsets.all(scale * 0.8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(scale * 0.7),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.location_on,
                                          size: scale,
                                          color: Colors.grey.shade600),
                                      SizedBox(width: scale * 0.5),
                                      Expanded(
                                        child: Text(
                                          '${data['society'] ?? 'Unknown Society'}, ${data['building'] ?? 'Unknown Building'}',
                                          style: TextStyle(fontSize: scale),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: scale * 0.3),
                                  Row(
                                    children: [
                                      Icon(Icons.home,
                                          size: scale,
                                          color: Colors.grey.shade600),
                                      SizedBox(width: scale * 0.5),
                                      Text(
                                        'Flat: ${data['flat_no'] ?? 'Not specified'}',
                                        style: TextStyle(fontSize: scale),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: scale * 0.3),
                                  Row(
                                    children: [
                                      Icon(Icons.phone,
                                          size: scale,
                                          color: Colors.grey.shade600),
                                      SizedBox(width: scale * 0.5),
                                      Text(
                                        data['phone'] ?? 'No phone',
                                        style: TextStyle(fontSize: scale),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: scale),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () =>
                                        _updateStatus(uid, 'rejected', data),
                                    icon: Icon(Icons.close, size: scale),
                                    label: Text('Reject',
                                        style: TextStyle(fontSize: scale)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.error,
                                      side:
                                          BorderSide(color: AppTheme.error),
                                    ),
                                  ),
                                ),
                                SizedBox(width: scale * 0.7),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        _updateStatus(uid, 'approved', data),
                                    icon: Icon(Icons.check, size: scale),
                                    label: Text('Approve',
                                        style: TextStyle(fontSize: scale)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.success,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }
}
