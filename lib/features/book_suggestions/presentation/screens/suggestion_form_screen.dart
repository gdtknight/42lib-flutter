import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<SuggestionBloc>().add(SuggestionSubmitted(
          suggestedTitle: _title.text.trim(),
          suggestedAuthor: _author.text.trim(),
          reason: _reason.text.trim().isEmpty ? null : _reason.text.trim(),
        ));
  }

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

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (state is SuggestionLoaded && state.activePeriod != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          '제출 대상 기간: ${state.activePeriod!.name}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    TextFormField(
                      controller: _title,
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
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: '추천 사유',
                        helperText: '1000자 이내 (선택)',
                      ),
                      validator: (v) => _maxLen('사유', v, 1000),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: isInProgress ? null : _submit,
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
