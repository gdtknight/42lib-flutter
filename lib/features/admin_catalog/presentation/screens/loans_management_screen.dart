import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/config.dart';
import '../../data/models/loan.dart';
import '../../data/repositories/admin_loan_repository_impl.dart';
import '../../domain/repositories/admin_loan_repository.dart';
import '../bloc/admin_loans_bloc.dart';
import '../bloc/admin_loans_event.dart';
import '../bloc/admin_loans_state.dart';
import '../widgets/admin_sidebar.dart';

class LoansManagementScreen extends StatelessWidget {
  const LoansManagementScreen({super.key, this.repository});

  final AdminLoanRepository? repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AdminLoansBloc>(
      create: (_) => AdminLoansBloc(
        repository: repository ??
            AdminLoanRepositoryImpl(baseUrl: AppConfig.apiBaseUrl),
      )..add(const AdminLoansRequested()),
      child: const _LoansView(),
    );
  }
}

class _LoansView extends StatelessWidget {
  const _LoansView();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('대출 관리'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: '새로고침',
              onPressed: () => context
                  .read<AdminLoansBloc>()
                  .add(const AdminLoansRequested()),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: '대기 요청'),
              Tab(text: '진행 중인 대출'),
            ],
          ),
        ),
        drawer: const AdminSidebar(currentRoute: '/admin/loans'),
        body: BlocConsumer<AdminLoansBloc, AdminLoansState>(
          listenWhen: (prev, next) =>
              next is AdminLoansLoaded &&
              next.actionMessage != null &&
              next.actionStatus != AdminLoanActionStatus.idle &&
              next.actionStatus != AdminLoanActionStatus.inProgress,
          listener: (context, state) {
            if (state is AdminLoansLoaded && state.actionMessage != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(state.actionMessage!)));
            }
          },
          builder: (context, state) {
            if (state is AdminLoansInitial || state is AdminLoansLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is AdminLoansError) {
              return _ErrorView(message: state.message);
            }
            final loaded = state as AdminLoansLoaded;
            return TabBarView(
              children: [
                _PendingTab(requests: loaded.pendingRequests),
                _ActiveTab(loans: loaded.activeLoans),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline,
              size: 48, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => context
                .read<AdminLoansBloc>()
                .add(const AdminLoansRequested()),
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}

class _PendingTab extends StatelessWidget {
  const _PendingTab({required this.requests});
  final List<AdminLoanRequest> requests;

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return const Center(child: Text('대기 중인 대출 요청이 없습니다.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) => _LoanRequestRow(request: requests[i]),
    );
  }
}

class _ActiveTab extends StatelessWidget {
  const _ActiveTab({required this.loans});
  final List<Loan> loans;

  @override
  Widget build(BuildContext context) {
    if (loans.isEmpty) {
      return const Center(child: Text('진행 중인 대출이 없습니다.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: loans.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) => _LoanRow(loan: loans[i]),
    );
  }
}

class _LoanRequestRow extends StatelessWidget {
  const _LoanRequestRow({required this.request});
  final AdminLoanRequest request;

  @override
  Widget build(BuildContext context) {
    final bookTitle = request.book?.title ?? request.bookId;
    final studentName = request.student?.fullName ??
        request.student?.username ??
        request.studentId;
    return ListTile(
      title: Text(bookTitle),
      subtitle: Text('$studentName · ${_formatDate(request.requestDate)}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: '승인',
            icon: const Icon(Icons.check_circle_outline, color: Colors.green),
            onPressed: () => _confirmApprove(context, request),
          ),
          IconButton(
            tooltip: '반려',
            icon: const Icon(Icons.cancel_outlined, color: Colors.red),
            onPressed: () => _confirmReject(context, request),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmApprove(
    BuildContext context,
    AdminLoanRequest request,
  ) async {
    final bloc = context.read<AdminLoansBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('대출 승인'),
        content: Text('"${request.book?.title ?? request.bookId}" 대출을 승인하시겠습니까?\n\n반납 기한: 14일 후'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('승인'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      bloc.add(AdminLoanApproveRequested(request.id));
    }
  }

  Future<void> _confirmReject(
    BuildContext context,
    AdminLoanRequest request,
  ) async {
    final bloc = context.read<AdminLoansBloc>();
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('대출 반려'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('"${request.book?.title ?? request.bookId}" 반려 사유를 입력하세요.'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '예: 동일 도서 미반납',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('취소'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
            ),
            onPressed: () {
              final value = controller.text.trim();
              if (value.isEmpty) return;
              Navigator.of(dialogContext).pop(value);
            },
            child: const Text('반려'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason != null && reason.isNotEmpty) {
      bloc.add(AdminLoanRejectRequested(request.id, reason));
    }
  }
}

class _LoanRow extends StatelessWidget {
  const _LoanRow({required this.loan});
  final Loan loan;

  @override
  Widget build(BuildContext context) {
    final bookTitle = loan.book?.title ?? loan.bookId;
    final studentName =
        loan.student?.fullName ?? loan.student?.username ?? loan.studentId;
    final daysLeft = loan.daysUntilDue(DateTime.now());
    final overdue = loan.isOverdue || daysLeft < 0;
    return ListTile(
      title: Text(bookTitle),
      subtitle: Text(
        '$studentName · 만기 ${_formatDate(loan.dueDate)} '
        '(${overdue ? '연체 ${-daysLeft}일' : 'D-$daysLeft'})',
        style: TextStyle(
          color: overdue ? Theme.of(context).colorScheme.error : null,
          fontWeight: overdue ? FontWeight.bold : null,
        ),
      ),
      trailing: IconButton(
        tooltip: '반납 처리',
        icon: const Icon(Icons.assignment_returned_outlined),
        onPressed: () => _confirmReturn(context, loan),
      ),
    );
  }

  Future<void> _confirmReturn(BuildContext context, Loan loan) async {
    final bloc = context.read<AdminLoansBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('반납 처리'),
        content: Text('"${loan.book?.title ?? loan.bookId}" 반납으로 처리하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('반납'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      bloc.add(AdminLoanReturnRequested(loan.id));
    }
  }
}

String _formatDate(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
