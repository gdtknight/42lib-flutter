import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../books/data/models/book.dart';
import '../../domain/repositories/admin_book_repository.dart';

/// Reusable form for creating or editing a book. When [initial] is provided,
/// the form is in edit mode and pre-populated. [prefillTitle]/[prefillAuthor]
/// seed only those two fields (used when promoting a suggestion to catalog).
class BookFormWidget extends StatefulWidget {
  const BookFormWidget({
    super.key,
    this.initial,
    this.prefillTitle,
    this.prefillAuthor,
    required this.onSubmit,
    this.submitLabel = '저장',
  });

  final Book? initial;
  final String? prefillTitle;
  final String? prefillAuthor;
  final void Function(AdminBookPayload payload) onSubmit;
  final String submitLabel;

  @override
  State<BookFormWidget> createState() => _BookFormWidgetState();
}

class _BookFormWidgetState extends State<BookFormWidget> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _author;
  late final TextEditingController _category;
  late final TextEditingController _isbn;
  late final TextEditingController _description;
  late final TextEditingController _publicationYear;
  late final TextEditingController _quantity;
  late final TextEditingController _availableQuantity;
  late final TextEditingController _coverImageUrl;

  @override
  void initState() {
    super.initState();
    final b = widget.initial;
    _title = TextEditingController(text: b?.title ?? widget.prefillTitle ?? '');
    _author =
        TextEditingController(text: b?.author ?? widget.prefillAuthor ?? '');
    _category = TextEditingController(text: b?.category ?? '');
    _isbn = TextEditingController(text: b?.isbn ?? '');
    _description = TextEditingController(text: b?.description ?? '');
    _publicationYear =
        TextEditingController(text: b?.publicationYear?.toString() ?? '');
    _quantity = TextEditingController(text: b?.quantity.toString() ?? '1');
    _availableQuantity = TextEditingController(
      text: b?.availableQuantity.toString() ?? '1',
    );
    _coverImageUrl = TextEditingController(text: b?.coverImageUrl ?? '');
  }

  @override
  void dispose() {
    for (final c in [
      _title,
      _author,
      _category,
      _isbn,
      _description,
      _publicationYear,
      _quantity,
      _availableQuantity,
      _coverImageUrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String label, String? v) =>
      (v == null || v.trim().isEmpty) ? '$label을(를) 입력하세요' : null;

  String? _validateIsbn(String? v) {
    if (v == null || v.trim().isEmpty) return null; // optional
    final cleaned = v.replaceAll(RegExp(r'[- ]'), '');
    if (!RegExp(r'^\d{10}$|^\d{13}$').hasMatch(cleaned)) {
      return 'ISBN은 10자리 또는 13자리 숫자여야 합니다';
    }
    return null;
  }

  String? _validatePositiveInt(String label, String? v, {int min = 1}) {
    if (v == null || v.trim().isEmpty) return '$label을(를) 입력하세요';
    final n = int.tryParse(v);
    if (n == null) return '$label은(는) 숫자여야 합니다';
    if (n < min) return '$label은(는) $min 이상이어야 합니다';
    return null;
  }

  String? _validateAvailability(String? v) {
    final base = _validatePositiveInt('대출 가능 수량', v, min: 0);
    if (base != null) return base;
    final available = int.parse(v!);
    final quantity = int.tryParse(_quantity.text) ?? 0;
    if (available > quantity) {
      return '대출 가능 수량은 총 수량($quantity) 이하여야 합니다';
    }
    return null;
  }

  String? _validatePublicationYear(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final y = int.tryParse(v);
    if (y == null) return '발행연도는 숫자여야 합니다';
    final maxYear = DateTime.now().year + 1;
    if (y < 1000 || y > maxYear) return '발행연도는 1000~$maxYear 범위여야 합니다';
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmit(
      AdminBookPayload(
        title: _title.text.trim(),
        author: _author.text.trim(),
        category: _category.text.trim(),
        quantity: int.parse(_quantity.text),
        availableQuantity: int.parse(_availableQuantity.text),
        isbn: _isbn.text.trim().isEmpty ? null : _isbn.text.trim(),
        description:
            _description.text.trim().isEmpty ? null : _description.text.trim(),
        publicationYear: _publicationYear.text.trim().isEmpty
            ? null
            : int.parse(_publicationYear.text),
        coverImageUrl: _coverImageUrl.text.trim().isEmpty
            ? null
            : _coverImageUrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: '제목 *'),
              validator: (v) => _required('제목', v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _author,
              decoration: const InputDecoration(labelText: '저자 *'),
              validator: (v) => _required('저자', v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _category,
              decoration: const InputDecoration(labelText: '카테고리 *'),
              validator: (v) => _required('카테고리', v),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantity,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: '총 수량 *'),
                    validator: (v) => _validatePositiveInt('총 수량', v, min: 1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _availableQuantity,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: '대출 가능 수량 *'),
                    validator: _validateAvailability,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _isbn,
              decoration: const InputDecoration(
                labelText: 'ISBN',
                helperText: '10자리 또는 13자리',
              ),
              validator: _validateIsbn,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _publicationYear,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: '발행연도'),
              validator: _validatePublicationYear,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _coverImageUrl,
              decoration: const InputDecoration(labelText: '표지 이미지 URL'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(labelText: '설명'),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(widget.submitLabel),
            ),
          ],
        ),
      ),
    );
  }
}
