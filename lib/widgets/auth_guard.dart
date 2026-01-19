import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthGuard extends StatefulWidget {
  final Widget child;
  
  const AuthGuard({super.key, required this.child});
  
  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  bool _isChecking = true;
  bool _isAuthenticated = false;
  
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }
  
  Future<void> _checkAuth() async {
    final isLoggedIn = await AuthService.isLoggedIn();
    
    if (mounted) {
      setState(() {
        _isAuthenticated = isLoggedIn;
        _isChecking = false;
      });
      
      if (!_isAuthenticated) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (!_isAuthenticated) {
      return const SizedBox.shrink();
    }
    
    return widget.child;
  }
}
