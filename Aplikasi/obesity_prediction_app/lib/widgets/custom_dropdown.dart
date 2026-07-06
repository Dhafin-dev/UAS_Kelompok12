import 'package:flutter/material.dart';

class CustomDropdown extends StatelessWidget {
  final String label;
  final double value;
  final List<DropdownMenuItem<double>> items;
  final Function(double?) onChanged;

  const CustomDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<double>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontWeight: FontWeight.w500),
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }
}
