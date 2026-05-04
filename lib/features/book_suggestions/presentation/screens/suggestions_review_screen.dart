import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/config.dart';
import '../../data/models/book_suggestion.dart';
import '../../data/models/grouped_suggestion.dart';
import '../../data/repositories/admin_suggestion_repository_impl.dart';
import '../../domain/repositories/admin_suggestion_repository.dart';
import '../bloc/admin_suggestions_bloc.dart';
import '../bloc/admin_suggestions_event.dart';
import '../bloc/admin_suggestions_state.dart';
import '../../../admin_catalog/presentation/widgets/admin_sidebar.dart';

class SuggestionsReviewScreen extends StatelessWidget {
  const SuggestionsReviewScreen({super.key, this.repository});

  final AdminSuggestionRepository? repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AdminSuggestionsBloc>(
      create: (_) => AdminSuggestionsBloc(
        repository: repository ??
            AdminSuggestionRepositoryImpl(baseUrl: AppConfig.apiBaseUrl),
      )..add(const AdminSuggestionsRequested()),
      child: const _Body(),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('도서 추천 검토'),
        actions: [
          IconButton(
            tooltip: '새로고침',
            icon: const Icon(Icons.refresh),
            onPressed: () => context
                .read<AdminSuggestionsBloc>()
                .add(const AdminSuggestionsRequested()),
          ),
        ],
      ),
      drawer: const AdminSidebar(currentRoute: '/admin/suggestions'),
      body: BlocConsumer<AdminSuggestionsBloc, AdminSuggestionsState>(
        listenWhen: (a, b) =>
            b is AdminSuggestionsLoaded &&
            (b.actionStatus == AdminSuggestionsActionStatus.success ||
                b.actionStatus == AdminSuggestionsActionStatus.failure) &&
            b.actionMessage != null,
        listener: (context, state) {
          if (state is AdminSuggestionsLoaded && state.actionMessage != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.actionMessage!)));
          }
        },
        builder: (context, state) {
          if (state is AdminSuggestionsInitial ||
              state is AdminSuggestionsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AdminSuggestionsError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        size: 56, color: Theme.of(context).colorScheme.error),
                    const SizedBox(height: 12),
                    Text(state.message, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => context
                          .read<AdminSuggestionsBloc>()
                          .add(const AdminSuggestionsRequested()),
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              ),
            );
          }
          final loaded = state as AdminSuggestionsLoaded;
          if (loaded.groups.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  '활성 수집 기간에 제출된 추천이 없습니다.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: loaded.groups.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _GroupCard(group: loaded.groups[i]),
          );
        },
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group});
  final GroupedSuggestion group;

  String _statusKor(SuggestionStatus s) {
    switch (s) {
      case SuggestionStatus.submitted:
        return '제출됨';
      case SuggestionStatus.approved:
        return '승인';
      case SuggestionStatus.rejected:
        return '반려';
      case SuggestionStatus.underReview:
        return '검토중';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group.suggestedTitle,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(group.suggestedAuthor,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[700])),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '추천 ${group.requesterCount}명',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              children: group.statuses.entries
                  .map((e) => Chip(
                        label: Text(
                          '${_statusKor(e.key)} ${e.value}',
                          style: theme.textTheme.bodySmall,
                        ),
                        visualDensity: VisualDensity.compact,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
            const Divider(),
            ...group.items.map((s) => _ItemRow(suggestion: s)),
          ],
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.suggestion});
  final BookSuggestion suggestion;

  Future<void> _openReviewDialog(
    BuildContext context,
    SuggestionStatus targetStatus,
  ) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final label = switch (targetStatus) {
          SuggestionStatus.approved => '승인',
          SuggestionStatus.rejected => '반려',
          SuggestionStatus.underReview => '검토중',
          _ => '저장',
        };
        return AlertDialog(
          title: Text('추천 $label'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  '대상: ${suggestion.suggestedTitle} / ${suggestion.suggestedAuthor}'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: '관리자 메모 (선택)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(label),
            ),
          ],
        );
      },
    );
    if (confirmed == true && context.mounted) {
      context.read<AdminSuggestionsBloc>().add(
            AdminSuggestionReviewed(
              suggestionId: suggestion.id,
              status: targetStatus,
              adminNotes: controller.text.trim().isEmpty
                  ? null
                  : controller.text.trim(),
            ),
          );
    }
  }

  String _statusKor(SuggestionStatus s) {
    switch (s) {
      case SuggestionStatus.submitted:
        return '제출됨';
      case SuggestionStatus.approved:
        return '승인';
      case SuggestionStatus.rejected:
        return '반려';
      case SuggestionStatus.underReview:
        return '검토중';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_statusKor(suggestion.status)} · ${suggestion.submittedAt.toLocal().toString().substring(0, 10)}',
                  style: theme.textTheme.bodySmall,
                ),
                if (suggestion.reason != null && suggestion.reason!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '사유: ${suggestion.reason}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.grey[700]),
                    ),
                  ),
                if (suggestion.adminNotes != null &&
                    suggestion.adminNotes!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '관리자 메모: ${suggestion.adminNotes}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.grey[700]),
                    ),
                  ),
              ],
            ),
          ),
          if (suggestion.isSubmitted || suggestion.isUnderReview) ...[
            IconButton(
              tooltip: '승인',
              icon: const Icon(Icons.check_circle_outline, color: Colors.green),
              onPressed: () =>
                  _openReviewDialog(context, SuggestionStatus.approved),
            ),
            IconButton(
              tooltip: '반려',
              icon: Icon(Icons.cancel_outlined, color: theme.colorScheme.error),
              onPressed: () =>
                  _openReviewDialog(context, SuggestionStatus.rejected),
            ),
            if (suggestion.isSubmitted)
              IconButton(
                tooltip: '검토중',
                icon: const Icon(Icons.hourglass_top_outlined,
                    color: Colors.amber),
                onPressed: () =>
                    _openReviewDialog(context, SuggestionStatus.underReview),
              ),
          ],
        ],
      ),
    );
  }
}
