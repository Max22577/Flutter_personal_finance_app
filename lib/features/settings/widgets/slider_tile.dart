import 'package:flutter/material.dart';
import '../../../models/setting_item.dart';

class SliderTile extends StatelessWidget {
  final SettingItem item;
  final ValueChanged<double>? onChanged;

  const SliderTile({super.key, required this.item, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: Icon(item.icon, color: Theme.of(context).colorScheme.primary),
          title: Text(item.title),
          trailing: Text('${item.value?.toInt() ?? 0}'),
        ),
        Slider(
          value: (item.value as num?)?.toDouble() ?? 0.0,
          min: 0,
          max: 1000, // Customise based on item.metadata if needed
          onChanged: onChanged,
        ),
      ],
    );
  }
}