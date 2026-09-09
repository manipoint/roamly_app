import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:roamly_ui/roamly_ui.dart';

import '../../../../localization/app_strings.dart';
import '../../domain/policies/location_resolution_policy.dart';

final class LocationSearchField extends StatelessWidget {
  const LocationSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    this.focusNode,
    this.isLoading = false,
    this.enabled = true,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool isLoading;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return RoamlyTextFormField(
          controller: controller,
          focusNode: focusNode,
          label: AppStrings.homeCity,
          hint: AppStrings.homeCityHint,
          enabled: enabled,
          keyboardType: TextInputType.streetAddress,
          textInputAction: TextInputAction.search,
          autocorrect: true,
          enableSuggestions: true,
          inputFormatters: [
            LengthLimitingTextInputFormatter(
              LocationResolutionPolicy.maximumQueryLength,
            ),
          ],
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _buildSuffix(hasText: value.text.isNotEmpty),
          onChanged: onChanged,
        );
      },
    );
  }

  Widget? _buildSuffix({required bool hasText}) {
    if (isLoading) {
      return Padding(
        padding: EdgeInsets.all(RoamlySpacing.space12),
        child: Semantics(
          label: AppStrings.searchingLocations,
          child: SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator.adaptive(strokeWidth: 2),
          ),
        ),
      );
    }

    if (!hasText) {
      return null;
    }

    return IconButton(
      key: const ValueKey<String>('location-search-clear'),
      tooltip: AppStrings.clearHomeCity,
      onPressed: () {
        controller.clear();
        onClear();
      },
      icon: const Icon(Icons.close),
    );
  }
}
