import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/collection_period.dart';
import '../bloc/suggestion_bloc.dart';
import '../bloc/suggestion_event.dart';
import '../bloc/suggestion_state.dart';

class SuggestionFormScreen extends StatelessWidget {
  const SuggestionFormScreen({super.key, this.bloc});

  /// In production we expect to be navigated *from* MySuggestionsScreen which
  /// owns a [SuggestionBloc]; the parent BlocProvider is reachable via `context`.
  /// For testing we accept an explicit `bloc` and wrap with BlocProvider.value.
  final SuggestionBloc? bloc;

  @override
  Widget build(BuildContext context) {
    if (bloc != null) {
      return BlocProvider<SuggestionBloc>.value(
        value: bloc!,
        child: const _SuggestionFormView(),
      );
    }
    return const _SuggestionFormView();
  }
}

class _SuggestionFormView extends StatefulWidget {
  const _SuggestionFormView();

  @override
  State<_SuggestionFormView> createState() => _SuggestionFormViewState();
}

class _SuggestionFormViewState extends State<_SuggestionFormView> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _author = TextEditingController();
  final _reason = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _author.dispose();
    _reason.dispose();
    super.dispose();
  }

  String? _required(String label, String? v) =>
      (v == null || v.trim().isEmpty) ? '$label을(를) 입력하세요' : null;

  String? _maxLen(String label, String? v, int max) {
    if (v == null) return null;
    if (v.length > max) return '$label은(는) $max자 이하여야 합니다';
    return null;
  }

  void _submit(BuildContext context) {
    final loaded = context.read<SuggestionBloc>().state;
    // T178: pre-flight guard — refuse to submit when there is no active
    // collection period. Backend would 400 anyway, but inline message is
    // gentler than a generic snackbar.
    if (loaded is! SuggestionLoaded ||
        !_isPeriodAcceptingSubmissions(loaded.activePeriod)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('현재 활성 수집 기간이 없어 추천을 제출할 수 없습니다.'),
        ));
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    context.read<SuggestionBloc>().add(SuggestionSubmitted(
          suggestedTitle: _title.text.trim(),
          suggestedAuthor: _author.text.trim(),
          reason: _reason.text.trim().isEmpty ? null : _reason.text.trim(),
        ));
  }

  bool _isPeriodAcceptingSubmissions(CollectionPeriod? period) =>
      period != null && period.status == PeriodStatus.active;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('도서 추천')),
      body: BlocConsumer<SuggestionBloc, SuggestionState>(
        listenWhen: (a, b) =>
            b is SuggestionLoaded &&
            (b.actionStatus == SuggestionActionStatus.success ||
                b.actionStatus == SuggestionActionStatus.failure) &&
            b.actionMessage != null,
        listener: (context, state) {
          if (state is SuggestionLoaded && state.actionMessage != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.actionMessage!)));
            if (state.actionStatus == SuggestionActionStatus.success) {
              context.go('/suggestions/mine');
            }
          }
        },
        builder: (context, state) {
          final isInProgress = state is SuggestionLoaded &&
              state.actionStatus == SuggestionActionStatus.inProgress;
          final period = state is SuggestionLoaded ? state.activePeriod : null;
          final canSubmit =
              !isInProgress && _isPeriodAcceptingSubmissions(period);

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _PeriodBanner(period: period),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _title,
                      enabled: canSubmit,
                      decoration: const InputDecoration(
                        labelText: '제목 *',
                        helperText: '500자 이내',
                      ),
                      validator: (v) =>
                          _required('제목', v) ?? _maxLen('제목', v, 500),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _author,
                      enabled: canSubmit,
                      decoration: const InputDecoration(
                        labelText: '저자 *',
                        helperText: '200자 이내',
                      ),
                      validator: (v) =>
                          _required('저자', v) ?? _maxLen('저자', v, 200),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _reason,
                      enabled: canSubmit,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: '추천 사유',
                        helperText: '1000자 이내 (선택)',
                      ),
                      validator: (v) => _maxLen('사유', v, 1000),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: canSubmit ? () => _submit(context) : null,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: isInProgress
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('제출'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Banner shown above the form. Three variants:
///   • no period at all → 경고 (form 비활성)
///   • upcoming/closed → 안내 (form 비활성)
///   • active → 기간 이름 + 종료일 + 남은 일수
class _PeriodBanner extends StatelessWidget {
  const _PeriodBanner({required this.period});

  final CollectionPeriod? period;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (period == null) {
      return _banner(
        context,
        icon: Icons.warning_amber_outlined,
        bg: theme.colorScheme.errorContainer,
        fg: theme.colorScheme.onErrorContainer,
        title: '활성 수집 기간이 없습니다',
        body: '관리자가 새 기간을 활성화할 때까지 추천을 제출할 수 없습니다.',
      );
    }

    if (period!.status != PeriodStatus.active) {
      final label = period!.status == PeriodStatus.upcoming ? '예정' : '종료';
      return _banner(
        context,
        icon: Icons.info_outline,
        bg: theme.colorScheme.surfaceContainerHighest,
        fg: theme.colorScheme.onSurface,
        title: '"${period!.name}" — $label 상태',
        body: '이 기간은 현재 추천을 받지 않습니다.',
      );
    }

    final days = period!.daysRemaining(DateTime.now());
    final endText = _formatDate(period!.endDate);
    return _banner(
      context,
      icon: Icons.event_available,
      bg: theme.colorScheme.primaryContainer,
      fg: theme.colorScheme.onPrimaryContainer,
      title: '제출 대상 기간: ${period!.name}',
      body: days == 0
          ? '오늘이 마지막 날입니다 (~$endText).'
          : '종료까지 D-$days · ~$endText',
    );
  }

  Widget _banner(
    BuildContext context, {
    required IconData icon,
    required Color bg,
    required Color fg,
    required String title,
    required String body,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fg),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: fg),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
