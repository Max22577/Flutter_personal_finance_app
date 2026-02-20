import 'package:flutter/material.dart';

class SettingItem {
  final String id;
  final String title;
  final String? subtitle;
  final IconData icon;
  final SettingType type;
  final dynamic value;
  final bool enabled;
  final Color? color;
  final Map<String, dynamic>? metadata;

  const SettingItem({
    required this.id,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.type,
    this.value,
    this.enabled = true,
    this.color,
    this.metadata,
  });
}

enum SettingType {
  navigation,    // Goes to another page
  toggle,        // Switch on/off
  selection,     // Choose from options
  slider,        // Numeric value with slider
  action,        // Performs immediate action
  destructive,   // Dangerous action (red)
  info,          // Display only, no action
}