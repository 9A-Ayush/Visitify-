import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final areaController = TextEditingController();
  final blockController = TextEditingController();
  String? selectedRole;
  String? selectedServiceType;
  bool isLoading = false;
  bool isPasswordVisible = false;

  final List<String> serviceTypes = [
    'Plumbing',
    'Electrical',
    'Automobile Repair',
    'Grocery Shop',
    'Fruit Seller',
    'Medical Store',
    'Vegetable Seller',
  ];

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    areaController.dispose();
    blockController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate() || selectedRole == null) return;
    setState(() => isLoading = true);
    try {
      String flatNo = '';
      String societyId = '';
      if (selectedRole == 'resident') {
        // Resident: create user with profileComplete: false, status: pending, then go to add_home
        final cred = await AuthService().registerWithSelfSignup(
          email: emailController.text.trim(),
          password: passwordController.text,
          name: nameController.text.trim(),
          phone: phoneController.text.trim(),
          role: selectedRole!,
          flatNo: '',
          societyId: '',
        );
        final uid = cred.user!.uid;
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'profileComplete': false,
          'status': 'pending',
        });
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/add_home');
        setState(() => isLoading = false);
        return;
      }
      // For guard, area/block can be stored similarly
      await AuthService().registerWithSelfSignup(
        email: emailController.text.trim(),
        password: passwordController.text,
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
        role: selectedRole!,
        flatNo: flatNo,
        societyId: societyId,
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/profile_completion');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _registerWithGoogle() async {
    if (selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a role first'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      final credential = await AuthService().registerWithGoogle(
        role: selectedRole!,
      );

      if (credential == null) {
        if (mounted) {
          setState(() => isLoading = false);
        }
        return;
      }

      if (!mounted) return;

      // Route based on role
      if (selectedRole == 'resident') {
        Navigator.pushReplacementNamed(context, '/add_home');
      } else {
        Navigator.pushReplacementNamed(context, '/profile_completion');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google registration failed: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
    if (mounted) {
      setState(() => isLoading = false);
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
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  
                  // Header
                  _buildHeader(),
                  
                  const SizedBox(height: 40),
                  
                  // Welcome section
                  _buildWelcomeSection(),
                  
                  const SizedBox(height: 32),
                  
                  // Registration form
                  _buildRegistrationForm(),
                  
                  const SizedBox(height: 32),
                  
                  // Register button
                  _buildRegisterButton(),
                  
                  const SizedBox(height: 20),
                  
                  // Divider
                  _buildDivider(),
                  
                  const SizedBox(height: 20),
                  
                  // Google sign-up
                  _buildGoogleSignUp(),
                  
                  const SizedBox(height: 32),
                  
                  // Login link
                  _buildLoginLink(),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Create Account',
          style: AppTheme.headingMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Join Visitify',
          style: AppTheme.headingLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Create your account to start managing your smart community',
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildRegistrationForm() {
    return Column(
      children: [
        // Role selection
        DropdownButtonFormField<String>(
          value: selectedRole,
          decoration: AppTheme.inputDecoration(
            labelText: 'Select Role',
            prefixIcon: const Icon(Icons.person_outline),
          ),
          items: ['resident', 'admin', 'guard']
              .map((role) => DropdownMenuItem(
                    value: role,
                    child: Text(role.capitalize()),
                  ))
              .toList(),
          onChanged: (val) => setState(() => selectedRole = val),
          validator: (val) => val == null ? 'Please select a role' : null,
        ),
        
        const SizedBox(height: 20),
        
        // Name field
        TextFormField(
          controller: nameController,
          decoration: AppTheme.inputDecoration(
            labelText: 'Full Name',
            hintText: 'Enter your full name',
            prefixIcon: const Icon(Icons.person),
          ),
          validator: (val) => val == null || val.isEmpty ? 'Enter your name' : null,
        ),
        
        const SizedBox(height: 20),
        
        // Email field
        TextFormField(
          controller: emailController,
          decoration: AppTheme.inputDecoration(
            labelText: 'Email Address',
            hintText: 'Enter your email address',
            prefixIcon: const Icon(Icons.email_outlined),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (val) => val == null || !val.contains('@') ? 'Enter valid email' : null,
        ),
        
        const SizedBox(height: 20),
        
        // Phone field
        TextFormField(
          controller: phoneController,
          decoration: AppTheme.inputDecoration(
            labelText: 'Phone Number',
            hintText: 'Enter your phone number',
            prefixIcon: const Icon(Icons.phone_outlined),
          ),
          keyboardType: TextInputType.phone,
          validator: (val) => val == null || val.length < 10 ? 'Enter valid phone number' : null,
        ),
        
        const SizedBox(height: 20),
        
        // Password field
        TextFormField(
          controller: passwordController,
          obscureText: !isPasswordVisible,
          decoration: AppTheme.inputDecoration(
            labelText: 'Password',
            hintText: 'Create a strong password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: AppTheme.textSecondary,
              ),
              onPressed: () => setState(() => isPasswordVisible = !isPasswordVisible),
            ),
          ),
          validator: (val) => val == null || val.length < 6 ? 'Password must be at least 6 characters' : null,
        ),
        
        // Role-specific fields
        if (selectedRole == 'guard') ...[
          const SizedBox(height: 20),
          TextFormField(
            controller: areaController,
            decoration: AppTheme.inputDecoration(
              labelText: 'Area',
              hintText: 'Enter your assigned area',
              prefixIcon: const Icon(Icons.location_on_outlined),
            ),
            validator: (val) => val == null || val.isEmpty ? 'Enter area' : null,
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: blockController,
            decoration: AppTheme.inputDecoration(
              labelText: 'Building/Block',
              hintText: 'Enter building or block',
              prefixIcon: const Icon(Icons.apartment_outlined),
            ),
            validator: (val) => val == null || val.isEmpty ? 'Enter building/block' : null,
          ),
        ],
      ],
    );
  }

  Widget _buildRegisterButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: AppTheme.buttonRadius,
        boxShadow: AppTheme.buttonShadow,
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : _register,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: AppTheme.buttonRadius,
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Create Account',
                style: AppTheme.bodyLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: Colors.grey.shade300,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.grey.shade300,
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleSignUp() {
    return Container(
      height: 56,
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : _registerWithGoogle,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppTheme.surface,
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: AppTheme.buttonRadius,
          ),
        ),
        icon: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Center(
            child: Text(
              'G',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        label: Text(
          'Sign up with Google',
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Text(
            'Sign In',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

extension StringCasingExtension on String {
  String capitalize() => '${this[0].toUpperCase()}${substring(1)}';
}