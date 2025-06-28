import 'package:flutter/material.dart';
import '../services/balance_service.dart';
import '../utils/date_formatter.dart';
import 'balance_transaction_detail_screen.dart';

class AllBalanceTransactionsScreen extends StatefulWidget {
  const AllBalanceTransactionsScreen({Key? key}) : super(key: key);

  @override
  State<AllBalanceTransactionsScreen> createState() =>
      _AllBalanceTransactionsScreenState();
}

class _AllBalanceTransactionsScreenState
    extends State<AllBalanceTransactionsScreen>
    with SingleTickerProviderStateMixin {
  final BalanceService _balanceService = BalanceService();
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTransactions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final txs = await _balanceService.getTransactionHistory();
      setState(() {
        _transactions = txs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'add':
        return Icons.add_circle_outline;
      case 'spend':
        return Icons.remove_circle_outline;
      case 'loan':
        return Icons.credit_card;
      case 'repay':
        return Icons.check_circle_outline;
      default:
        return Icons.swap_horiz;
    }
  }

  Color _colorForType(BuildContext context, String type) {
    switch (type) {
      case 'add':
        return Colors.green;
      case 'spend':
        return Colors.red;
      case 'loan':
        return Theme.of(context).colorScheme.error;
      case 'repay':
        return Colors.blue;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  List<Map<String, dynamic>> _filteredTransactions(int tabIndex) {
    if (tabIndex == 1) {
      // Spendings: spend, loan, repay
      return _transactions
          .where(
            (tx) =>
                tx['transaction_type'] == 'spend' ||
                tx['transaction_type'] == 'loan' ||
                tx['transaction_type'] == 'repay',
          )
          .toList();
    }
    // All Payments: all
    return _transactions;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Balance Transactions'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'All Payments'), Tab(text: 'Spendings')],
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(child: Text('Error: $_error'))
              : _transactions.isEmpty
              ? const Center(child: Text('No transactions found.'))
              : TabBarView(
                controller: _tabController,
                children: List.generate(2, (tabIndex) {
                  final filtered = _filteredTransactions(tabIndex);
                  if (filtered.isEmpty) {
                    return const Center(child: Text('No transactions found.'));
                  }
                  return RefreshIndicator(
                    onRefresh: _loadTransactions,
                    child: ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder:
                          (context, i) => const Divider(height: 0),
                      itemBuilder: (context, i) {
                        final tx = filtered[i];
                        final type = tx['transaction_type'] as String? ?? '';
                        final amount =
                            (tx['amount'] as num?)?.toDouble() ?? 0.0;
                        final title = tx['title'] as String? ?? '';
                        final desc = tx['description'] as String? ?? '';
                        final date = tx['created_at'] as String?;
                        return ListTile(
                          leading: Icon(
                            _iconForType(type),
                            color: _colorForType(context, type),
                          ),
                          title: Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${type[0].toUpperCase()}${type.substring(1)} | ${DateFormatter.formatFullDateTime(date)}',
                              ),
                              if (desc.isNotEmpty)
                                Text(
                                  desc,
                                  style: const TextStyle(fontSize: 12),
                                ),
                            ],
                          ),
                          trailing: Text(
                            '${type == 'spend' || type == 'loan' ? '-' : '+'}Rs ${amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: _colorForType(context, type),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => BalanceTransactionDetailScreen(
                                      transaction: tx,
                                    ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  );
                }),
              ),
    );
  }
}
