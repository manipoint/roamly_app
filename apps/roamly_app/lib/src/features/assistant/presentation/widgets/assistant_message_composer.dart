import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:roamly_app/src/features/assistant/domain/policies/assistant_policy.dart';
import 'package:roamly_app/src/localization/app_strings.dart';
import 'package:roamly_ui/roamly_ui.dart';

typedef AssistantMessageSubmitCallback = Future<bool> Function(String message);

final class AssistantMessageComposer extends StatefulWidget {
  const AssistantMessageComposer({
    super.key,
    required this.onSubmit,
    this.isSending = false,
    this.enabled = true,
    this.errorText,
  });
  final AssistantMessageSubmitCallback onSubmit;
  final bool isSending;
  final bool enabled;
  final String? errorText;

  @override
  State<AssistantMessageComposer> createState() =>
      _AssistantMessageComposerState();
}

final class _AssistantMessageComposerState
    extends State<AssistantMessageComposer> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _isSubmitting = false;
  bool get _isBusy => widget.isSending || _isSubmitting;
  bool get _canSubmit {
    return widget.enabled && !_isBusy && _controller.text.trim().isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_canSubmit) {
      return;
    }
    final message = _controller.text.trim();
    setState(() {
      _isSubmitting = true;
    });
    try {
      final submitted = await widget.onSubmit(message);
      if (!mounted || !submitted) return;
      _controller.clear();
      _focusNode.requestFocus();
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          RoamlySpacing.space16,
          RoamlySpacing.space8,
          RoamlySpacing.space16,
          RoamlySpacing.space12,
        ),
        child: ValueListenableBuilder<TextEditingValue>(
          valueListenable: _controller,
          builder: (_, value, _) {
            return Semantics(
              textField: true,
              label: AppStrings.assistantMessageHint,
              child: TextField(
                key: const ValueKey('assistant-message-field'),
                controller: _controller,
                focusNode: _focusNode,
                enabled: widget.enabled,
                readOnly: _isBusy,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                minLines: 1,
                maxLines: 5,
                autocorrect: true,
                enableSuggestions: true,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(
                    AssistantPolicy.maximumMessageLength,
                  ),
                ],
                decoration: InputDecoration(
                  hintText: AppStrings.assistantMessageHint,
                  errorText: widget.errorText,
                  suffixIcon: Padding(
                    padding: const EdgeInsets.all(RoamlySpacing.space4),
                    child: _isBusy
                        ? Padding(
                            padding: EdgeInsets.all(RoamlySpacing.space12),
                            child: Semantics(
                              label: AppStrings.assistantSendMessage,
                              child: SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator.adaptive(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          )
                        : IconButton.filled(
                            key: const ValueKey<String>(
                              'assistant-send-button',
                            ),
                            tooltip: AppStrings.assistantSendMessage,
                            onPressed: _canSubmit ? _submit : null,
                            icon: const Icon(Icons.arrow_upward_rounded),
                          ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
