import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../services/auth.dart';
import '../services/balance_service.dart';
import '../widgets/stats_card.dart';
import '../widgets/stat_item.dart';
import '../widgets/profile_card.dart';
import '../widgets/details_modal.dart';
import '../widgets/pie_chart_widget.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with TickerProviderStateMixin {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final BalanceService _balanceService = BalanceService();

  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _expenseShares = [];
  List<Map<String, dynamic>> _createdExpenses = [];
  List<Map<String, dynamic>> _groups = [];
  Map<String, dynamic>? _balanceStats;
  bool _isLoading = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final futures = await Future.wait([
        _authService.getUserProfile(),
        _chatService.getUserExpenseShares(),
        _chatService.getUserCreatedExpenses(),
        _chatService.getUserGroupsWithDetails(),
        _balanceService.getBalanceStatistics(),
      ]);

      if (mounted) {
        setState(() {
          _profile = futures[0] as Map<String, dynamic>;
          _expenseShares = futures[1] as List<Map<String, dynamic>>;
          _createdExpenses = futures[2] as List<Map<String, dynamic>>;
          _groups = futures[3] as List<Map<String, dynamic>>;
          _balanceStats = futures[4] as Map<String, dynamic>;
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading stats: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showExpenseDetailsModal(
    String title,
    List<Map<String, dynamic>> expenses,
  ) {
    final totalAmount = expenses.fold(
      0.0,
      (sum, expense) =>
          sum + (expense['amount_owed'] ?? expense['total_amount'] ?? 0),
    );

    final expenseItems =
        expenses.map((expense) {
          final amount = expense['amount_owed'] ?? expense['total_amount'] ?? 0;
          final expenseName = expense['expense_name'] ?? 'Unknown Expense';
          final groupName = expense['group_name'] ?? 'Unknown Group';
          final isPaid = expense['is_paid'] ?? false;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isPaid
                          ? Colors.green
                          : Theme.of(context).colorScheme.primary)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isPaid ? Icons.check_circle : Icons.receipt,
                  color:
                      isPaid
                          ? Colors.green
                          : Theme.of(context).colorScheme.primary,
                  size: 18,
                ),
              ),
              title: Text(
                expenseName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    groupName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (isPaid ? Colors.green : Colors.orange).withValues(
                        alpha: 0.1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isPaid ? 'Paid' : 'Pending',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isPaid ? Colors.green : Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Rs ${amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
          );
        }).toList();

    showDetailsModal(
      context,
      title: title,
      subtitle: '${expenses.length} expense${expenses.length != 1 ? 's' : ''}',
      totalAmount: 'Rs ${totalAmount.toStringAsFixed(2)}',
      icon: Icons.receipt_long,
      children: expenseItems,
      isEmpty: expenses.isEmpty,
      emptyTitle: 'No expenses found',
      emptySubtitle: 'There are no expenses in this category yet',
      emptyIcon: Icons.inbox_outlined,
    );
  }

  void _showGroupDetailsModal(String title, List<Map<String, dynamic>> groups) {
    final activeGroups = groups.where((group) => _isGroupActive(group)).length;

    final groupItems =
        groups.map((group) {
          final groupName = group['name'] ?? 'Unknown Group';
          final isActive = _isGroupActive(group);
          final memberCount = group['member_count'] ?? 0;

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(14),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isActive ? Colors.green : Colors.grey).withValues(
                    alpha: 0.1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isActive ? Icons.chat : Icons.group,
                  color: isActive ? Colors.green : Colors.grey,
                  size: 18,
                ),
              ),
              title: Text(
                groupName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Text(
                    '$memberCount member${memberCount != 1 ? 's' : ''}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (isActive ? Colors.green : Colors.grey).withValues(
                        alpha: 0.1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isActive ? Colors.green : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              trailing:
                  isActive
                      ? Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.circle,
                          color: Colors.green,
                          size: 12,
                        ),
                      )
                      : null,
            ),
          );
        }).toList();

    showDetailsModal(
      context,
      title: title,
      subtitle:
          '${groups.length} group${groups.length != 1 ? 's' : ''} • $activeGroups active',
      totalAmount:
          groups.isNotEmpty
              ? '${(activeGroups / groups.length * 100).toStringAsFixed(0)}%'
              : '0%',
      icon: Icons.group,
      children: groupItems,
      isEmpty: groups.isEmpty,
      emptyTitle: 'No groups found',
      emptySubtitle: 'There are no groups in this category yet',
      emptyIcon: Icons.group_outlined,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Statistics',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body:
          _isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: theme.colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Loading statistics...',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadData,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ProfileCard(profile: _profile),
                        const SizedBox(height: 20),
                        _buildExpensePieChart(theme),
                        const SizedBox(height: 20),
                        PieChartWidget(
                          data: [
                            ChartDataItem(
                              label: 'Paid',
                              value:
                                  _expenseShares
                                      .where((share) => share['is_paid'])
                                      .length
                                      .toDouble(),
                              color: Colors.green,
                              icon: Icons.check_circle,
                            ),
                            ChartDataItem(
                              label: 'Pending',
                              value:
                                  _expenseShares
                                      .where((share) => !share['is_paid'])
                                      .length
                                      .toDouble(),
                              color: Colors.orange,
                              icon: Icons.pending,
                            ),
                          ],
                          title: 'Expense Shares',
                          subtitle: 'Paid vs Pending',
                          size: 120,
                          onTap: () {
                            final totalExpenses = _expenseShares.length;
                            final paidExpenses =
                                _expenseShares
                                    .where((share) => share['is_paid'])
                                    .length;
                            final pendingExpenses =
                                totalExpenses - paidExpenses;
                            final paymentRate =
                                totalExpenses > 0
                                    ? (paidExpenses / totalExpenses * 100)
                                    : 0.0;
                            final allExpenseSharesForModal =
                                _expenseShares
                                    .map(
                                      (share) => {
                                        'expense_name':
                                            share['expenses']?['title'] ??
                                            'Unknown Expense',
                                        'group_name':
                                            share['expenses']?['groups']?['name'] ??
                                            'Unknown Group',
                                        'amount_owed': share['amount_owed'],
                                        'is_paid': share['is_paid'],
                                      },
                                    )
                                    .toList();
                            final paidExpenseList =
                                allExpenseSharesForModal
                                    .where((share) => share['is_paid'])
                                    .toList();
                            final pendingExpenseList =
                                allExpenseSharesForModal
                                    .where((share) => !share['is_paid'])
                                    .toList();
                            showDetailsModal(
                              context,
                              title: 'Expense Shares',
                              subtitle: 'Breakdown of your expense shares',
                              totalAmount: totalExpenses.toString(),
                              icon: Icons.pie_chart,
                              children: [
                                StatItem(
                                  label: 'Total Shares',
                                  value: totalExpenses.toString(),
                                  icon: Icons.list,
                                  color: Theme.of(context).colorScheme.tertiary,
                                  onTap:
                                      () => _showExpenseDetailsModal(
                                        'All Expense Shares',
                                        allExpenseSharesForModal,
                                      ),
                                ),
                                StatItem(
                                  label: 'Payment Rate',
                                  value: '${paymentRate.toStringAsFixed(1)}%',
                                  icon: Icons.trending_up,
                                  color: Theme.of(context).colorScheme.primary,
                                  onTap: null,
                                ),
                                StatItem(
                                  label: 'Paid',
                                  value: paidExpenses.toString(),
                                  icon: Icons.check_circle,
                                  color: Colors.green,
                                  onTap:
                                      () => _showExpenseDetailsModal(
                                        'Paid Expenses',
                                        paidExpenseList,
                                      ),
                                ),
                                StatItem(
                                  label: 'Pending',
                                  value: pendingExpenses.toString(),
                                  icon: Icons.pending,
                                  color: Colors.orange,
                                  onTap:
                                      () => _showExpenseDetailsModal(
                                        'Pending Expenses',
                                        pendingExpenseList,
                                      ),
                                ),
                              ],
                              isEmpty: totalExpenses == 0,
                              emptyTitle: 'No expense shares found',
                              emptySubtitle: 'You have no expense shares yet',
                              emptyIcon: Icons.inbox_outlined,
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        PieChartWidget(
                          data: [
                            ChartDataItem(
                              label: 'Average',
                              value:
                                  _expenseShares.isNotEmpty
                                      ? (_expenseShares.fold(
                                                0.0,
                                                (sum, share) =>
                                                    sum +
                                                    (share['amount_owed']
                                                        as num),
                                              ) /
                                              _expenseShares.length)
                                          .roundToDouble()
                                      : 0.0,
                              color: theme.colorScheme.primary,
                              icon: Icons.calculate,
                            ),
                            ChartDataItem(
                              label: 'Maximum',
                              value:
                                  _expenseShares.isNotEmpty
                                      ? _expenseShares.fold(
                                        0.0,
                                        (max, share) =>
                                            (share['amount_owed'] as num) > max
                                                ? (share['amount_owed'] as num)
                                                    .toDouble()
                                                : max,
                                      )
                                      : 0.0,
                              color: theme.colorScheme.error,
                              icon: Icons.trending_up,
                            ),
                          ],
                          title: 'Payment Details',
                          subtitle: 'Average vs Maximum Amount',
                          size: 120,
                          onTap: () {
                            final avgAmountOwed =
                                _expenseShares.isNotEmpty
                                    ? (_expenseShares.fold(
                                              0.0,
                                              (sum, share) =>
                                                  sum +
                                                  (share['amount_owed'] as num),
                                            ) /
                                            _expenseShares.length)
                                        .roundToDouble()
                                    : 0.0;
                            final maxAmountOwed =
                                _expenseShares.isNotEmpty
                                    ? _expenseShares.fold(
                                      0.0,
                                      (max, share) =>
                                          (share['amount_owed'] as num) > max
                                              ? (share['amount_owed'] as num)
                                                  .toDouble()
                                              : max,
                                    )
                                    : 0.0;
                            showDetailsModal(
                              context,
                              title: 'Payment Details',
                              subtitle: 'Amount statistics',
                              totalAmount:
                                  'Rs ${(avgAmountOwed + maxAmountOwed).toStringAsFixed(2)}',
                              icon: Icons.payment,
                              children: [
                                StatItem(
                                  label: 'Average Amount',
                                  value:
                                      'Rs ${avgAmountOwed.toStringAsFixed(2)}',
                                  icon: Icons.calculate,
                                  color: theme.colorScheme.primary,
                                  onTap: null,
                                ),
                                StatItem(
                                  label: 'Maximum Amount',
                                  value:
                                      'Rs ${maxAmountOwed.toStringAsFixed(2)}',
                                  icon: Icons.trending_up,
                                  color: theme.colorScheme.error,
                                  onTap: null,
                                ),
                              ],
                              isEmpty: _expenseShares.isEmpty,
                              emptyTitle: 'No payment data',
                              emptySubtitle: 'You have no expense shares yet',
                              emptyIcon: Icons.payment_outlined,
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildTransactionStats(theme),
                        const SizedBox(height: 20),
                        _buildPaymentStatusPieChart(theme),
                        const SizedBox(height: 32),
                        _buildGroupActivityPieChart(theme),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  Widget _buildExpensePieChart(ThemeData theme) {
    final totalOwed = _expenseShares
        .where((share) => !share['is_paid'])
        .fold(0.0, (sum, share) => sum + (share['amount_owed'] as num));

    final totalPaid = _expenseShares
        .where((share) => share['is_paid'])
        .fold(0.0, (sum, share) => sum + (share['amount_owed'] as num));

    final totalCreated = _createdExpenses.fold(
      0.0,
      (sum, expense) => sum + (expense['total_amount'] as num),
    );

    // Transform expense shares to include expense details for modals
    final owedExpenses =
        _expenseShares
            .where((share) => !share['is_paid'])
            .map(
              (share) => {
                'expense_name':
                    share['expenses']?['title'] ?? 'Unknown Expense',
                'group_name':
                    share['expenses']?['groups']?['name'] ?? 'Unknown Group',
                'amount_owed': share['amount_owed'],
                'is_paid': share['is_paid'],
              },
            )
            .toList();

    final paidExpenses =
        _expenseShares
            .where((share) => share['is_paid'])
            .map(
              (share) => {
                'expense_name':
                    share['expenses']?['title'] ?? 'Unknown Expense',
                'group_name':
                    share['expenses']?['groups']?['name'] ?? 'Unknown Group',
                'amount_owed': share['amount_owed'],
                'is_paid': share['is_paid'],
              },
            )
            .toList();

    // Transform created expenses for modal
    final createdExpensesForModal =
        _createdExpenses
            .map(
              (expense) => {
                'expense_name': expense['title'] ?? 'Unknown Expense',
                'group_name': expense['groups']?['name'] ?? 'Unknown Group',
                'total_amount': expense['total_amount'],
                'is_paid':
                    true, // Created expenses are considered "paid" by creator
              },
            )
            .toList();

    return PieChartWidget(
      data: [
        ChartDataItem(
          label: 'Owed',
          value: totalOwed,
          color: theme.colorScheme.error,
          icon: Icons.account_balance_wallet,
        ),
        ChartDataItem(
          label: 'Paid',
          value: totalPaid,
          color: theme.colorScheme.primary,
          icon: Icons.check_circle,
        ),
        ChartDataItem(
          label: 'Created',
          value: totalCreated,
          color: theme.colorScheme.secondary,
          icon: Icons.add_circle,
        ),
      ],
      title: 'Expense Overview',
      subtitle: 'Distribution of your expenses',
      size: 120,
      onTap: () {
        showDetailsModal(
          context,
          title: 'Expense Overview',
          subtitle: 'Detailed breakdown of your expenses',
          icon: Icons.pie_chart,
          children: [
            StatItem(
              label: 'Total Owed',
              value: 'Rs ${totalOwed.toStringAsFixed(2)}',
              icon: Icons.account_balance_wallet,
              color: theme.colorScheme.error,
              onTap:
                  () => _showExpenseDetailsModal(
                    'Expenses You Owe',
                    owedExpenses,
                  ),
            ),
            StatItem(
              label: 'Total Paid',
              value: 'Rs ${totalPaid.toStringAsFixed(2)}',
              icon: Icons.check_circle,
              color: theme.colorScheme.primary,
              onTap:
                  () => _showExpenseDetailsModal(
                    'Expenses You Paid',
                    paidExpenses,
                  ),
            ),
            StatItem(
              label: 'Total Created',
              value: 'Rs ${totalCreated.toStringAsFixed(2)}',
              icon: Icons.add_circle,
              color: theme.colorScheme.secondary,
              onTap:
                  () => _showExpenseDetailsModal(
                    'Expenses You Created',
                    createdExpensesForModal,
                  ),
            ),
          ],
          isEmpty: false,
          totalAmount:
              'Rs ${(totalOwed + totalPaid + totalCreated).toStringAsFixed(2)}',
          emptyTitle: 'No expenses found',
          emptySubtitle: 'You haven\'t recorded any expenses yet',
          emptyIcon: Icons.receipt_outlined,
        );
      },
    );
  }

  Widget _buildTransactionStats(ThemeData theme) {
    if (_balanceStats == null) {
      return const SizedBox.shrink();
    }

    final thisMonthAdded =
        (_balanceStats!['this_month_added'] as num?)?.toDouble() ?? 0.0;
    final thisMonthSpent =
        (_balanceStats!['this_month_spent'] as num?)?.toDouble() ?? 0.0;
    final lastMonthAdded =
        (_balanceStats!['last_month_added'] as num?)?.toDouble() ?? 0.0;
    final lastMonthSpent =
        (_balanceStats!['last_month_spent'] as num?)?.toDouble() ?? 0.0;
    final outstandingLoan =
        (_balanceStats!['outstanding_loan'] as num?)?.toDouble() ?? 0.0;
    final totalLoans =
        (_balanceStats!['total_loans'] as num?)?.toDouble() ?? 0.0;
    final totalRepaid =
        (_balanceStats!['total_repaid'] as num?)?.toDouble() ?? 0.0;

    // Calculate monthly percentages
    final monthlyIncome = thisMonthAdded;
    final monthlyOutflow = thisMonthSpent;
    final monthlySavingsRate =
        monthlyIncome > 0
            ? ((monthlyIncome - monthlyOutflow) / monthlyIncome * 100)
            : 0.0;

    // Calculate monthly changes
    final monthlyAddedChange =
        lastMonthAdded > 0
            ? ((thisMonthAdded - lastMonthAdded) / lastMonthAdded * 100)
            : 0.0;
    final monthlySpentChange =
        lastMonthSpent > 0
            ? ((thisMonthSpent - lastMonthSpent) / lastMonthSpent * 100)
            : 0.0;

    // Calculate loan statistics
    final overallRepaymentRate =
        totalLoans > 0 ? (totalRepaid / totalLoans * 100) : 0.0;

    return StatsCard(
      title: 'Transactions',
      color: theme.colorScheme.tertiary,
      children: [
        StatItem(
          label: 'Added This Month',
          value: 'Rs ${thisMonthAdded.toStringAsFixed(2)}',
          icon: Icons.add_circle,
          color: Colors.green,
          onTap: null,
        ),
        StatItem(
          label: 'Spent This Month',
          value: 'Rs ${thisMonthSpent.toStringAsFixed(2)}',
          icon: Icons.remove_circle,
          color: Colors.red,
          onTap: null,
        ),
        StatItem(
          label: 'Monthly Savings Rate',
          value: '${monthlySavingsRate.toStringAsFixed(1)}%',
          icon: Icons.trending_up,
          color: monthlySavingsRate >= 0 ? Colors.green : Colors.red,
          onTap: null,
        ),
        if (monthlyAddedChange != 0) ...[
          StatItem(
            label: 'Added vs Last Month',
            value:
                '${monthlyAddedChange >= 0 ? '+' : ''}${monthlyAddedChange.toStringAsFixed(1)}%',
            icon: Icons.trending_up,
            color: monthlyAddedChange >= 0 ? Colors.green : Colors.red,
            onTap: null,
          ),
        ],
        if (monthlySpentChange != 0) ...[
          StatItem(
            label: 'Spent vs Last Month',
            value:
                '${monthlySpentChange >= 0 ? '+' : ''}${monthlySpentChange.toStringAsFixed(1)}%',
            icon: Icons.trending_down,
            color: monthlySpentChange <= 0 ? Colors.green : Colors.red,
            onTap: null,
          ),
        ],
        if (totalLoans > 0) ...[
          StatItem(
            label: 'Total Loans Taken',
            value: 'Rs ${totalLoans.toStringAsFixed(2)}',
            icon: Icons.credit_card,
            color: theme.colorScheme.error,
            onTap: null,
          ),
          StatItem(
            label: 'Total Repaid',
            value: 'Rs ${totalRepaid.toStringAsFixed(2)}',
            icon: Icons.check_circle,
            color: Colors.green,
            onTap: null,
          ),
          StatItem(
            label: 'Overall Repayment Rate',
            value: '${overallRepaymentRate.toStringAsFixed(1)}%',
            icon: Icons.percent,
            color: overallRepaymentRate >= 80 ? Colors.green : Colors.orange,
            onTap: null,
          ),
        ],
        if (outstandingLoan > 0) ...[
          StatItem(
            label: 'Outstanding Loan',
            value: 'Rs ${outstandingLoan.toStringAsFixed(2)}',
            icon: Icons.warning_amber,
            color: theme.colorScheme.error,
            onTap: null,
          ),
        ],
      ],
    );
  }

  bool _isGroupActive(Map<String, dynamic> group) {
    final lastMessage = group['last_message'];
    if (lastMessage == null) return false;

    try {
      final messageTime = DateTime.parse(lastMessage['created_at']);
      final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
      return messageTime.isAfter(oneWeekAgo);
    } catch (e) {
      return false;
    }
  }

  Widget _buildPaymentStatusPieChart(ThemeData theme) {
    final paidExpenses =
        _expenseShares.where((share) => share['is_paid']).length;
    final pendingExpenses =
        _expenseShares.where((share) => !share['is_paid']).length;

    final chartData = <ChartDataItem>[
      if (paidExpenses > 0)
        ChartDataItem(
          label: 'Paid',
          value: paidExpenses.toDouble(),
          color: Colors.green,
          icon: Icons.check_circle,
        ),
      if (pendingExpenses > 0)
        ChartDataItem(
          label: 'Pending',
          value: pendingExpenses.toDouble(),
          color: Colors.orange,
          icon: Icons.pending,
        ),
    ];

    return PieChartWidget(
      data: chartData,
      title: 'Payment Status',
      subtitle: 'Distribution of expense payments',
      centerText: 'Total',
      size: 120,
      onTap: () {
        final total = paidExpenses + pendingExpenses;
        if (total > 0) {
          showDetailsModal(
            context,
            title: 'Payment Status',
            subtitle: 'Breakdown of expense payment status',
            totalAmount: total.toString(),
            icon: Icons.payment,
            children: [
              if (paidExpenses > 0)
                _buildPaymentBreakdownItem(
                  'Paid',
                  paidExpenses,
                  total,
                  Colors.green,
                  Icons.check_circle,
                ),
              if (pendingExpenses > 0)
                _buildPaymentBreakdownItem(
                  'Pending',
                  pendingExpenses,
                  total,
                  Colors.orange,
                  Icons.pending,
                ),
            ],
            isEmpty: chartData.isEmpty,
            emptyTitle: 'No expenses found',
            emptySubtitle: 'You haven\'t recorded any expenses yet',
            emptyIcon: Icons.receipt_outlined,
          );
        }
      },
    );
  }

  Widget _buildGroupActivityPieChart(ThemeData theme) {
    final activeGroups = _groups.where((group) => _isGroupActive(group)).length;
    final inactiveGroups =
        _groups.where((group) => !_isGroupActive(group)).length;

    final chartData = <ChartDataItem>[
      if (activeGroups > 0)
        ChartDataItem(
          label: 'Active',
          value: activeGroups.toDouble(),
          color: Colors.green,
          icon: Icons.chat,
        ),
      if (inactiveGroups > 0)
        ChartDataItem(
          label: 'Inactive',
          value: inactiveGroups.toDouble(),
          color: Colors.grey,
          icon: Icons.group,
        ),
    ];

    return PieChartWidget(
      data: chartData,
      title: 'Group Activity',
      subtitle: 'Distribution of group activity',
      centerText: 'Groups',
      size: 120,
      onTap: () {
        _showGroupDetailsModal('All Groups', _groups);
      },
    );
  }

  Widget _buildPaymentBreakdownItem(
    String label,
    int value,
    int total,
    Color color,
    IconData icon,
  ) {
    final percentage = total > 0 ? (value / total * 100) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$value expenses (${percentage.toStringAsFixed(1)}%)',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
