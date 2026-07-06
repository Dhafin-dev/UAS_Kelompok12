import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomNumberInput extends StatelessWidget {
  final String label;
  final String? suffix;
  final String? hintText;
  final double? value;
  final Function(double) onChanged;
  final bool allowDecimal;

  const CustomNumberInput({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.suffix,
    this.hintText,
    this.allowDecimal = false,
  });

  @override
  Widget build(BuildContext context) {
    String displayValue = '';
    if (value != null) {
      if (allowDecimal) {
        displayValue = value == value!.roundToDouble()
            ? value!.toStringAsFixed(1)
            : value!.toStringAsFixed(2);
      } else {
        displayValue = value!.toInt().toString();
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        initialValue: displayValue,
        keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
        inputFormatters: [
          FilteringTextInputFormatter.allow(
            allowDecimal ? RegExp(r'^\d*\.?\d*') : RegExp(r'^\d*'),
          ),
        ],
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontWeight: FontWeight.w500),
          suffixText: suffix,
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        ),
        validator: (val) {
          if (val == null || val.isEmpty) {
            return '$label wajib diisi';
          }
          final parsed = double.tryParse(val);
          if (parsed == null || parsed <= 0) {
            return 'Masukkan angka yang valid';
          }
          return null;
        },
        onChanged: (val) {
          final parsed = double.tryParse(val);
          if (parsed != null) {
            onChanged(parsed);
          }
        },
      ),
    );
  }
}
