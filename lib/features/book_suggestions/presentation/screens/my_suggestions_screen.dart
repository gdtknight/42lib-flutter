import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config.dart';
import '../../data/models/book_suggestion.dart';
import '../../data/repositories/suggestion_repository_impl.dart';
import '../bloc/suggestion_bloc.dart';
import '../bloc/suggestion_event.dart';
import '../bloc/suggestion_state.dart';

class MySuggestionsScreen extends StatelessWidget {
  const MySuggestionsScreen({super.key, this.bloc});

  final SuggestionBloc? bloc;

  @override
  Widget build(BuildContext context) {
    if (bloc != null) {
      return BlocProvider<SuggestionBloc>.value(
        value: bloc!,
        child: const _MySuggestionsView(),
      );
    }
    return BlocProvider<SuggestionBloc>(
      create: (_) => SuggestionBloc(
        repository:
            SuggestionRepositoryImpl(baseUrl: AppConfig.apiBaseUrl),
      )..add(const SuggestionsRequested()),
      child: const _MySuggestionsView(),
    );
  }
}

class _MySuggestionsView extends StatelessWidget {
  const _MySuggestionsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 희망 도서'),
        actions: [
          IconButton(
            tooltip: '새로고침',
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                context.read<SuggestionBloc>().add(const SuggestionsRequested()),
          ),
        ],
      ),
      floatingActionButton: BlocBuilder<SuggestionBloc, SuggestionState>(
        buildWhen: (a, b) => b is SuggestionLoaded || b is SuggestionInitial,
        builder: (context, state) {
          if (state is SuggestionLoaded && state.activePeriod != null) {
            return FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: const Text('도서 추천'),
              onPressed: () => context.go('/suggestions/new'),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      body: BlocBuilder<SuggestionBloc, SuggestionState>(
        builder: (context, state) {
          if (state is SuggestionLoading || state is SuggestionInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is SuggestionError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 56, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(state.message, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => context
                          .read<SuggestionBloc>()
                          .add(const SuggestionsRequested()),
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              ),
            );
          }
          final loaded = state as SuggestionLoaded;
          return Column(
            children: [
              if (loaded.activePeriod == null)
                const _NoActivePeriodBanner()
              else
                _ActivePeriodBanner(periodName: loaded.activePeriod!.name),
              Expanded(
                child: loaded.mySuggestions.isEmpty
                    ? const _EmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                        itemCount: loaded.mySuggestions.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) =>
                            _SuggestionTile(suggestion: loaded.mySuggestions[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ActivePeriodBanner extends StatelessWidget {
  const _ActivePeriodBanner({required this.periodName});
  final String periodName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.primaryContainer,
      padding: const EdgeInsets.all(12),
      child: Text(
        '활성 수집 기간: $periodName',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
      ),
    );
  }
}

class _NoActivePeriodBanner extends StatelessWidget {
  const _NoActivePeriodBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.all(12),
      child: Text(
        '현재 활성 수집 기간이 없습니다. 새 기간이 열릴 때까지 추천을 제출할 수 없습니다.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lightbulb_outline,
                size: 56, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              '아직 제출한 추천이 없습니다.\n우측 하단 + 버튼으로 추천을 시작하세요.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({required this.suggestion});
  final BookSuggestion suggestion;

  Color _statusColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (suggestion.status) {
      case SuggestionStatus.approved:
        return Colors.green;
      case SuggestionStatus.rejected:
        return scheme.error;
      case SuggestionStatus.underReview:
        return Colors.amber.shade700;
      case SuggestionStatus.submitted:
        return scheme.primary;
    }
  }

  String _statusLabel() {
    switch (suggestion.status) {
      case SuggestionStatus.approved:
        return '승인됨';
      case SuggestionStatus.rejected:
        return '반려됨';
      case SuggestionStatus.underReview:
        return '검토 중';
      case SuggestionStatus.submitted:
        return '제출됨';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(suggestion.suggestedTitle),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(suggestion.suggestedAuthor),
          if (suggestion.adminNotes != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '관리자 메모: ${suggestion.adminNotes}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[700],
                    ),
              ),
            ),
        ],
      ),
      trailing: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _statusColor(context).withOpacity(0.12),
          border: Border.all(color: _statusColor(context).withOpacity(0.4)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _statusLabel(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _statusColor(context),
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}
