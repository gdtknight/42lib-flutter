import 'dart:async';
import 'package:flutter/material.dart';

/// A search bar widget with debounce functionality
class BookSearchBar extends StatefulWidget {
  final ValueChanged<String>? onChanged;
  final String? hintText;
  final bool enabled;
  final Duration debounceDuration;

  const BookSearchBar({
    super.key,
    this.onChanged,
    this.hintText = 'Search books...',
    this.enabled = true,
    this.debounceDuration = const Duration(milliseconds: 500),
  });

  @override
  State<BookSearchBar> createState() => _BookSearchBarState();
}

class _BookSearchBarState extends State<BookSearchBar> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  bool _showClearButton = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _showClearButton = _controller.text.isNotEmpty;
    });

    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(widget.debounceDuration, () {
      widget.onChanged?.call(_controller.text);
    });
  }

  void _clearText() {
    _controller.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      enabled: widget.enabled,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _showClearButton
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: _clearText,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: widget.enabled
            ? Theme.of(context).colorScheme.surface
            : Colors.grey[200],
      ),
    );
  }
}
