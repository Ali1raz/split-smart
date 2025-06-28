import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/date_formatter.dart';

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

      final filePath = await _exportTransactionToCsv(transaction);

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
                      'You can find this file in your device\'s Documents folder under "split_smart_transactions".',
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

  Future<String?> _exportTransactionToCsv(Map<String, dynamic> tx) async {
    final documentsPath = await _getDocumentsPath();
    final now = DateTime.now();
    final timestamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    final fileName = 'transaction-${tx['id'] ?? timestamp}-$timestamp.csv';
    final filePath = '$documentsPath/$fileName';

    final csvContent = _generateTransactionCsvContent(tx);
    final file = File(filePath);
    await file.writeAsString(csvContent, encoding: utf8);
    return filePath;
  }

  Future<String> _getDocumentsPath() async {
    if (Platform.isAndroid) {
      final directory = Directory(
        '/storage/emulated/0/Documents/split_smart_transactions',
      );
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      return directory.path;
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final subDir = Directory('${directory.path}/split_smart_transactions');
      if (!await subDir.exists()) {
        await subDir.create(recursive: true);
      }
      return subDir.path;
    }
  }

  String _generateTransactionCsvContent(Map<String, dynamic> tx) {
    final buffer = StringBuffer();
    buffer.writeln('SPLIT SMART - TRANSACTION EXPORT');
    buffer.writeln(
      'Exported: ${DateFormatter.formatFullDateTime(DateTime.now())}',
    );
    buffer.writeln();
    buffer.writeln('Transaction ID,${tx['id'] ?? '-'}');
    buffer.writeln('Type,${tx['transaction_type'] ?? '-'}');
    buffer.writeln(
      'Amount,Rs ${(tx['amount'] as num?)?.toStringAsFixed(2) ?? '-'}',
    );
    buffer.writeln('Title,${_escapeCsvField(tx['title'] ?? '-')}');
    buffer.writeln('Description,${_escapeCsvField(tx['description'] ?? '-')}');
    buffer.writeln(
      'Date/Time,${DateFormatter.formatFullDateTime(tx['created_at'])}',
    );
    buffer.writeln(
      'Balance Before,Rs ${(tx['balance_before'] as num?)?.toStringAsFixed(2) ?? '-'}',
    );
    buffer.writeln(
      'Balance After,Rs ${(tx['balance_after'] as num?)?.toStringAsFixed(2) ?? '-'}',
    );
    if (tx['expense_shares']?['expenses'] != null) {
      buffer.writeln(
        'Expense Title,${_escapeCsvField(tx['expense_shares']['expenses']['title'])}',
      );
    }
    if (tx['expense_shares']?['groups'] != null) {
      buffer.writeln(
        'Group,${_escapeCsvField(tx['expense_shares']['groups']['name'])}',
      );
    }
    buffer.writeln();
    return buffer.toString();
  }

  String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }
}
