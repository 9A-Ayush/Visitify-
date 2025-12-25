import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/qr_service.dart';
import '../../services/visitor_service.dart';
import '../../models/qr_invitation.dart';
import '../../theme/app_theme.dart';

class GuardQRScannerScreen extends StatefulWidget {
  const GuardQRScannerScreen({Key? key}) : super(key: key);

  @override
  State<GuardQRScannerScreen> createState() => _GuardQRScannerScreenState();
}

class _GuardQRScannerScreenState extends State<GuardQRScannerScreen> {
  MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeScanner();
  }

  void _initializeScanner() async {
    try {
      // Start the scanner
      await controller.start();
    } catch (e) {
      debugPrint('Error initializing scanner: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to initialize camera: ${e.toString()}';
        });
      }
    }
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
                        'Scan QR Code',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: ValueListenableBuilder(
                            valueListenable: controller.torchState,
                            builder: (context, state, child) {
                              switch (state) {
                                case TorchState.off:
                                  return const Icon(Icons.flash_off, color: Colors.white70);
                                case TorchState.on:
                                  return const Icon(Icons.flash_on, color: Colors.yellow);
                              }
                            },
                          ),
                          onPressed: () => controller.toggleTorch(),
                        ),
                        IconButton(
                          icon: ValueListenableBuilder(
                            valueListenable: controller.cameraFacingState,
                            builder: (context, state, child) {
                              switch (state) {
                                case CameraFacing.front:
                                  return const Icon(Icons.camera_front, color: Colors.white);
                                case CameraFacing.back:
                                  return const Icon(Icons.camera_rear, color: Colors.white);
                              }
                            },
                          ),
                          onPressed: () => controller.switchCamera(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Scanner Area
              Expanded(
                flex: 3,
                child: Container(
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.primary.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: _hasError 
                      ? _buildErrorWidget()
                      : MobileScanner(
                          controller: controller,
                          onDetect: _onDetect,
                          errorBuilder: (context, error, child) {
                            return _buildErrorWidget(error.toString());
                          },
                        ),
                  ),
                ),
              ),
              
              // Instructions and Status
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isProcessing) ...[
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Processing QR Code...',
                          style: AppTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.qr_code_scanner,
                                size: 48,
                                color: AppTheme.primary,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Position QR code within the frame',
                                textAlign: TextAlign.center,
                                style: AppTheme.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                            
                            ],
                          ),
                        ),
                      ],
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

  void _onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (!_isProcessing && barcode.rawValue != null) {
        _processQRCode(barcode.rawValue!);
        break;
      }
    }
  }

  Future<void> _processQRCode(String qrData) async {
    if (_isProcessing) return;
    
    setState(() => _isProcessing = true);
    
    try {
      debugPrint('QR Data received: $qrData');
      
      // Parse QR data
      final parsedData = QRService.parseQRData(qrData);
      
      if (parsedData == null) {
        debugPrint('Failed to parse QR data');
        _showError('Invalid QR code format. Please scan a valid visitor invitation QR code.');
        return;
      }

      debugPrint('Parsed QR data: $parsedData');

      final invitationId = parsedData['invitation_id'] as String?;
      if (invitationId == null) {
        debugPrint('No invitation ID found in QR data');
        _showError('Invalid invitation ID in QR code');
        return;
      }

      debugPrint('Looking up invitation: $invitationId');

      // Get invitation details
      final invitation = await QRService.getQRInvitation(invitationId);
      
      if (invitation == null) {
        debugPrint('Invitation not found in database');
        _showError('Invitation not found. This QR code may be invalid or expired.');
        return;
      }

      debugPrint('Invitation found: ${invitation.hostName} - ${invitation.purpose}');

      if (!invitation.isValid) {
        debugPrint('Invitation is not valid: active=${invitation.isActive}, used=${invitation.usedCount}/${invitation.maxVisitors}');
        _showError('This invitation has expired or is no longer valid');
        return;
      }

      debugPrint('Invitation is valid, showing details');

      // Show invitation details
      if (mounted) {
        _showInvitationDetails(invitation);
      }
    } catch (e) {
      debugPrint('Error processing QR code: $e');
      _showError('Error processing QR code: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showInvitationDetails(QRInvitation invitation) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    bool isLoggingVisitor = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppTheme.cardRadius,
        ),
        title: Row(
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
            Expanded(
              child: Text(
                'Valid QR Invitation',
                style: AppTheme.headingSmall.copyWith(
                  color: AppTheme.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Show invitation image if available
              if (invitation.imageUrl != null) ...[
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
                          invitation.imageUrl!,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.person,
                                color: Colors.grey.shade400,
                                size: 50,
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
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Host', invitation.hostName),
                    _buildDetailRow('Flat No', invitation.flatNo),
                    _buildDetailRow('Purpose', invitation.purpose),
                    _buildDetailRow('Max Visitors', '${invitation.maxVisitors}'),
                    _buildDetailRow('Valid Until', _formatDateTime(invitation.validUntil)),
                    _buildDetailRow('Status', 'Auto-Approved'),
                    if (invitation.notes?.isNotEmpty == true)
                      _buildDetailRow('Notes', invitation.notes!),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.success.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.success, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This QR code is valid. Enter visitor details to log their entry.',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Visitor Information Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.primary.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person_add, color: AppTheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Visitor Information',
                          style: AppTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      decoration: AppTheme.inputDecoration(
                        labelText: 'Visitor Name',
                        hintText: 'Enter visitor\'s full name',
                        prefixIcon: const Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      decoration: AppTheme.inputDecoration(
                        labelText: 'Phone Number',
                        hintText: 'Enter visitor\'s phone number',
                        prefixIcon: const Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                       maxLength: 10,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                       buildCounter: (
                          context, {
                          required int currentLength,
                          required bool isFocused,
                          int? maxLength,
                        }) =>
                            null, // hides 0/10 counter
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: isLoggingVisitor ? null : () {
              Navigator.of(context).pop();
              // Resume scanning
              this.setState(() => _isProcessing = false);
            },
            child: Text(
              'Cancel',
              style: AppTheme.bodyMedium.copyWith(
                color: isLoggingVisitor ? Colors.grey : AppTheme.textSecondary,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ElevatedButton(
              onPressed: isLoggingVisitor ? null : () async {
                final name = nameController.text.trim();
                final phone = phoneController.text.trim();
                
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter visitor name'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                
                setState(() => isLoggingVisitor = true);
                
                try {
                  // Log visitor entry
                  await VisitorService.logVisitorFromQR(
                    qrInvitationId: invitation.id,
                    hostId: invitation.hostId,
                    hostName: invitation.hostName,
                    flatNo: invitation.flatNo,
                    purpose: invitation.purpose,
                    visitorName: name,
                    visitorPhone: phone,
                    imageUrl: invitation.imageUrl,
                  );
                  
                  // Mark QR invitation as used
                  await QRService.useQRInvitation(invitation.id);
                  
                  Navigator.of(context).pop(); // Close dialog
                  
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Visitor $name logged successfully!'),
                      backgroundColor: AppTheme.success,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                  
                  // Resume scanning after a delay
                  Future.delayed(const Duration(seconds: 2), () {
                    if (mounted) {
                      this.setState(() => _isProcessing = false);
                    }
                  });
                  
                } catch (e) {
                  setState(() => isLoggingVisitor = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error logging visitor: $e'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
              ),
              child: isLoggingVisitor
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Log Visitor Entry',
                      style: AppTheme.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
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

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
      
      // Resume scanning after showing error
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _isProcessing = false);
        }
      });
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildErrorWidget([String? error]) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.camera_alt_outlined,
            size: 64,
            color: AppTheme.error.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Text(
            'Camera Error',
            style: AppTheme.headingSmall.copyWith(
              color: AppTheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              error ?? _errorMessage ?? 'Unable to access camera. Please check permissions and try again.',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _retryCamera,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _retryCamera() async {
    setState(() {
      _hasError = false;
      _errorMessage = null;
    });
    
    try {
      // Recreate the controller
      controller.dispose();
      controller = MobileScannerController();
      await controller.start();
    } catch (e) {
      debugPrint('Error retrying camera: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to restart camera: ${e.toString()}';
        });
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}