import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../state/loan/loan_bloc.dart';
import '../../state/loan/loan_event.dart';
import '../../state/loan/loan_state.dart';
import '../../state/auth/auth_bloc.dart';
import '../../state/auth/auth_state.dart';

/// Button widget for requesting a book loan
class LoanRequestButton extends StatelessWidget {
  final String bookId;
  final bool isAvailable;
  final VoidCallback? onSuccess;

  const LoanRequestButton({
    super.key,
    required this.bookId,
    required this.isAvailable,
    this.onSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoanBloc, LoanState>(
      listener: (context, state) {
        if (state is LoanRequestCreated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
          onSuccess?.call();
        } else if (state is ReservationCreated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
          onSuccess?.call();
        } else if (state is LoanError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, loanState) {
        final authState = context.watch<AuthBloc>().state;
        final isAuthenticated = authState is Authenticated;
        final isLoading = loanState is LoanRequestCreating &&
            (loanState).bookId == bookId;

        if (!isAuthenticated) {
          return ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/login');
            },
            icon: const Icon(Icons.login),
            label: const Text('로그인하여 대출 요청'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          );
        }

        return ElevatedButton.icon(
          onPressed: isLoading ? null : () => _handleLoanRequest(context),
          icon: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(isAvailable ? Icons.book : Icons.queue),
          label: Text(
            isLoading
                ? '처리 중...'
                : isAvailable
                    ? '대출 요청'
                    : '예약 대기열 추가',
          ),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            backgroundColor: isAvailable
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.secondary,
          ),
        );
      },
    );
  }

  void _handleLoanRequest(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('대출 요청'),
        content: Text(
          isAvailable
              ? '이 도서를 대출 요청하시겠습니까?'
              : '도서가 현재 품절입니다. 예약 대기열에 추가하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<LoanBloc>().add(
                    CreateLoanRequest(bookId: bookId),
                  );
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}
