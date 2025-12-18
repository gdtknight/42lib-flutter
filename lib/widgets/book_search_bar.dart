import 'dart:async';
import 'package:flutter/material.dart';

class BookSearchBar extends StatefulWidget {
  final Function(String) onChanged;
  final String? hintText;
  final bool enabled;
  final Color? backgroundColor;
  final double borderRadius;
  final int debounceMilliseconds;

  const BookSearchBar({
    Key? key,
    required this.onChanged,
    this.hintText = '책 제목, 저자로 검색',
    this.enabled = true,
    this.backgroundColor,
    this.borderRadius = 12.0,
    this.debounceMilliseconds = 500,
  }) : super(key: key);

  @override
  State<BookSearchBar> createState() => _BookSearchBarState();
}

class _BookSearchBarState extends State<BookSearchBar> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Create new timer
    _debounceTimer = Timer(
      Duration(milliseconds: widget.debounceMilliseconds),
      () {
        widget.onChanged(value);
      },
    );
  }

  void _clearSearch() {
    _controller.clear();
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.grey[100],
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      child: TextField(
        controller: _controller,
        enabled: widget.enabled,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: widget.hintText,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _clearSearch,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
