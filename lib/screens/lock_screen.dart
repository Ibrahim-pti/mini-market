import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});
  @override
  State<LockScreen> createState() => _LockScreenState();
}
class _LockScreenState extends State<LockScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _hasError = false;
  bool _obscurePassword = true;
  void _login() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = _usernameController.text.trim();
    final pass = _passwordController.text;
    if (user.isEmpty || pass.isEmpty) {
      setState(() {
        _hasError = true;
      });
      return;
    }
    bool success = auth.authenticate(user, pass);
    if (!success) {
      setState(() {
        _hasError = true;
      });
    }
  }
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width > 800;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          if (isDesktop)
            Expanded(
              flex: 5,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppGradients.brand,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.shopping_cart_rounded,
                          size: 100,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'مارکێت گوڵینا',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              offset: Offset(0, 4),
                              blurRadius: 10,
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'باشترین سیستەم بۆ بەڕێوەبردنی مارکێتەکەت',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            flex: 4,
            child: Center(
              child: SingleChildScrollView(
                child: Container(
                  width: 450,
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 48 : 24,
                    vertical: 32,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!isDesktop) ...[
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.shopping_cart_rounded,
                              size: 48,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Center(
                          child: Text(
                            'مارکێت گوڵینا',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                      Text(
                        'چوونە ژوورەوە',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'تکایە ناوی بەکارهێنەر و پاسوۆرد داخڵ بکە',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.muted,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 48),
                      if (_hasError)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.rose.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.rose.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline_rounded, color: AppColors.rose),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'ناوی بەکارهێنەر یان پاسوۆرد هەڵەیە!',
                                  style: TextStyle(color: AppColors.rose),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_hasError) const SizedBox(height: 24),
                      TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'ناوی بەکارهێنەر',
                          prefixIcon: Icon(Icons.person_rounded, color: AppColors.primary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.primary, width: 2),
                          ),
                        ),
                        onSubmitted: (_) => _login(),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'پاسوۆرد',
                          prefixIcon: Icon(Icons.lock_rounded, color: AppColors.primary),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                              color: AppColors.inkSoft,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.primary, width: 2),
                          ),
                        ),
                        onSubmitted: (_) => _login(),
                      ),
                      const SizedBox(height: 48),
                      ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'چوونە ژوورەوە',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
