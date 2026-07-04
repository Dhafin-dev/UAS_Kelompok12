import 'package:flutter/material.dart';
import '../core/constants.dart';

class CustomSlider extends StatefulWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final Function(double) onChanged;

  const CustomSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  @override
  State<CustomSlider> createState() => _CustomSliderState();
}

class _CustomSliderState extends State<CustomSlider> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _formatValue(widget.value));
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        // When losing focus, ensure the text matches the current slider value
        _controller.text = _formatValue(widget.value);
      }
    });
  }

  @override
  void didUpdateWidget(CustomSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      final newText = _formatValue(widget.value);
      if (_controller.text != newText && !_focusNode.hasFocus) {
        _controller.text = newText;
      }
    }
  }

  String _formatValue(double val) {
    // If it's effectively an integer (e.g. 2.0), show as '2' or '2.0'
    // Let's use 1 decimal place to be consistent, but if user types '72' we don't want it to jump
    // We'll just show what they typed if they are focused, otherwise format to 1 decimal if needed
    // Actually, checking if divisions allow integers
    if (val == val.roundToDouble()) {
      return val.toInt().toString();
    }
    return val.toStringAsFixed(1);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                ),
              ),
              SizedBox(
                width: 70,
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  onSubmitted: (val) {
                    double? parsed = double.tryParse(val);
                    if (parsed != null) {
                      if (parsed < widget.min) parsed = widget.min;
                      if (parsed > widget.max) parsed = widget.max;
                      widget.onChanged(parsed);
                      _controller.text = _formatValue(parsed);
                    } else {
                      _controller.text = _formatValue(widget.value);
                    }
                  },
                ),
              ),
            ],
          ),
          Slider(
            value: widget.value,
            min: widget.min,
            max: widget.max,
            divisions: widget.divisions,
            activeColor: AppColors.primary,
            label: _formatValue(widget.value),
            onChanged: (val) {
              if (!_focusNode.hasFocus) {
                _controller.text = _formatValue(val);
              }
              widget.onChanged(val);
            },
          ),
        ],
      ),
    );
  }
}