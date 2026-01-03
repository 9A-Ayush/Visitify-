import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/cloudinary_service.dart';
import '../../theme/app_theme.dart';

class GuardVisitorLogScreen extends StatefulWidget {
  const GuardVisitorLogScreen({Key? key}) : super(key: key);

  @override
  State<GuardVisitorLogScreen> createState() => _GuardVisitorLogScreenState();
}

class _GuardVisitorLogScreenState extends State<GuardVisitorLogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _purposeController = TextEditingController();
  
  File? _selectedImage;
  bool _isLoading = false;
  bool _isLoadingFlats = true;
  String _selectedVehicleType = 'None';
  String? _selectedFlat;
  List<String> _flatNumbers = [];
  bool _useManualEntry = false;
  final _manualFlatController = TextEditingController();

  final List<String> _vehicleTypes = ['None', 'Car', 'Bike', 'Bicycle', 'Auto', 'Taxi'];
  final List<String> _purposes = [
    'Personal Visit',
    'Delivery',
    'Service/Repair',
    'Medical',
    'Business',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _loadFlatNumbers();
  }

  Future<void> _loadFlatNumbers() async {
    try {
      // Fetch all residents with their flat numbers
      // Remove status filter to show all residents (including pending)
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'resident')
          .get();

      print('DEBUG: Found ${snapshot.docs.length} residents');

      final flats = snapshot.docs
          .map((doc) {
            final data = doc.data();
            final flatNo = data['flatNo'] as String?;
            print('DEBUG: Resident ${data['name']} - Flat: $flatNo');
            return flatNo;
          })
          .where((flat) => flat != null && flat.isNotEmpty)
          .cast<String>() // Cast to non-nullable String
          .toSet() // Remove duplicates
          .toList();

      flats.sort(); // Sort alphabetically

      print('DEBUG: Final flat list: $flats');

      setState(() {
        _flatNumbers = flats;
        _isLoadingFlats = false;
      });

      if (flats.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No flat numbers found. Please add residents first.'),
            backgroundColor: AppTheme.warning,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('DEBUG: Error loading flats: $e');
      setState(() => _isLoadingFlats = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading flat numbers: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
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
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 
                          MediaQuery.of(context).padding.top,
              ),
              child: IntrinsicHeight(
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
                              'Log Visitor Entry',
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
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header
                              _buildCard(
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.person_add, 
                                        size: 48, 
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Visitor Entry Form',
                                      style: AppTheme.headingMedium,
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Fill in visitor details for entry log',
                                      style: AppTheme.bodyMedium.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Visitor Photo
                              _buildCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.camera_alt, color: AppTheme.primary, size: 20),
                                        const SizedBox(width: 8),
                                        Text('Visitor Photo', style: AppTheme.headingSmall),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Center(
                                      child: GestureDetector(
                                        onTap: _pickImage,
                                        child: Container(
                                          width: 140,
                                          height: 140,
                                          decoration: BoxDecoration(
                                            color: AppTheme.background,
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: AppTheme.primary.withOpacity(0.3),
                                              width: 2,
                                            ),
                                            boxShadow: AppTheme.cardShadow,
                                          ),
                                          child: _selectedImage != null
                                              ? ClipRRect(
                                                  borderRadius: BorderRadius.circular(14),
                                                  child: Image.file(_selectedImage!, fit: BoxFit.cover),
                                                )
                                              : Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.camera_alt, 
                                                      size: 32, 
                                                      color: AppTheme.primary,
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      'Tap to capture',
                                                      style: AppTheme.bodySmall.copyWith(
                                                        color: AppTheme.textSecondary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Visitor Details
                              _buildCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.person, color: AppTheme.primary, size: 20),
                                        const SizedBox(width: 8),
                                        Text('Visitor Details', style: AppTheme.headingSmall),
                                      ],
                                    ),
                                    const SizedBox(height: 20),

                                    // Name
                                    _buildTextField(
                                      controller: _nameController,
                                      label: 'Visitor Name *',
                                      icon: Icons.person,
                                      validator: (v) => v?.isEmpty == true ? 'Please enter name' : null,
                                    ),
                                    const SizedBox(height: 16),

                                    // Phone
                                    _buildTextField(
                                      controller: _phoneController,
                                      label: 'Phone Number *',
                                      icon: Icons.phone,
                                      keyboard: TextInputType.phone,
                                      maxLength: 10,
                                      validator: (v) {
                                        if (v == null || v.isEmpty) {
                                          return 'Please enter phone number';
                                        }
                                        if (v.length != 10) {
                                          return 'Phone number must be exactly 10 digits';
                                        }
                                        if (!RegExp(r'^[0-9]+$').hasMatch(v)) {
                                          return 'Phone number must contain only digits';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // Flat - Dropdown or Manual Entry
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Toggle between dropdown and manual entry
                                        if (!_isLoadingFlats && _flatNumbers.isNotEmpty)
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              Text(
                                                'Manual Entry',
                                                style: AppTheme.bodySmall.copyWith(
                                                  color: AppTheme.textSecondary,
                                                ),
                                              ),
                                              Switch(
                                                value: _useManualEntry,
                                                onChanged: (v) {
                                                  setState(() {
                                                    _useManualEntry = v;
                                                    if (v) {
                                                      _selectedFlat = null;
                                                    } else {
                                                      _manualFlatController.clear();
                                                    }
                                                  });
                                                },
                                                activeColor: AppTheme.primary,
                                              ),
                                            ],
                                          ),
                                        
                                        // Loading state
                                        if (_isLoadingFlats)
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: AppTheme.background,
                                              borderRadius: AppTheme.inputRadius,
                                              border: Border.all(
                                                color: Colors.grey.shade300,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Text(
                                                  'Loading flat numbers...',
                                                  style: AppTheme.bodyMedium.copyWith(
                                                    color: AppTheme.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        // Manual entry or no flats available
                                        else if (_useManualEntry || _flatNumbers.isEmpty)
                                          _buildTextField(
                                            controller: _manualFlatController,
                                            label: 'Visiting Flat *',
                                            icon: Icons.home,
                                            hint: 'e.g., A-101, B-205',
                                            validator: (v) => v?.isEmpty == true 
                                                ? 'Please enter flat number' 
                                                : null,
                                          )
                                        // Dropdown
                                        else
                                          DropdownButtonFormField<String>(
                                            value: _selectedFlat,
                                            decoration: AppTheme.inputDecoration(
                                              labelText: 'Visiting Flat *',
                                              prefixIcon: const Icon(Icons.home),
                                            ),
                                            hint: const Text('Select flat number'),
                                            items: _flatNumbers
                                                .map((flat) => DropdownMenuItem(
                                                      value: flat,
                                                      child: Text(flat),
                                                    ))
                                                .toList(),
                                            onChanged: (v) => setState(() => _selectedFlat = v),
                                            validator: (v) => v == null
                                                ? 'Please select visiting flat'
                                                : null,
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),

                                    // Purpose
                                    DropdownButtonFormField<String>(
                                      value: _purposeController.text.isEmpty ? null : _purposeController.text,
                                      decoration: AppTheme.inputDecoration(
                                        labelText: 'Purpose of Visit *',
                                        prefixIcon: const Icon(Icons.info),
                                      ),
                                      items: _purposes.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                                      onChanged: (v) => _purposeController.text = v ?? '',
                                      validator: (v) => v == null ? 'Please select purpose' : null,
                                    ),
                                    const SizedBox(height: 16),

                                    // Vehicle
                                    DropdownButtonFormField<String>(
                                      value: _selectedVehicleType,
                                      decoration: AppTheme.inputDecoration(
                                        labelText: 'Vehicle Type',
                                        prefixIcon: const Icon(Icons.directions_car),
                                      ),
                                      items: _vehicleTypes.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                                      onChanged: (v) => setState(() => _selectedVehicleType = v!),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Submit Button
                              Container(
                                width: double.infinity,
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  borderRadius: AppTheme.buttonRadius,
                                  boxShadow: AppTheme.buttonShadow,
                                ),
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _submitVisitorEntry,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: AppTheme.buttonRadius,
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white, 
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          'LOG VISITOR ENTRY',
                                          style: AppTheme.bodyLarge.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.cardRadius,
        boxShadow: AppTheme.cardShadow,
      ),
      child: child,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboard,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: AppTheme.inputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
      ),
      keyboardType: keyboard,
      maxLength: maxLength,
      validator: validator,
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  Future<void> _submitVisitorEntry() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      String? imageUrl;
      if (_selectedImage != null) {
        print('DEBUG: Uploading image to Cloudinary...');
        imageUrl = await CloudinaryService.uploadImage(_selectedImage!, folder: 'visitors');
        print('DEBUG: Image uploaded. URL: $imageUrl');
        
        if (imageUrl == null || imageUrl.isEmpty) {
          print('DEBUG: Image upload failed - URL is null or empty');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Warning: Image upload failed. Visitor logged without photo.'),
              backgroundColor: AppTheme.warning,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        print('DEBUG: No image selected');
      }

      // Get flat number from either dropdown or manual entry
      final flatNumber = _useManualEntry || _flatNumbers.isEmpty
          ? _manualFlatController.text.trim().toUpperCase()
          : _selectedFlat;

      print('DEBUG: Saving visitor with photo_url: $imageUrl');
      
      final docRef = await FirebaseFirestore.instance.collection('visitors').add({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'visiting_flat': flatNumber,
        'purpose': _purposeController.text,
        'vehicle_type': _selectedVehicleType,
        'photo_url': imageUrl,
        'entry_time': FieldValue.serverTimestamp(),
        'status': 'pending',
        'logged_by': 'guard',
      });

      print('DEBUG: Visitor saved with ID: ${docRef.id}');
      
      // Verify the data was saved correctly
      final savedDoc = await docRef.get();
      final savedData = savedDoc.data();
      print('DEBUG: Saved data photo_url: ${savedData?['photo_url']}');

      _nameController.clear();
      _phoneController.clear();
      _purposeController.clear();
      _manualFlatController.clear();
      setState(() {
        _selectedImage = null;
        _selectedVehicleType = 'None';
        _selectedFlat = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            imageUrl != null && imageUrl.isNotEmpty
                ? 'Visitor entry logged successfully with photo!'
                : 'Visitor entry logged successfully (no photo)',
          ),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      print('DEBUG: Error in _submitVisitorEntry: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging visitor: $e'), backgroundColor: AppTheme.error),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _purposeController.dispose();
    _manualFlatController.dispose();
    super.dispose();
  }
}
