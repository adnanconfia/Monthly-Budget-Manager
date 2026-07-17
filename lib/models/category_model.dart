import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String name;
  final String iconName;
  final int colorHex;

  CategoryModel({
    required this.id,
    required this.name,
    required this.iconName,
    required this.colorHex,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'iconName': iconName,
    'colorHex': colorHex,
  };

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
    id: json['id'] as String,
    name: json['name'] as String,
    iconName: json['iconName'] as String,
    colorHex: json['colorHex'] as int,
  );

  Color get color => Color(colorHex);
}