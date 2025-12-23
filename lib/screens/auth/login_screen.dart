import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../theme/admin_theme.dart';
import '../../providers/admin_auth_provider.dart';
import '../../widgets/common/animated_button.dart';
import '../../widgets/common/glass_card.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AdminAuthProvider>(context, listen: false);
    
    final success = await authProvider.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage ?? 'Login failed',
            style: AdminTheme.bodyMedium,
          ),
          backgroundColor: AdminTheme.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
          ),
        ),
      );
    }
  }

  Future<void> _handleForgotPassword() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter your email address first',
            style: AdminTheme.bodyMedium,
          ),
          backgroundColor: AdminTheme.warningOrange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
          ),
        ),
      );
      return;
    }

    final authProvider = Provider.of<AdminAuthProvider>(context, listen: false);
    
    final success = await authProvider.resetPassword(_emailController.text.trim());
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success 
              ? 'Password reset email sent successfully'
              : authProvider.errorMessage ?? 'Failed to send reset email',
            style: AdminTheme.bodyMedium,
          ),
          backgroundColor: success ? AdminTheme.successGreen : AdminTheme.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AdminTheme.radiusSm),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AdminTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? AdminTheme.spacingLg : AdminTheme.spacingXl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo and title
                        _buildHeader(),
                        
                        const SizedBox(height: AdminTheme.spacing2Xl),
                        
                        // Login form
                        _buildLoginForm(),
                        
                        const SizedBox(height: AdminTheme.spacingXl),
                        
                        // Footer
                        _buildFooter(),
                      ],
                    ),
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
    return Column(
      children: [
        // Logo
        Hero(
          tag: 'admin_logo',
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: AdminTheme.primaryGradient,
              borderRadius: BorderRadius.circular(AdminTheme.radiusXl),
              boxShadow: AdminTheme.cardShadow,
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              size: 50,
              color: Colors.white,
            ),
          ),
        ),
        
        const SizedBox(height: AdminTheme.spacingLg),
        
        // Title
        Text(
          'Strame Admin Panel',
          style: AdminTheme.displaySmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: AdminTheme.spacingSm),
        
        Text(
          'High-Level Dashboard Access',
          style: AdminTheme.bodyLarge.copyWith(
            color: AdminTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Consumer<AdminAuthProvider>(
      builder: (context, authProvider, child) {
        return GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(AdminTheme.spacingXl),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Form title
                  Text(
                    'Admin Login',
                    style: AdminTheme.headlineMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: AdminTheme.spacingXl),
                  
                  // Email field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      hintText: 'Enter your admin email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email is required';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: AdminTheme.spacingLg),
                  
                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleLogin(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: AdminTheme.spacingMd),
                  
                  // Remember me and forgot password
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value ?? false;
                          });
                        },
                        activeColor: AdminTheme.primaryPurple,
                      ),
                      Expanded(
                        child: Text(
                          'Remember me',
                          style: AdminTheme.bodyMedium,
                        ),
                      ),
                      
                      TextButton(
                        onPressed: _handleForgotPassword,
                        child: Text(
                          'Forgot?',
                          style: AdminTheme.bodyMedium.copyWith(
                            color: AdminTheme.primaryPurple,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AdminTheme.spacingXl),
                  
                  // Login button
                  AnimatedButton(
                    onPressed: authProvider.isLoading ? null : _handleLogin,
                    child: authProvider.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Sign In',
                            style: AdminTheme.labelLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Text(
          '© 2024 Strame. All rights reserved.',
          style: AdminTheme.bodySmall.copyWith(
            color: AdminTheme.textTertiary,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: AdminTheme.spacingSm),
        
        Text(
          'Secure Admin Access Only',
          style: AdminTheme.labelSmall.copyWith(
            color: AdminTheme.textTertiary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
