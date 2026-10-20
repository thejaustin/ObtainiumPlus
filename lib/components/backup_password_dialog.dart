import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:obtainium/components/common/scale_touch_wrapper.dart';
import 'package:obtainium/utils/haptic_utils.dart';

/// Asks for a backup password. With [confirm], the password is entered twice
/// (used when turning encryption on). Returns null when cancelled.
Future<String?> showBackupPasswordDialog(
  BuildContext context, {
  bool confirm = false,
  String? message,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _BackupPasswordDialog(confirm: confirm, message: message),
  );
}

class _BackupPasswordDialog extends StatefulWidget {
  const _BackupPasswordDialog({required this.confirm, this.message});

  final bool confirm;
  final String? message;

  @override
  State<_BackupPasswordDialog> createState() => _BackupPasswordDialogState();
}

class _BackupPasswordDialogState extends State<_BackupPasswordDialog> {
  final _password = TextEditingController();
  final _repeat = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _repeat.dispose();
    super.dispose();
  }

  void _submit() {
    if (_password.text.isEmpty) return;
    if (widget.confirm && _password.text != _repeat.text) {
      setState(() => _error = tr('backupPasswordsDoNotMatch'));
      return;
    }
    Navigator.of(context).pop(_password.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.enhanced_encryption_outlined),
      title: Text(tr('backupPassword')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.message ??
                (widget.confirm
                    ? tr('backupPasswordHint')
                    : tr('enterBackupPassword')),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _password,
            obscureText: true,
            autofocus: true,
            decoration: InputDecoration(labelText: tr('backupPassword')),
            onSubmitted: (_) => widget.confirm ? null : _submit(),
          ),
          if (widget.confirm) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _repeat,
              obscureText: true,
              decoration: InputDecoration(
                labelText: tr('confirmBackupPassword'),
                errorText: _error,
              ),
              onSubmitted: (_) => _submit(),
            ),
          ],
        ],
      ),
      actions: [
        ScaleTouchWrapper(
          hapticOnPressDown: true,
          scaleDownFactor: 0.94,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(tr('cancel')),
          ),
        ),
        ScaleTouchWrapper(
          hapticOnPressDown: true,
          scaleDownFactor: 0.94,
          child: FilledButton(
            onPressed: () {
              AppHaptics.selectionClick();
              _submit();
            },
            child: Text(tr('ok')),
          ),
        ),
      ],
    );
  }
}
