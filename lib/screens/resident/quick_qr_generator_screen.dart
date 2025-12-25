import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/qr_invitation.dart';
import '../../services/qr_service.dart';
import '../../services/auth_provider.dart';
import '../../services/cloudinary_service.dart';
import '../../theme/app_theme.dart';

class QuickQRGeneratorScreen extends StatefulWidget {
  const QuickQRGeneratorScreen({Key? key}) : super(key: key);

  @override
  State<QuickQRGeneratorScreen> createState() => _QuickQRGeneratorScreenState();
}

class _QuickQRGeneratorScreenState extends State<QuickQRGeneratorScreen> {
  final _purposeController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  bool _isGenerating = false;
  QRInvitation? _generatedInvitation;
  XFile? _selectedImage;
  
  // Purpose of visit options
  final List<String> _purposeOptions = [
    'Personal Visit',
    'Delivery',
    'Service/Repair',
    'Medical',
    'Business',
    'Other',
  ];
  
  String? _selectedPurpose;

  @override
  void dispose() {
    _purposeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Quick QR Generator',
          style: AppTheme.headingSmall.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: _generatedInvitation == null
                ? _buildQuickForm()
                : _buildQRDisplay(),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Info Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.05),
            borderRadius: AppTheme.cardRadius,
            border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Generate a QR code for visitors. They can scan it to auto-register and get approved instantly!',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Quick Purpose Selection
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: AppTheme.cardRadius,
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Purpose of Visit',
                style: AppTheme.headingSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Purpose dropdown
              DropdownButtonFormField<String>(
                value: _selectedPurpose,
                decoration: AppTheme.inputDecoration(
                  labelText: 'Select Purpose of Visit',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                items: _purposeOptions.map((String purpose) {
                  return DropdownMenuItem<String>(
                    value: purpose,
                    child: Text(purpose),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedPurpose = newValue;
                    _purposeController.text = newValue ?? '';
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a purpose of visit';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Custom purpose input (only show if "Other" is selected)
              if (_selectedPurpose == 'Other') ...[
                TextFormField(
                  controller: _purposeController,
                  decoration: AppTheme.inputDecoration(
                    labelText: 'Enter custom purpose',
                    hintText: 'e.g., Doctor visit, Tutor, etc.',
                    prefixIcon: Icon(Icons.edit_outlined),
                  ),
                  validator: (value) {
                    if (_selectedPurpose == 'Other' && (value == null || value.trim().isEmpty)) {
                      return 'Please enter a custom purpose';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    // Keep the controller updated for "Other" option
                  },
                ),
              ],
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Optional Image Upload
        Container(
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
                  Icon(Icons.image_outlined, color: AppTheme.accent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Visitor Image (Optional)',
                    style: AppTheme.headingSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Image preview or upload button
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: _selectedImage != null 
                          ? Colors.transparent 
                          : AppTheme.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primary.withOpacity(0.3),
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: _selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              File(_selectedImage!.path),
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo_outlined,
                                size: 32,
                                color: AppTheme.primary,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add Photo',
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.primary,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              
              if (_selectedImage != null) ...[
                const SizedBox(height: 12),
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedImage = null;
                      });
                    },
                    icon: Icon(Icons.delete_outline, color: AppTheme.error),
                    label: Text(
                      'Remove Image',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.error,
                      ),
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 8),
              Text(
                'Adding a photo helps guards identify your visitor easily',
                style: AppTheme.caption.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Validity Info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.success.withOpacity(0.05),
            borderRadius: AppTheme.cardRadius,
            border: Border.all(color: AppTheme.success.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.schedule, color: AppTheme.success, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick QR Code Settings',
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.success,
                      ),
                    ),
                    Text(
                      '• Valid for 24 hours\n• Maximum 5 visitors\n• Auto-approved entry',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Generate Button
        Container(
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: AppTheme.buttonRadius,
            boxShadow: AppTheme.buttonShadow,
          ),
          child: ElevatedButton(
            onPressed: _isGenerating || _selectedPurpose == null || (_selectedPurpose == 'Other' && _purposeController.text.trim().isEmpty)
                ? null 
                : _generateQuickQR,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: AppTheme.buttonRadius,
              ),
            ),
            child: _isGenerating
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Generate QR Code',
                        style: AppTheme.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildQRDisplay() {
    final qrData = QRService.generateQRData(_generatedInvitation!.id);
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: AppTheme.cardRadius,
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle, color: AppTheme.success, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'QR Code Generated!',
                    style: AppTheme.headingSmall.copyWith(
                      color: AppTheme.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Show uploaded image if available
              if (_generatedInvitation!.imageUrl != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Visitor Image',
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _generatedInvitation!.imageUrl!,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.image_not_supported,
                                color: Colors.grey.shade400,
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
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'QR Code Details',
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow('Purpose', _generatedInvitation!.purpose),
                    _buildDetailRow('Valid Until', _formatDateTime(_generatedInvitation!.validUntil)),
                    _buildDetailRow('Max Visitors', '${_generatedInvitation!.maxVisitors}'),
                    _buildDetailRow('Status', 'Auto-Approved'),
                    if (_generatedInvitation!.imageUrl != null)
                      _buildDetailRow('Image', 'Included'),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Action Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _generatedInvitation = null;
                    _selectedPurpose = null;
                    _purposeController.clear();
                    _selectedImage = null;
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Generate Another'),
                style: AppTheme.secondaryButtonStyle,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/qr_invitations_list'),
                icon: const Icon(Icons.list),
                label: const Text('View All QRs'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppTheme.buttonRadius,
                  ),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.home),
            label: const Text('Back to Home'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: AppTheme.buttonRadius,
              ),
            ),
          ),
        ),
      ],
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
              style: AppTheme.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
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

  Future<void> _generateQuickQR() async {
    if (_selectedPurpose == null || (_selectedPurpose == 'Other' && _purposeController.text.trim().isEmpty)) return;

    setState(() => _isGenerating = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.appUser;

      if (user == null) {
        throw Exception('User not found');
      }

      String? imageUrl;
      
      // Upload image if selected
      if (_selectedImage != null) {
        imageUrl = await CloudinaryService.uploadImage(
          File(_selectedImage!.path),
          folder: 'qr_invitations',
        );
        
        if (imageUrl == null) {
          throw Exception('Failed to upload image');
        }
      }

      // Generate QR with default 24-hour validity and 5 max visitors
      final invitation = await QRService.generateQRInvitation(
        hostId: user.uid,
        hostName: user.name,
        flatNo: user.flatNo ?? '',
        purpose: _selectedPurpose == 'Other' ? _purposeController.text.trim() : _selectedPurpose!,
        validFrom: DateTime.now(),
        validUntil: DateTime.now().add(const Duration(hours: 24)),
        maxVisitors: 5,
        notes: 'Quick QR - Auto-approved entry',
        imageUrl: imageUrl,
      );

      setState(() {
        _generatedInvitation = invitation;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() => _isGenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating QR code: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}