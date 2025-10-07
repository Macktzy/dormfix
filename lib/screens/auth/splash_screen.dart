import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_constants.dart';
import '../admin/admin_home_screen.dart';
import '../staff/staff_home_screen.dart';
import '../student/student_home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _routeUser();
  }

  Future<void> _routeUser() async {
    // Add small delay for splash effect
    await Future.delayed(const Duration(seconds: 1));

    final prefs = await SharedPreferences.getInstance();
    final userType = prefs.getString('user_type');
    final fullName = prefs.getString('full_name') ?? '';
    final studentId = prefs.getString('student_id') ?? '';
    final staffIdInt = prefs.getInt('staff_id'); // Get as int
    final username = prefs.getString('username') ?? '';

    if (!mounted) return;

    // No saved session, go to login
    if (userType == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    try {
      // Route based on user type
      if (userType == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
        );
      } else if (userType == 'staff') {
        if (staffIdInt == null) {
          // Session corrupted, go to login
          await prefs.clear();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
          return;
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => EnhancedStaffManagementScreen(
              staffUsername: username,
              staffId: staffIdInt, // use the int value
            ),
          ),
        );
      } else if (userType == 'student') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                StudentHomeScreen(studentId: studentId, fullName: fullName),
          ),
        );
      } else {
        // Unknown user type, go to login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      print('Error routing user: $e');
      // On error, go to login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.build,
                size: 60,
                color: AppConstants.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'DORM FIX',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Maintenance Request System',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}
