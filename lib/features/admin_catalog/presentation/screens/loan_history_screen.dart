import 'package:flutter/material.dart';

import '../../../../app/config.dart';
import '../../../../widgets/admin/overdue_indicator.dart';
import '../../data/models/loan.dart';
import '../../data/repositories/admin_loan_repository_impl.dart';
import '../../domain/repositories/admin_loan_repository.dart';
import '../widgets/admin_sidebar.dart';

/// T154 + T159 — Loan history with date-range filter.
///
/// Read-only screen; no Bloc needed because filter state is form-local and
/// data is fetched once per filter change. Wraps `AdminLoanRepository`
/// directly (constructor accepts a repo for tests).
class LoanHistoryScreen extends StatefulWidget {
  const LoanHistoryScreen({super.key, this.repository});

  final AdminLoanRepository? repository;

  @override
  State<LoanHistoryScreen> createState() => _LoanHistoryScreenState();
}

class _LoanHistoryScreenState extends State<LoanHistoryScreen> {
  late final AdminLoanRepository _repo;

  DateTime? _from;
  DateTime? _to;

  bool _loading = true;
  String? _error;
  List<Loan> _loans = const [];

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ??
        AdminLoanRepositoryImpl(baseUrl: AppConfig.apiBaseUrl);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final loans = await _repo.fetchHistory(from: _from, to: _to);
      if (!mounted) return;
      setState(() {
        _loans = loans;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is LoanOperationException ? e.message : e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = (isFrom ? _from : _to) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _from = picked;
      } else {
        _to = picked;
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _from = null;
      _to = null;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('대출 내역'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '새로고침',
            onPressed: _load,
          ),
        ],
      ),
      drawer: const AdminSidebar(currentRoute: '/admin/loans/history'),
      body: Column(
        children: [
          _FilterBar(
            from: _from,
            to: _to,
            onPickFrom: () => _pickDate(isFrom: true),
            onPickTo: () => _pickDate(isFrom: false),
            onApply: _from == null && _to == null ? null : _load,
            onClear: (_from == null && _to == null) ? null : _clearFilters,
          ),
          const Divider(height: 1),
          Expanded(child: _resultBody()),
        ],
      ),
    );
  }

  Widget _resultBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('다시 시도')),
            ],
          ),
        ),
      );
    }
    if (_loans.isEmpty) {
      return const Center(child: Text('해당 기간에 대출 내역이 없습니다.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _loans.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) => _HistoryRow(loan: _loans[i]),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.from,
    required this.to,
    required this.onPickFrom,
    required this.onPickTo,
    required this.onApply,
    required this.onClear,
  });

  final DateTime? from;
  final DateTime? to;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;
  final VoidCallback? onApply;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text('시작: ${_formatDate(from)}'),
            onPressed: onPickFrom,
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.event, size: 18),
            label: Text('종료: ${_formatDate(to)}'),
            onPressed: onPickTo,
          ),
          FilledButton.tonal(
            onPressed: onApply,
            child: const Text('적용'),
          ),
          TextButton(
            onPressed: onClear,
            child: const Text('전체'),
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.loan});
  final Loan loan;

  @override
  Widget build(BuildContext context) {
    final bookTitle = loan.book?.title ?? loan.bookId;
    final studentName =
        loan.student?.fullName ?? loan.student?.username ?? loan.studentId;
    final returnedSuffix = loan.returnedDate != null
        ? '· 반납 ${_formatDate(loan.returnedDate!)}'
        : '· 미반납';
    return ListTile(
      title: Row(
        children: [
          Expanded(
            child: Text(bookTitle, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          OverdueIndicator(
            dueDate: loan.dueDate,
            isOverdue: loan.isOverdue,
          ),
        ],
      ),
      subtitle: Text(
        '$studentName · 대출 ${_formatDate(loan.checkoutDate)} '
        '· 만기 ${_formatDate(loan.dueDate)} $returnedSuffix',
      ),
      trailing: _StatusChip(status: loan.status),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final LoanStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (Color bg, Color fg, String label) = switch (status) {
      LoanStatus.active => (
          theme.colorScheme.secondaryContainer,
          theme.colorScheme.onSecondaryContainer,
          '진행 중',
        ),
      LoanStatus.overdue => (
          theme.colorScheme.errorContainer,
          theme.colorScheme.onErrorContainer,
          '연체',
        ),
      LoanStatus.returned => (
          theme.colorScheme.surfaceContainerHighest,
          theme.colorScheme.onSurface,
          '반납',
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(color: fg, fontSize: 12)),
    );
  }
}

String _formatDate(DateTime? d) {
  if (d == null) return '미선택';
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
