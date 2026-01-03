import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/qr_invitation.dart';
import '../../models/visitor.dart';
import '../../services/qr_service.dart';
import '../../services/notification_service.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/responsive_widgets.dart';
import '../../theme/app_theme.dart';

class VisitorRegistrationScreen extends StatefulWidget {
  final QRInvitation invitation;

  const VisitorRegistrationScreen({
    Key? key,
    required this.invitation,
  }) : super(key: key);

  @override
  State<VisitorRegistrationScreen> createState() => _VisitorRegistrationScreenState();
}

class _VisitorRegistrationScreenState extends State<VisitorRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _isSubmitting = false;
  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

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
                        'Visitor Registration',
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
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildInvitationCard(),
                        const SizedBox(height: 24),
                        _buildRegistrationForm(),
                        const SizedBox(height: 32),
                        _buildSubmitButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvitationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.cardRadius,
        boxShadow: AppTheme.cardShadow,
        border: Border.all(
          color: AppTheme.success.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.verified,
                  color: AppTheme.success,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Valid Invitation',
                style: AppTheme.headingSmall.copyWith(
                  color: AppTheme.success,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Show invitation image if available
          if (widget.invitation.imageUrl != null) ...[
            Center(
              child: Column(
                children: [
                  Text(
                    'Expected Visitor',
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.invitation.imageUrl!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.person,
                            color: Colors.grey.shade400,
                            size: 40,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
            
          _buildDetailRow('Host', widget.invitation.hostName),
          _buildDetailRow('Flat No', widget.invitation.flatNo),
          _buildDetailRow('Purpose', widget.invitation.purpose),
          _buildDetailRow('Valid Until', _formatDateTime(widget.invitation.validUntil)),
          
          if (widget.invitation.notes?.isNotEmpty == true)
            _buildDetailRow('Notes', widget.invitation.notes!),
        ],
      ),
    );
  }

  Widget _buildRegistrationForm() {
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
              Text('Your Information', style: AppTheme.headingSmall),
            ],
          ),
          
          const SizedBox(height: 20),
            
          // Photo section
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(60),
                      border: Border.all(
                        color: AppTheme.primary.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: _selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(58),
                            child: Image.network(
                              _selectedImage!.path,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.person_add_alt_1,
                                  size: 48,
                                  color: AppTheme.primary,
                                );
                              },
                            ),
                          )
                        : Icon(
                            Icons.person_add_alt_1,
                            size: 48,
                            color: AppTheme.primary,
                          ),
                  ),
                ),
                
                const SizedBox(height: 12),
                  
                TextButton.icon(
                  onPressed: _pickImage,
                  icon: Icon(Icons.camera_alt, color: AppTheme.primary),
                  label: Text(
                    _selectedImage != null ? 'Change Photo' : 'Add Photo (Optional)',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          TextFormField(
            controller: _nameController,
            decoration: AppTheme.inputDecoration(
              labelText: 'Full Name *',
              prefixIcon: const Icon(Icons.person),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your full name';
              }
              if (value.trim().length < 2) {
                return 'Name must be at least 2 characters';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _phoneController,
            decoration: AppTheme.inputDecoration(
              labelText: 'Phone Number *',
              prefixIcon: const Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your phone number';
              }
              if (value.trim().length < 10) {
                return 'Please enter a valid phone number';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: AppTheme.buttonRadius,
        boxShadow: AppTheme.buttonShadow,
      ),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitRegistration,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: AppTheme.buttonRadius,
          ),
        ),
        child: _isSubmitting
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                'Complete Registration',
                style: AppTheme.bodyLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
            width: 80,
            child: Text(
              '$label:',
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // Use the QR invitation
      final success = await QRService.useQRInvitation(widget.invitation.id);
      
      if (!success) {
        throw Exception('Failed to validate invitation');
      }

      // Create visitor record - AUTO APPROVED since they have valid QR code
      final visitor = Visitor(
        id: '', // Will be set by Firestore
        name: _nameController.text.trim(),
        visitingFlat: widget.invitation.flatNo,
        phone: _phoneController.text.trim(),
        photoUrl: null, // TODO: Upload image if selected
        status: 'approved', // AUTO APPROVED via QR code
        entryTime: DateTime.now(),
        purpose: widget.invitation.purpose,
        qrCode: widget.invitation.id,
        hostId: widget.invitation.hostId,
        hostName: widget.invitation.hostName,
        isPreApproved: true, // Since they have a valid QR code
      );

      // Save to Firestore
      final docRef = await FirebaseFirestore.instance
          .collection('visitors')
          .add(visitor.toMap());

      // Send notifications to guard and resident about auto-approved visitor
      await Future.wait([
        NotificationService.sendQRVisitorNotification(
          visitorId: docRef.id,
          visitorName: visitor.name,
          flatNo: visitor.visitingFlat,
          hostName: visitor.hostName ?? '',
          purpose: visitor.purpose ?? '',
        ),
        NotificationService.sendResidentQRVisitorNotification(
          hostId: visitor.hostId ?? '',
          visitorId: docRef.id,
          visitorName: visitor.name,
          visitorPhone: visitor.phone,
          purpose: visitor.purpose ?? '',
        ),
      ]);

      // Show success and navigate back
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Registration Successful!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppTheme.success,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  'Your visit has been automatically approved! You can now proceed to the gate for entry.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Go back to scanner
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}