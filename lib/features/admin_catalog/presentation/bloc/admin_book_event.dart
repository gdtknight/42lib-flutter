import 'package:equatable/equatable.dart';

import '../../domain/repositories/admin_book_repository.dart';

abstract class AdminBookEvent extends Equatable {
  const AdminBookEvent();

  @override
  List<Object?> get props => [];
}

class AdminBooksRequested extends AdminBookEvent {
  const AdminBooksRequested();
}

class AdminBookCreated extends AdminBookEvent {
  final AdminBookPayload payload;

  const AdminBookCreated(this.payload);

  @override
  List<Object?> get props => [payload];
}

class AdminBookUpdated extends AdminBookEvent {
  final String id;
  final AdminBookPayload payload;

  const AdminBookUpdated(this.id, this.payload);

  @override
  List<Object?> get props => [id, payload];
}

class AdminBookDeleted extends AdminBookEvent {
  final String id;

  const AdminBookDeleted(this.id);

  @override
  List<Object?> get props => [id];
}
