import 'package:flutter/material.dart';

import 'roamly_text_form_field.dart';

final class RoamlyPasswordFormField extends StatefulWidget {
  const RoamlyPasswordFormField({
    super.key,
    required this.controller,
    required this.showPasswordTooltip,
    required this.hidePasswordTooltip,
    this.label,
    this.hint,
    this.errorText,
    this.focusNode,
    this.textInputAction,
    this.autofillHints = const [AutofillHints.password],
    this.prefixIcon,
    this.enabled = true,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String showPasswordTooltip;
  final String hidePasswordTooltip;
  final String? label;
  final String? hint;
  final String? errorText;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final Widget? prefixIcon;
  final bool enabled;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  State<RoamlyPasswordFormField> createState() {
    return _RoamlyPasswordFormFieldState();
  }
}

final class _RoamlyPasswordFormFieldState
    extends State<RoamlyPasswordFormField> {
  bool _isPasswordVisible = false;

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RoamlyTextFormField(
      controller: widget.controller,
      label: widget.label,
      hint: widget.hint,
      errorText: widget.errorText,
      focusNode: widget.focusNode,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      prefixIcon: widget.prefixIcon,
      obscureText: !_isPasswordVisible,
      enabled: widget.enabled,
      autocorrect: false,
      enableSuggestions: false,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted,
      suffixIcon: IconButton(
        onPressed: widget.enabled ? _togglePasswordVisibility : null,
        tooltip: _isPasswordVisible
            ? widget.hidePasswordTooltip
            : widget.showPasswordTooltip,
        icon: Icon(
          _isPasswordVisible
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
        ),
      ),
    );
  }
}
