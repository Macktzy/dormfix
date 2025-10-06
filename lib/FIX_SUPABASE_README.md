Supabase wiring helper added.

What I changed:
- Added services/supabase_service.dart (a central wrapper to initialize Supabase and provide helpers).

Next steps you must perform:
1) Open lib/services/supabase_service.dart and replace the example URL/anon keys when you call SupabaseService.init.
2) Add supabase_flutter to pubspec.yaml dependencies:
   supabase_flutter: ^0.6.0

3) Ensure main.dart calls SupabaseService.init before runApp(). I attempted to insert this into these files:
   []

4) For each screen that needs Supabase access, import the service:
   import 'services/supabase_service.dart';
   then use SupabaseService().client or SupabaseService().signInEmail(...)

Automated modifications summary:
{
  "total_files_scanned": 24,
  "supabase_hit_files": 17,
  "supabase_hits_sample": [
    [
      "lib/main.dart",
      6
    ],
    [
      "lib/constants/supabase_config.dart",
      3
    ],
    [
      "lib/screens/admin/admin_chat_screen.dart",
      2
    ],
    [
      "lib/screens/admin/admin_home_screen.dart",
      1
    ],
    [
      "lib/screens/admin/admin_reports_screen.dart",
      1
    ],
    [
      "lib/screens/admin/admin_request_details_screen.dart",
      3
    ],
    [
      "lib/screens/admin/staff_management_screen.dart",
      2
    ],
    [
      "lib/screens/auth/login_screen.dart",
      6
    ],
    [
      "lib/screens/auth/splash_screen.dart",
      1
    ],
    [
      "lib/screens/auth/student_signup_screen.dart",
      2
    ],
    [
      "lib/screens/staff/staff_home_screen.dart",
      3
    ],
    [
      "lib/screens/student/my_requests_screen.dart",
      2
    ],
    [
      "lib/screens/student/student_chat_screen.dart",
      2
    ],
    [
      "lib/screens/student/student_home_screen.dart",
      1
    ],
    [
      "lib/screens/student/submit_request_screen.dart",
      1
    ],
    [
      "lib/services/database_service.dart",
      1
    ],
    [
      "lib/services/supabase_service.dart",
      5
    ]
  ],
  "files_sample": [
    "lib/main.dart",
    "lib/constants/app_constants.dart",
    "lib/constants/supabase_config.dart",
    "lib/models/message.dart",
    "lib/models/request.dart",
    "lib/models/staff.dart",
    "lib/models/student.dart",
    "lib/models/user.dart",
    "lib/screens/admin/admin_chat_screen.dart",
    "lib/screens/admin/admin_home_screen.dart",
    "lib/screens/admin/admin_reports_screen.dart",
    "lib/screens/admin/admin_request_details_screen.dart",
    "lib/screens/admin/staff_management_screen.dart",
    "lib/screens/auth/login_screen.dart",
    "lib/screens/auth/splash_screen.dart",
    "lib/screens/auth/student_signup_screen.dart",
    "lib/screens/staff/staff_home_screen.dart",
    "lib/screens/student/my_requests_screen.dart",
    "lib/screens/student/student_chat_screen.dart",
    "lib/screens/student/student_home_screen.dart",
    "lib/screens/student/submit_request_screen.dart",
    "lib/services/database_service.dart",
    "lib/services/supabase_service.dart",
    "lib/theme/app_theme.dart"
  ]
}