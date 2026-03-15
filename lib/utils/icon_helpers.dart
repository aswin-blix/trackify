import 'package:flutter/material.dart';

class IconHelpers {
  static const availableColors = [
    '#135bec', '#39ff14', '#ff7f50', '#a855f7', '#94a3b8',
    '#f59e0b', '#ef4444', '#06b6d4', '#f97316', '#ec4899',
  ];

  static const availableIcons = [
    'home', 'restaurant', 'directions_car', 'shopping_bag', 'category',
    'local_hospital', 'fitness_center', 'school', 'flight', 'movie',
    'pets', 'work', 'coffee', 'sports_esports', 'music_note',
  ];

  static IconData getIcon(String? code) {
    switch (code) {
      case 'home': return Icons.home;
      case 'restaurant': return Icons.restaurant;
      case 'directions_car': return Icons.directions_car;
      case 'shopping_bag': return Icons.shopping_bag;
      case 'local_hospital': return Icons.local_hospital;
      case 'fitness_center': return Icons.fitness_center;
      case 'school': return Icons.school;
      case 'flight': return Icons.flight;
      case 'movie': return Icons.movie;
      case 'pets': return Icons.pets;
      case 'work': return Icons.work;
      case 'coffee': return Icons.coffee;
      case 'sports_esports': return Icons.sports_esports;
      case 'music_note': return Icons.music_note;
      case 'payments': return Icons.payments;
      default: return Icons.category;
    }
  }

  static Color parseColor(String? colorCode) {
    final hexStr = colorCode?.replaceAll('#', '0xFF') ?? '0xFF94a3b8';
    return Color(int.parse(hexStr));
  }
}
