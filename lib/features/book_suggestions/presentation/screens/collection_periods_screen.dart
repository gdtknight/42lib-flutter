import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/config.dart';
import '../../data/models/collection_period.dart';
import '../../data/repositories/admin_suggestion_repository_impl.dart';
import '../../domain/repositories/admin_suggestion_repository.dart';
import '../bloc/admin_suggestions_bloc.dart';
import '../bloc/admin_suggestions_event.dart';
import '../bloc/admin_suggestions_state.dart';
import '../../../admin_catalog/presentation/widgets/admin_sidebar.dart';

/// Minimal CollectionPeriod create form. The list of periods isn't a backend
/// endpoint yet (only `/active` is exposed), so this screen focuses on
/// creation. Reading current period info comes via SuggestionRepository's
/// fetchActivePeriod when needed elsewhere.
class CollectionPeriodsScreen extends StatelessWidget {
  const CollectionPeriodsScreen({super.key, this.repository});

  final AdminSuggestionRepository? repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AdminSuggestionsBloc>(
      create: (_) => AdminSuggestionsBloc(
        repository: repository ??
            AdminSuggestionRepositoryImpl(baseUrl: AppConfig.apiBaseUrl),
      ),
      child: const _Body(),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('수집 기간 관리')),
      drawer: const AdminSidebar(currentRoute: '/admin/collection-periods'),
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
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('새 수집 기간 만들기',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'active로 만들면 기존 활성 기간이 자동으로 closed 처리됩니다.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  const _PeriodForm(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PeriodForm extends StatefulWidget {
  const _PeriodForm();

  @override
  State<_PeriodForm> createState() => _PeriodFormState();
}

class _PeriodFormState extends State<_PeriodForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  DateTime? _start;
  DateTime? _end;
  PeriodStatus _status = PeriodStatus.upcoming;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart
        ? (_start ?? DateTime.now())
        : (_end ?? (_start ?? DateTime.now()).add(const Duration(days: 30)));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _start = picked;
        } else {
          _end = picked;
        }
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_start == null || _end == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('시작일과 종료일을 모두 선택하세요.')),
      );
      return;
    }
    if (!_end!.isAfter(_start!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('종료일은 시작일 이후여야 합니다.')),
      );
      return;
    }
    context.read<AdminSuggestionsBloc>().add(AdminPeriodCreated(
          name: _name.text.trim(),
          startDate: _start!,
          endDate: _end!,
          status: _status,
        ));
    _formKey.currentState!.reset();
    setState(() {
      _name.clear();
      _start = null;
      _end = null;
      _status = PeriodStatus.upcoming;
    });
  }

  String _statusLabel(PeriodStatus s) {
    switch (s) {
      case PeriodStatus.upcoming:
        return '예정 (upcoming)';
      case PeriodStatus.active:
        return '활성 (active)';
      case PeriodStatus.closed:
        return '종료 (closed)';
    }
  }

  String _fmt(DateTime? d) => d == null
      ? '선택 안 됨'
      : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final inProgress = context.watch<AdminSuggestionsBloc>().state
            is AdminSuggestionsLoaded &&
        (context.watch<AdminSuggestionsBloc>().state as AdminSuggestionsLoaded)
                .actionStatus ==
            AdminSuggestionsActionStatus.inProgress;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: '기간 이름 *',
              helperText: '100자 이내 (예: 2024 Q2 도서 추천)',
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return '기간 이름을 입력하세요';
              if (v.length > 100) return '100자 이하여야 합니다';
              return null;
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text('시작: ${_fmt(_start)}'),
                  onPressed: () => _pickDate(isStart: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.event),
                  label: Text('종료: ${_fmt(_end)}'),
                  onPressed: () => _pickDate(isStart: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<PeriodStatus>(
            value: _status,
            decoration: const InputDecoration(labelText: '상태'),
            items: PeriodStatus.values
                .map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(_statusLabel(s)),
                    ))
                .toList(),
            onChanged: (v) =>
                setState(() => _status = v ?? PeriodStatus.upcoming),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: inProgress ? null : _submit,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: inProgress
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('기간 생성'),
          ),
        ],
      ),
    );
  }
}
