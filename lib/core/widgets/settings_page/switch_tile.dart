import 'package:flutter/material.dart';
import '../../../models/setting_item.dart';

class SwitchTile extends StatelessWidget {
  final SettingItem item;
  final ValueChanged<bool>? onChanged;

  const SwitchTile({super.key, required this.item, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(item.icon, color: Theme.of(context).colorScheme.primary),
      title: Text(item.title),
      subtitle: item.subtitle != null ? Text(item.subtitle!) : null,
      value: item.value ?? false,
      onChanged: onChanged,
      activeThumbColor: Theme.of(context).colorScheme.primary,
    );
  }
}