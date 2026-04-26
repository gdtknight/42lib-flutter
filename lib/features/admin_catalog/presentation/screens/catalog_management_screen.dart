import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/config.dart';
import '../../../books/data/models/book.dart';
import '../../data/repositories/admin_book_repository_impl.dart';
import '../../domain/repositories/admin_book_repository.dart';
import '../bloc/admin_book_bloc.dart';
import '../bloc/admin_book_event.dart';
import '../bloc/admin_book_state.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/book_form_widget.dart';
import '../widgets/delete_confirmation_dialog.dart';

class CatalogManagementScreen extends StatelessWidget {
  const CatalogManagementScreen({super.key, this.repository});

  final AdminBookRepository? repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AdminBookBloc>(
      create: (_) => AdminBookBloc(
        repository: repository ??
            AdminBookRepositoryImpl(baseUrl: AppConfig.apiBaseUrl),
      )..add(const AdminBooksRequested()),
      child: const _CatalogView(),
    );
  }
}

class _CatalogView extends StatelessWidget {
  const _CatalogView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('도서 관리'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '새로고침',
            onPressed: () =>
                context.read<AdminBookBloc>().add(const AdminBooksRequested()),
          ),
        ],
      ),
      drawer: const AdminSidebar(currentRoute: '/admin/catalog'),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('도서 추가'),
        onPressed: () => _openCreateForm(context),
      ),
      body: BlocConsumer<AdminBookBloc, AdminBookState>(
        listenWhen: (prev, next) =>
            next is AdminBookLoaded &&
            next.actionStatus != AdminBookActionStatus.idle &&
            next.actionStatus != AdminBookActionStatus.inProgress &&
            next.actionMessage != null,
        listener: (context, state) {
          if (state is AdminBookLoaded && state.actionMessage != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.actionMessage!)));
          }
        },
        builder: (context, state) {
          if (state is AdminBookInitial || state is AdminBookLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AdminBookError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline,
                      size: 48,
                      color: Theme.of(context).colorScheme.error),
                  const SizedBox(height: 12),
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context
                        .read<AdminBookBloc>()
                        .add(const AdminBooksRequested()),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }
          final loaded = state as AdminBookLoaded;
          if (loaded.books.isEmpty) {
            return const Center(child: Text('등록된 도서가 없습니다.'));
          }
          return _BookTable(books: loaded.books);
        },
      ),
    );
  }

  void _openCreateForm(BuildContext context) {
    final bloc = context.read<AdminBookBloc>();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '도서 추가',
                  style: Theme.of(dialogContext).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                BookFormWidget(
                  submitLabel: '추가',
                  onSubmit: (payload) {
                    bloc.add(AdminBookCreated(payload));
                    Navigator.of(dialogContext).pop();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BookTable extends StatelessWidget {
  const _BookTable({required this.books});

  final List<Book> books;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: books.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) => _BookRow(book: books[i]),
    );
  }
}

class _BookRow extends StatelessWidget {
  const _BookRow({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(book.title),
      subtitle: Text(
        '${book.author}  ·  ${book.category}  ·  ${book.availableQuantity}/${book.quantity}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: '편집',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _openEditForm(context, book),
          ),
          IconButton(
            tooltip: '삭제',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, book),
          ),
        ],
      ),
    );
  }

  void _openEditForm(BuildContext context, Book book) {
    final bloc = context.read<AdminBookBloc>();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '도서 편집',
                  style: Theme.of(dialogContext).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                BookFormWidget(
                  initial: book,
                  submitLabel: '저장',
                  onSubmit: (payload) {
                    bloc.add(AdminBookUpdated(book.id, payload));
                    Navigator.of(dialogContext).pop();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Book book) async {
    final bloc = context.read<AdminBookBloc>();
    final confirmed =
        await DeleteConfirmationDialog.show(context, bookTitle: book.title);
    if (confirmed) {
      bloc.add(AdminBookDeleted(book.id));
    }
  }
}
