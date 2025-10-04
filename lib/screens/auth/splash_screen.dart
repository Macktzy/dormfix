import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_constants.dart';
import '../admin/admin_home_screen.dart';
import '../staff/staff_home_screen.dart';
import '../student/student_home_screen.dart';
import 'login_screen.dart';
import '../../services/database_service.dart';

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
    final prefs = await SharedPreferences.getInstance();
    final userType = prefs.getString('user_type'); // e.g. "UserType.admin"
    final fullName = prefs.getString('full_name') ?? '';
    final studentId = prefs.getString('student_id') ?? '';
    final username = prefs.getString('username') ?? '';

    if (!mounted) return;

    if (userType == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
      return;
    }

    if (userType.contains('admin')) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
      );
    } else if (userType.contains('staff')) {
      // Fetch staff ID from database
      final allStaff = await DatabaseService.instance.getAllStaff();
      final staff = allStaff.firstWhere(
        (u) => u.username == username,
        orElse: () => throw Exception('Staff user not found'),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => StaffHomeScreen(
            staffId: staff.id!, // pass int ID
            staffUsername: staff.username, // for display in AppBar
          ),
        ),
      );
    } else {
      // default to student
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              StudentHomeScreen(studentId: studentId, fullName: fullName),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
