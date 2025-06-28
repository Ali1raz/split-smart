import 'package:flutter/material.dart';
import 'package:split_smart_supabase/utils/constants.dart';
import '../utils/date_formatter.dart';

class BalanceTransactionDetailScreen extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const BalanceTransactionDetailScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final tx = transaction;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('Transaction Details')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: [
            Text(
              AppConstants.getTransactionTypeLabel(tx['transaction_type']),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Amount: Rs ${(tx['amount'] as num?)?.toStringAsFixed(2) ?? '-'}',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (tx['title'] != null && tx['title'].toString().isNotEmpty)
              Text('Title: ${tx['title']}', style: theme.textTheme.bodyLarge),
            if (tx['expense_shares']?['expenses'] != null)
              Text(
                'Expense Title: ${tx['expense_shares']['expenses']['title']}',
                style: theme.textTheme.bodyLarge,
              ),
            if (tx['expense_shares']?['groups'] != null)
              Text(
                'Group: ${tx['expense_shares']['groups']['name']}',
                style: theme.textTheme.bodyLarge,
              ),
            const SizedBox(height: 8),
            Text(
              'Date/Time: ${DateFormatter.formatFullDateTime(tx['created_at'])}',
              style: theme.textTheme.bodyMedium,
            ),
            if (tx['description'] != null &&
                tx['description'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Description: ${tx['description']}',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'Balance Before: Rs ${(tx['balance_before'] as num?)?.toStringAsFixed(2) ?? '-'}',
              style: theme.textTheme.bodyMedium,
            ),
            Text(
              'Balance After: Rs ${(tx['balance_after'] as num?)?.toStringAsFixed(2) ?? '-'}',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
