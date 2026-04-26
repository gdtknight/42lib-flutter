import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lib_42_flutter/features/admin_catalog/domain/repositories/admin_book_repository.dart';
import 'package:lib_42_flutter/features/admin_catalog/presentation/bloc/admin_book_bloc.dart';
import 'package:lib_42_flutter/features/admin_catalog/presentation/bloc/admin_book_event.dart';
import 'package:lib_42_flutter/features/admin_catalog/presentation/bloc/admin_book_state.dart';

import '../../../../support/fake_admin_book_repository.dart';

const _payload = AdminBookPayload(
  title: '신간',
  author: '저자',
  category: 'Programming',
  quantity: 2,
  availableQuantity: 2,
);

void main() {
  group('AdminBookBloc', () {
    blocTest<AdminBookBloc, AdminBookState>(
      'load: emits [Loading, Loaded] when fetch succeeds',
      build: () {
        final repo = FakeAdminBookRepository()
          ..books = [makeAdminBook(id: 'a'), makeAdminBook(id: 'b')];
        return AdminBookBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const AdminBooksRequested()),
      expect: () => [
        isA<AdminBookLoading>(),
        isA<AdminBookLoaded>().having((s) => s.books.length, 'count', 2),
      ],
    );

    blocTest<AdminBookBloc, AdminBookState>(
      'load: emits [Loading, Error] on failure',
      build: () {
        final repo = FakeAdminBookRepository()..fetchError = Exception('boom');
        return AdminBookBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const AdminBooksRequested()),
      expect: () => [isA<AdminBookLoading>(), isA<AdminBookError>()],
    );

    blocTest<AdminBookBloc, AdminBookState>(
      'create: prepends new book and reports success',
      build: () {
        final repo = FakeAdminBookRepository()
          ..books = [makeAdminBook(id: 'existing')]
          ..createResult = makeAdminBook(id: 'new', title: '새 책');
        return AdminBookBloc(repository: repo);
      },
      seed: () => AdminBookLoaded(books: [makeAdminBook(id: 'existing')]),
      act: (bloc) => bloc.add(const AdminBookCreated(_payload)),
      expect: () => [
        isA<AdminBookLoaded>().having(
          (s) => s.actionStatus,
          'inProgress',
          AdminBookActionStatus.inProgress,
        ),
        isA<AdminBookLoaded>()
            .having((s) => s.books.length, 'count', 2)
            .having((s) => s.books.first.id, 'first.id', 'new')
            .having((s) => s.actionStatus, 'success',
                AdminBookActionStatus.success),
      ],
    );

    blocTest<AdminBookBloc, AdminBookState>(
      'update: replaces existing book in list',
      build: () {
        final repo = FakeAdminBookRepository()
          ..books = [makeAdminBook(id: 'a', title: '원래')]
          ..updateResult = makeAdminBook(id: 'a', title: '바뀜');
        return AdminBookBloc(repository: repo);
      },
      seed: () =>
          AdminBookLoaded(books: [makeAdminBook(id: 'a', title: '원래')]),
      act: (bloc) =>
          bloc.add(const AdminBookUpdated('a', _payload)),
      expect: () => [
        isA<AdminBookLoaded>().having((s) => s.actionStatus, 'inProgress',
            AdminBookActionStatus.inProgress),
        isA<AdminBookLoaded>()
            .having((s) => s.books.first.title, 'first.title', '바뀜')
            .having((s) => s.actionStatus, 'success',
                AdminBookActionStatus.success),
      ],
    );

    blocTest<AdminBookBloc, AdminBookState>(
      'delete: removes book and reports success',
      build: () {
        final repo = FakeAdminBookRepository()
          ..books = [makeAdminBook(id: 'a'), makeAdminBook(id: 'b')];
        return AdminBookBloc(repository: repo);
      },
      seed: () => AdminBookLoaded(
          books: [makeAdminBook(id: 'a'), makeAdminBook(id: 'b')]),
      act: (bloc) => bloc.add(const AdminBookDeleted('a')),
      expect: () => [
        isA<AdminBookLoaded>().having((s) => s.actionStatus, 'inProgress',
            AdminBookActionStatus.inProgress),
        isA<AdminBookLoaded>()
            .having((s) => s.books.length, 'count', 1)
            .having((s) => s.books.first.id, 'first.id', 'b')
            .having((s) => s.actionStatus, 'success',
                AdminBookActionStatus.success),
      ],
    );

    blocTest<AdminBookBloc, AdminBookState>(
      'delete: surfaces blockedByActiveUsage on BookInUseException',
      build: () {
        final repo = FakeAdminBookRepository()
          ..books = [makeAdminBook(id: 'a')]
          ..deleteError = const BookInUseException(
            activeLoans: 2,
            pendingRequests: 1,
          );
        return AdminBookBloc(repository: repo);
      },
      seed: () => AdminBookLoaded(books: [makeAdminBook(id: 'a')]),
      act: (bloc) => bloc.add(const AdminBookDeleted('a')),
      expect: () => [
        isA<AdminBookLoaded>().having((s) => s.actionStatus, 'inProgress',
            AdminBookActionStatus.inProgress),
        isA<AdminBookLoaded>()
            .having((s) => s.actionStatus, 'blocked',
                AdminBookActionStatus.blockedByActiveUsage)
            .having((s) => s.books.length, 'books retained', 1),
      ],
    );
  });
}
