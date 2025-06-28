import 'package:flutter/material.dart';
import '../services/transaction_export_service.dart';

class SaveTransactionButton extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final VoidCallback? onSaveComplete;
  final String? customLabel;
  final IconData? customIcon;
  final bool isCompact;

  const SaveTransactionButton({
    super.key,
    required this.transaction,
    this.onSaveComplete,
    this.customLabel,
    this.customIcon,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isCompact) {
      return IconButton(
        onPressed: () => _saveTransaction(context),
        icon: Icon(customIcon ?? Icons.save_alt, color: Colors.white, size: 20),
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: () => _saveTransaction(context),
      icon: Icon(customIcon ?? Icons.save_alt),
      label: Text(customLabel ?? 'Save Transaction'),
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _saveTransaction(BuildContext context) async {
    final exportService = TransactionExportService();

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => AlertDialog(
              contentPadding: const EdgeInsets.all(20),
              content: SizedBox(
                width: double.maxFinite,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Saving transaction...',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      );

      final filePath = await exportService.exportTransactionToCsv(transaction);

      Navigator.of(context).pop();

      if (filePath != null) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Save Successful'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Transaction has been saved to:'),
                    const SizedBox(height: 8),
                    Text(
                      filePath,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You can find this file in your device\'s Documents folder under "split_smart_expenses/transactions".',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
        onSaveComplete?.call();
      }
    } catch (e) {
      Navigator.of(context).pop();
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Save Failed'),
              content: Text('Error saving transaction: $e'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    }
  }
}
