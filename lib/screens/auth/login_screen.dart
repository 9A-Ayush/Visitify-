import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart' as my_auth;
import '../../route_helper.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/responsive_widgets.dart';
import '../../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  bool isPasswordVisible = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);
    try {
      await AuthService().signInWithEmail(
        emailController.text.trim(),
        passwordController.text,
      );

      if (!mounted) return;

      // Load user data after successful login
      final authProvider = Provider.of<my_auth.AuthProvider>(
        context,
        listen: false,
      );
      await authProvider.loadUser();

      if (!mounted) return;

      // Route user based on their profile
      RouteHelper.routeUser(
        context,
        authProvider.role ?? '',
        authProvider.isProfileComplete,
        status: authProvider.appUser?.status,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() => isLoading = true);
    try {
      await AuthService().signInWithGoogle();

      if (!mounted) return;

      final authProvider = Provider.of<my_auth.AuthProvider>(
        context,
        listen: false,
      );
      await authProvider.loadUser();

      if (!mounted) return;

      RouteHelper.routeUser(
        context,
        authProvider.role ?? '',
        authProvider.isProfileComplete,
        status: authProvider.appUser?.status,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google Sign-In failed: $e'),
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
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
              ),
              child: IntrinsicHeight(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),
                      
                      // Header with logo
                      _buildHeader(),
                      
                      const SizedBox(height: 60),
                      
                      // Welcome section
                      _buildWelcomeSection(),
                      
                      const SizedBox(height: 40),
                      
                      // Login form
                      _buildLoginForm(),
                      
                      const SizedBox(height: 32),
                      
                      // Login button
                      _buildLoginButton(),
                      
                      const SizedBox(height: 20),
                      
                      // Divider
                      _buildDivider(),
                      
                      const SizedBox(height: 20),
                      
                      // Google sign-in
                      _buildGoogleSignIn(),
                      
                      const Spacer(),
                      
                      // Sign up link
                      _buildSignUpLink(),
                      
                      const SizedBox(height: 20),
                      
                      // Legal text
                      _buildLegalText(),
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.home_outlined,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Visitify',
              style: AppTheme.headingMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        IconButton(
          onPressed: () {
            // TODO: Show help/info
          },
          icon: Icon(
            Icons.help_outline,
            color: AppTheme.textSecondary,
            size: 24,
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
          'Welcome Back',
          style: AppTheme.headingLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to your account to continue managing your smart community',
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        // Email field
        TextFormField(
          controller: emailController,
          decoration: AppTheme.inputDecoration(
            labelText: 'Email or Phone',
            hintText: 'Enter your email or phone number',
            prefixIcon: const Icon(Icons.person_outline),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (val) => val == null || val.isEmpty ? 'Enter email or phone' : null,
        ),
        
        const SizedBox(height: 20),
        
        // Password field
        TextFormField(
          controller: passwordController,
          obscureText: !isPasswordVisible,
          decoration: AppTheme.inputDecoration(
            labelText: 'Password',
            hintText: 'Enter your password',
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
        
        const SizedBox(height: 16),
        
        // Forgot password
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.pushNamed(context, '/forgot_password'),
            child: Text(
              'Forgot Password?',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: AppTheme.buttonRadius,
        boxShadow: AppTheme.buttonShadow,
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : _login,
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
                'Sign In',
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

  Widget _buildGoogleSignIn() {
    return Container(
      height: 56,
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : _googleSignIn,
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
          'Continue with Google',
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/register'),
          child: Text(
            'Sign Up',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegalText() {
    return Text(
      'By continuing, you agree to our Terms of Service and Privacy Policy.',
      textAlign: TextAlign.center,
      style: AppTheme.caption.copyWith(
        color: AppTheme.textSecondary,
        height: 1.4,
      ),
    );
  }
}