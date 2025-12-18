import 'package:flutter/material.dart';

class CategoryFilter extends StatefulWidget {
  final List<String> categories;
  final String? selectedCategory;
  final Function(String?) onCategorySelected;

  const CategoryFilter({
    Key? key,
    required this.categories,
    this.selectedCategory,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  State<CategoryFilter> createState() => _CategoryFilterState();
}

class _CategoryFilterState extends State<CategoryFilter> {
  final Map<String, String> _categoryLabels = {
    'Programming': '프로그래밍',
    'Design': '디자인',
    'Business': '비즈니스',
    'Science': '과학',
    'Art': '예술',
    'Language': '언어',
    'History': '역사',
    'Philosophy': '철학',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // "전체" chip (clear filter)
          _buildCategoryChip(
            label: '전체',
            value: null,
            isSelected: widget.selectedCategory == null,
          ),
          const SizedBox(width: 8),
          
          // Category chips
          ...widget.categories.map((category) {
            final label = _categoryLabels[category] ?? category;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildCategoryChip(
                label: label,
                value: category,
                isSelected: widget.selectedCategory == category,
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required String? value,
    required bool isSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        widget.onCategorySelected(value);
      },
      selectedColor: Theme.of(context).primaryColor,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.grey[200],
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}
