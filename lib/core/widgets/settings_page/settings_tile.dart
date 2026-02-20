import 'package:flutter/material.dart';
import '../../../models/setting_item.dart';

class SettingsTile extends StatelessWidget {
  final SettingItem item;
  final VoidCallback? onTap;

  const SettingsTile({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(item.icon, color: Theme.of(context).colorScheme.primary),
      title: Text(item.title, style: Theme.of(context).textTheme.bodyLarge),
      subtitle: item.subtitle != null ? Text(item.subtitle!) : null,
      trailing: item.type == SettingType.navigation 
          ? const Icon(Icons.chevron_right, size: 20) 
          : null,
      onTap: onTap,
    );
  }
}