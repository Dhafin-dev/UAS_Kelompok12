import 'package:flutter/material.dart';
import '../core/constants.dart';

class CustomRadioButton extends StatelessWidget {
  final String label;
  final double value;
  final List<RadioOption> options;
  final Function(double) onChanged;

  const CustomRadioButton({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontWeight: FontWeight.w500),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        child: Wrap(
          spacing: 12,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = value == option.value;
            return ChoiceChip(
              label: Text(option.label),
              selected: isSelected,
              showCheckmark: false,
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.primary : Colors.grey.shade300,
                width: isSelected ? 1.5 : 1.0,
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              onSelected: (_) => onChanged(option.value),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class RadioOption {
  final String label;
  final double value;

  const RadioOption({required this.label, required this.value});
}
