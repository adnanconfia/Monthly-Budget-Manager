import 'package:flutter/material.dart';

IconData getIconFromString(String name) {
  switch (name) {
    case 'restaurant': return Icons.restaurant;
    case 'directions_car': return Icons.directions_car;
    case 'shopping_bag': return Icons.shopping_bag;
    case 'bolt': return Icons.bolt;
    case 'water_drop': return Icons.water_drop;
    case 'wifi': return Icons.wifi;
    case 'local_gas_station': return Icons.local_gas_station;
    case 'sports_esports': return Icons.sports_esports;
    case 'local_hospital': return Icons.local_hospital;
    case 'school': return Icons.school;
    case 'home': return Icons.home;
    case 'work': return Icons.work;
    case 'flight': return Icons.flight;
    case 'movie': return Icons.movie;
    case 'fitness_center': return Icons.fitness_center;
    default: return Icons.category;
  }
}

List<Map<String, dynamic>> getAvailableCustomIcons() {
  return [
    {'name': 'home', 'icon': Icons.home},
    {'name': 'work', 'icon': Icons.work},
    {'name': 'flight', 'icon': Icons.flight},
    {'name': 'movie', 'icon': Icons.movie},
    {'name': 'fitness_center', 'icon': Icons.fitness_center},
    {'name': 'restaurant', 'icon': Icons.restaurant},
    {'name': 'shopping_bag', 'icon': Icons.shopping_bag},
    {'name': 'directions_car', 'icon': Icons.directions_car},
  ];
}