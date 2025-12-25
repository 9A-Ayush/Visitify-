import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/qr_invitation.dart';
import '../../services/qr_service.dart';
import '../../services/auth_provider.dart';
import '../../services/cloudinary_service.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/responsive_widgets.dart';
import '../../theme/app_theme.dart';

class QRInvitationScreen extends StatefulWidget {
  const QRInvitationScreen({Key? key}) : super(key: key);

  @override
  State<QRInvitationScreen> createState() => _QRInvitationScreenState();
}

class _QRInvitationScreenState extends State<QRInvitationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _purposeController = TextEditingController();
  final _notesController = TextEditingController();
  final _maxVisitorsController = TextEditingController(text: '1');
  final ImagePicker _picker = ImagePicker();
  
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
  
  DateTime _validFrom = DateTime.now();
  DateTime _validUntil = DateTime.now().add(const Duration(hours: 24));
  
  bool _isGenerating = false;
  QRInvitation? _generatedInvitation;
  XFile? _selectedImage;

  @override
  void dispose() {
    _purposeController.dispose();
    _notesController.dispose();
    _maxVisitorsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Generate QR Invitation',
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
                ? _buildInvitationForm()
                : _buildQRDisplay(),
          ),
        ),
      ),
    );
  }

  Widget _buildInvitationForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Visitor Details Card
          Container(
            padding: const EdgeInsets.all(24),
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
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.person_add,
                        color: AppTheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Visitor Details',
                      style: AppTheme.headingSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                DropdownButtonFormField<String>(
                  value: _selectedPurpose,
                  decoration: AppTheme.inputDecoration(
                    labelText: 'Purpose of Visit',
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
                      if (newValue != 'Other') {
                        _purposeController.text = newValue ?? '';
                      } else {
                        _purposeController.clear();
                      }
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a purpose of visit';
                    }
                    return null;
                  },
                ),
                
                // Custom purpose input (only show if "Other" is selected)
                if (_selectedPurpose == 'Other') ...[
                  const SizedBox(height: 20),
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
                  ),
                ],
                
                const SizedBox(height: 20),
                
                TextFormField(
                  controller: _maxVisitorsController,
                  decoration: AppTheme.inputDecoration(
                    labelText: 'Maximum Visitors',
                    prefixIcon: Icon(Icons.group_outlined),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter maximum visitors';
                    }
                    final num = int.tryParse(value);
                    if (num == null || num < 1 || num > 10) {
                      return 'Please enter a number between 1 and 10';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 20),
                
                TextFormField(
                  controller: _notesController,
                  decoration: AppTheme.inputDecoration(
                    labelText: 'Additional Notes (Optional)',
                    hintText: 'Any special instructions',
                    prefixIcon: Icon(Icons.note_outlined),
                  ),
                  maxLines: 3,
                ),
                
                const SizedBox(height: 20),
                
                // Optional Image Upload
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.image_outlined, color: AppTheme.accent, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Visitor Image (Optional)',
                          style: AppTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: _selectedImage != null 
                                ? Colors.transparent 
                                : AppTheme.primary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.primary.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: _selectedImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(11),
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
                                      size: 24,
                                      color: AppTheme.primary,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Add Photo',
                                      style: AppTheme.caption.copyWith(
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    
                    if (_selectedImage != null) ...[
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedImage = null;
                            });
                          },
                          icon: Icon(Icons.delete_outline, size: 16, color: AppTheme.error),
                          label: Text(
                            'Remove',
                            style: AppTheme.caption.copyWith(
                              color: AppTheme.error,
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
          
          const SizedBox(height: 24),
          
          // Validity Period Card
          Container(
            padding: const EdgeInsets.all(24),
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
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.schedule,
                        color: AppTheme.accent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Validity Period',
                      style: AppTheme.headingSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                _buildDateTimeSelector(
                  'Valid From',
                  _formatDateTime(_validFrom),
                  Icons.calendar_today,
                  () => _selectDateTime(context, true),
                ),
                
                const SizedBox(height: 16),
                
                _buildDateTimeSelector(
                  'Valid Until',
                  _formatDateTime(_validUntil),
                  Icons.event,
                  () => _selectDateTime(context, false),
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
              onPressed: _isGenerating ? null : _generateQRInvitation,
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
      ),
    );
  }

  Widget _buildDateTimeSelector(String title, String value, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRDisplay() {
    final qrData = QRService.generateQRData(_generatedInvitation!.id);
    
    return Column(
      children: [
        Card(
          child: Padding(
            padding: ResponsiveUtils.getResponsivePadding(context),
            child: Column(
              children: [
                Text(
                  'QR Code Generated Successfully!',
                  style: ResponsiveUtils.getHeadingStyle(context)
                      .copyWith(color: const Color(0xFF4CAF50)),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: ResponsiveUtils.getSpacing(context, size: 'lg')),
                
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
                
                SizedBox(height: ResponsiveUtils.getSpacing(context, size: 'lg')),
                
                // Show uploaded image if available
                if (_generatedInvitation!.imageUrl != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Visitor Image',
                          style: ResponsiveUtils.getBodyStyle(context)
                              .copyWith(fontWeight: FontWeight.bold),
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
                  SizedBox(height: ResponsiveUtils.getSpacing(context, size: 'md')),
                ],
                
                _buildInvitationDetails(),
              ],
            ),
          ),
        ),
        
        SizedBox(height: ResponsiveUtils.getSpacing(context, size: 'lg')),
        
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _generatedInvitation = null;
                    _resetForm();
                  });
                },
                child: const Text('Generate Another'),
              ),
            ),
            SizedBox(width: ResponsiveUtils.getSpacing(context, size: 'md')),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInvitationDetails() {
    return Container(
      padding: ResponsiveUtils.getResponsivePadding(context),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Invitation Details',
            style: ResponsiveUtils.getBodyStyle(context)
                .copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: ResponsiveUtils.getSpacing(context, size: 'sm')),
          
          _buildDetailRow('Purpose', _generatedInvitation!.purpose),
          _buildDetailRow('Max Visitors', '${_generatedInvitation!.maxVisitors}'),
          _buildDetailRow('Valid From', _formatDateTime(_generatedInvitation!.validFrom)),
          _buildDetailRow('Valid Until', _formatDateTime(_generatedInvitation!.validUntil)),
          
          if (_generatedInvitation!.notes?.isNotEmpty == true)
            _buildDetailRow('Notes', _generatedInvitation!.notes!),
          
          if (_generatedInvitation!.imageUrl != null)
            _buildDetailRow('Image', 'Included'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveUtils.getSpacing(context, size: 'xs')),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: ResponsiveUtils.getCaptionStyle(context)
                  .copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: ResponsiveUtils.getCaptionStyle(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateTime(BuildContext context, bool isFrom) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isFrom ? _validFrom : _validUntil,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(isFrom ? _validFrom : _validUntil),
      );

      if (time != null) {
        final dateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        setState(() {
          if (isFrom) {
            _validFrom = dateTime;
            if (_validUntil.isBefore(_validFrom)) {
              _validUntil = _validFrom.add(const Duration(hours: 1));
            }
          } else {
            if (dateTime.isAfter(_validFrom)) {
              _validUntil = dateTime;
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('End time must be after start time'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        });
      }
    }
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

  Future<void> _generateQRInvitation() async {
    if (!_formKey.currentState!.validate()) return;

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

      final invitation = await QRService.generateQRInvitation(
        hostId: user.uid,
        hostName: user.name,
        flatNo: user.flatNo ?? '',
        purpose: _selectedPurpose == 'Other' ? _purposeController.text.trim() : _selectedPurpose!,
        validFrom: _validFrom,
        validUntil: _validUntil,
        maxVisitors: int.parse(_maxVisitorsController.text),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
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

  void _resetForm() {
    _selectedPurpose = null;
    _purposeController.clear();
    _notesController.clear();
    _maxVisitorsController.text = '1';
    _validFrom = DateTime.now();
    _validUntil = DateTime.now().add(const Duration(hours: 24));
    _selectedImage = null;
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}