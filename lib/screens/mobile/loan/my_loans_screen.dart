import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../state/loan/loan_bloc.dart';
import '../../../state/loan/loan_event.dart';
import '../../../state/loan/loan_state.dart';
import '../../../state/auth/auth_bloc.dart';
import '../../../state/auth/auth_state.dart';
import '../../../models/loan_request.dart';
import '../../../models/reservation.dart';
import '../../../widgets/loan/reservation_queue_indicator.dart';

/// Screen displaying user's loan requests and reservations
class MyLoansScreen extends StatefulWidget {
  const MyLoansScreen({super.key});

  @override
  State<MyLoansScreen> createState() => _MyLoansScreenState();
}

class _MyLoansScreenState extends State<MyLoansScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Load loan requests on init
    context.read<LoanBloc>().add(const LoadMyLoanRequests());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;

    if (authState is! Authenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('내 대출')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.login,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              const Text('로그인이 필요합니다'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
                child: const Text('로그인하기'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 대출'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '대출 요청', icon: Icon(Icons.book)),
            Tab(text: '예약 대기열', icon: Icon(Icons.queue)),
          ],
        ),
      ),
      body: BlocConsumer<LoanBloc, LoanState>(
        listener: (context, state) {
          if (state is LoanError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is LoanOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is LoanLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is LoanLoaded) {
            return TabBarView(
              controller: _tabController,
              children: [
                _buildLoanRequestsList(state.loanRequests),
                _buildReservationsList(state.reservations),
              ],
            );
          }

          return const Center(child: Text('대출 정보를 불러올 수 없습니다'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.read<LoanBloc>().add(const RefreshLoanRequests());
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildLoanRequestsList(List<LoanRequest> requests) {
    if (requests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('대출 요청 내역이 없습니다'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<LoanBloc>().add(const RefreshLoanRequests());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];
          return _buildLoanRequestCard(request);
        },
      ),
    );
  }

  Widget _buildLoanRequestCard(LoanRequest request) {
    final theme = Theme.of(context);
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (request.status) {
      case LoanRequestStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        statusText = '승인 대기';
        break;
      case LoanRequestStatus.approved:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = '승인됨';
        break;
      case LoanRequestStatus.rejected:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = '거절됨';
        break;
      case LoanRequestStatus.cancelled:
        statusColor = Colors.grey;
        statusIcon = Icons.block;
        statusText = '취소됨';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  statusText,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (request.status == LoanRequestStatus.pending)
                  TextButton(
                    onPressed: () {
                      _showCancelDialog(request.id);
                    },
                    child: const Text('취소'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '요청일: ${_formatDate(request.requestedAt)}',
              style: theme.textTheme.bodySmall,
            ),
            if (request.notes != null) ...[
              const SizedBox(height: 4),
              Text(
                '메모: ${request.notes}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReservationsList(List<Reservation> reservations) {
    final activeReservations = reservations
        .where((r) => r.status == ReservationStatus.active)
        .toList();

    if (activeReservations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.queue_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('예약 대기열에 없습니다'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<LoanBloc>().add(const RefreshLoanRequests());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: activeReservations.length,
        itemBuilder: (context, index) {
          final reservation = activeReservations[index];
          return Column(
            children: [
              ReservationQueueIndicator(
                position: reservation.queuePosition,
                totalInQueue: 10, // TODO: Get from API
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  _showCancelReservationDialog(reservation.id);
                },
                icon: const Icon(Icons.cancel),
                label: const Text('예약 취소'),
              ),
              if (index < activeReservations.length - 1) const Divider(),
            ],
          );
        },
      ),
    );
  }

  void _showCancelDialog(String requestId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('대출 요청 취소'),
        content: const Text('대출 요청을 취소하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('아니오'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context
                  .read<LoanBloc>()
                  .add(CancelLoanRequest(requestId: requestId));
            },
            child: const Text('예'),
          ),
        ],
      ),
    );
  }

  void _showCancelReservationDialog(String reservationId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('예약 취소'),
        content: const Text('예약을 취소하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('아니오'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context
                  .read<LoanBloc>()
                  .add(CancelReservation(reservationId: reservationId));
            },
            child: const Text('예'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
