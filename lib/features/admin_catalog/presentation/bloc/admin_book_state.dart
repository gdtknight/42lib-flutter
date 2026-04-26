import 'package:equatable/equatable.dart';

import '../../../books/data/models/book.dart';

abstract class AdminBookState extends Equatable {
  const AdminBookState();

  @override
  List<Object?> get props => [];
}

class AdminBookInitial extends AdminBookState {
  const AdminBookInitial();
}

class AdminBookLoading extends AdminBookState {
  const AdminBookLoading();
}

class AdminBookLoaded extends AdminBookState {
  final List<Book> books;
  final AdminBookActionStatus actionStatus;
  final String? actionMessage;

  const AdminBookLoaded({
    required this.books,
    this.actionStatus = AdminBookActionStatus.idle,
    this.actionMessage,
  });

  AdminBookLoaded copyWith({
    List<Book>? books,
    AdminBookActionStatus? actionStatus,
    String? actionMessage,
  }) {
    return AdminBookLoaded(
      books: books ?? this.books,
      actionStatus: actionStatus ?? this.actionStatus,
      actionMessage: actionMessage,
    );
  }

  @override
  List<Object?> get props => [books, actionStatus, actionMessage];
}

class AdminBookError extends AdminBookState {
  final String message;

  const AdminBookError(this.message);

  @override
  List<Object?> get props => [message];
}

enum AdminBookActionStatus {
  idle,
  inProgress,
  success,
  failure,
  blockedByActiveUsage,
}
