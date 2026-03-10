import 'package:flutter/material.dart';
import '../../../models/setting_item.dart';
import 'settings_tile.dart';
import 'switch_tile.dart';
import 'slider_tile.dart';
import 'destructive_tile.dart';

class SettingsSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<SettingItem> items;
  final void Function(SettingItem item, dynamic newValue)? onSettingChanged;
  final void Function(SettingItem item)? onSettingTapped;
  final bool showDivider;

  const SettingsSection({
    required this.title,
    this.subtitle,
    required this.items,
    this.onSettingChanged,
    this.onSettingTapped,
    this.showDivider = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Content Card
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                _buildItemTile(items[i]),
                if (i < items.length - 1 && showDivider)
                  const Divider(height: 1, indent: 16),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemTile(SettingItem item) {
    final onTap = onSettingTapped != null ? () => onSettingTapped!(item) : null;
    
    return switch (item.type) {
      SettingType.toggle => SwitchTile(
        item: item,
        onChanged: (bool val) => onSettingChanged?.call(item, val),
      ),
      SettingType.slider => SliderTile(
        item: item,
        onChanged: (double val) => onSettingChanged?.call(item, val),
      ),
      SettingType.destructive => DestructiveTile(
        item: item,
        onTap: onTap,
      ),
      _ => SettingsTile(
        item: item,
        onTap: onTap,
      ),
    };
  }
}