import 'package:flutter/material.dart';

class DeleteConfirmationDialog extends StatelessWidget {
  const DeleteConfirmationDialog({
    super.key,
    required this.bookTitle,
  });

  final String bookTitle;

  /// Returns `true` when the user confirms deletion.
  static Future<bool> show(BuildContext context, {required String bookTitle}) {
    return showDialog<bool>(
      context: context,
      builder: (_) => DeleteConfirmationDialog(bookTitle: bookTitle),
    ).then((value) => value ?? false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('도서 삭제 확인'),
      content: Text('"$bookTitle" 도서를 삭제하시겠습니까?\n\n활성 대출 또는 대기 중인 요청이 있으면 삭제할 수 없습니다.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('취소'),
        ),
        FilledButton.tonal(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('삭제'),
        ),
      ],
    );
  }
}
