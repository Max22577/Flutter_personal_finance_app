import 'package:flutter/material.dart';
import '../../../models/setting_item.dart';


class DestructiveTile extends StatelessWidget {
  final SettingItem item;
  final VoidCallback? onTap;

  const DestructiveTile({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(item.icon, color: Theme.of(context).colorScheme.error),
      title: Text(item.title, 
        style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.bold)),
      subtitle: item.subtitle != null ? Text(item.subtitle!) : null,
      onTap: onTap,
    );
  }
}