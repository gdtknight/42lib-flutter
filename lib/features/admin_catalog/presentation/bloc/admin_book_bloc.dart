import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../books/data/models/book.dart';
import '../../domain/repositories/admin_book_repository.dart';
import 'admin_book_event.dart';
import 'admin_book_state.dart';

class AdminBookBloc extends Bloc<AdminBookEvent, AdminBookState> {
  final AdminBookRepository repository;

  AdminBookBloc({required this.repository}) : super(const AdminBookInitial()) {
    on<AdminBooksRequested>(_onLoad);
    on<AdminBookCreated>(_onCreate);
    on<AdminBookUpdated>(_onUpdate);
    on<AdminBookDeleted>(_onDelete);
  }

  Future<void> _onLoad(
    AdminBooksRequested event,
    Emitter<AdminBookState> emit,
  ) async {
    emit(const AdminBookLoading());
    try {
      final books = await repository.fetchBooks();
      emit(AdminBookLoaded(books: books));
    } catch (e) {
      emit(AdminBookError(e.toString()));
    }
  }

  Future<void> _onCreate(
    AdminBookCreated event,
    Emitter<AdminBookState> emit,
  ) async {
    final current = state;
    if (current is AdminBookLoaded) {
      emit(current.copyWith(actionStatus: AdminBookActionStatus.inProgress));
    }
    try {
      final book = await repository.createBook(event.payload);
      final books = current is AdminBookLoaded
          ? [book, ...current.books]
          : [book];
      emit(AdminBookLoaded(
        books: books,
        actionStatus: AdminBookActionStatus.success,
        actionMessage: '도서 추가 완료',
      ));
    } on BookConflictException catch (e) {
      emit(_actionFailure(current, e.message));
    } catch (e) {
      emit(_actionFailure(current, e.toString()));
    }
  }

  Future<void> _onUpdate(
    AdminBookUpdated event,
    Emitter<AdminBookState> emit,
  ) async {
    final current = state;
    if (current is AdminBookLoaded) {
      emit(current.copyWith(actionStatus: AdminBookActionStatus.inProgress));
    }
    try {
      final updated = await repository.updateBook(event.id, event.payload);
      final books = current is AdminBookLoaded
          ? current.books.map((b) => b.id == updated.id ? updated : b).toList()
          : [updated];
      emit(AdminBookLoaded(
        books: books,
        actionStatus: AdminBookActionStatus.success,
        actionMessage: '도서 수정 완료',
      ));
    } on BookConflictException catch (e) {
      emit(_actionFailure(current, e.message));
    } catch (e) {
      emit(_actionFailure(current, e.toString()));
    }
  }

  Future<void> _onDelete(
    AdminBookDeleted event,
    Emitter<AdminBookState> emit,
  ) async {
    final current = state;
    if (current is AdminBookLoaded) {
      emit(current.copyWith(actionStatus: AdminBookActionStatus.inProgress));
    }
    try {
      await repository.deleteBook(event.id);
      final List<Book> books = current is AdminBookLoaded
          ? current.books.where((b) => b.id != event.id).toList()
          : <Book>[];
      emit(AdminBookLoaded(
        books: books,
        actionStatus: AdminBookActionStatus.success,
        actionMessage: '도서 삭제 완료',
      ));
    } on BookInUseException catch (e) {
      emit(_actionFailure(
        current,
        '활성 대출 ${e.activeLoans}건, 대기 요청 ${e.pendingRequests}건이 있어 삭제할 수 없습니다.',
        AdminBookActionStatus.blockedByActiveUsage,
      ));
    } on BookConflictException catch (e) {
      emit(_actionFailure(current, e.message));
    } catch (e) {
      emit(_actionFailure(current, e.toString()));
    }
  }

  AdminBookState _actionFailure(
    AdminBookState current,
    String message, [
    AdminBookActionStatus status = AdminBookActionStatus.failure,
  ]) {
    if (current is AdminBookLoaded) {
      return current.copyWith(
        actionStatus: status,
        actionMessage: message,
      );
    }
    return AdminBookError(message);
  }
}
