import 'package:flutter/material.dart';

class AppConstants {
  // App Colors
  static const primaryColor = Color(0xFF2196F3); // Blue
  static const secondaryColor = Color(0xFF03DAC6); // Teal
  static const errorColor = Color(0xFFB00020); // Red
  static const backgroundColor = Color(0xFFF5F5F5); // Light Gray

  // Problem Categories from your design
  static const List<String> problemCategories = [
    'Plumbing',
    'Electrical',
    'Furniture',
    'Internet',
    'Appliances',
    'Locks/Keys',
    'Walls/Floors/Ceilings',
    'Windows/Doors',
    'Others',
  ];

  // Urgency Levels
  static const List<String> urgencyLevels = ['Low', 'Medium', 'High'];

  // Status Types
  static const List<String> statusTypes = [
    'Submitted',
    'In Progress',
    'Completed',
  ];
}
