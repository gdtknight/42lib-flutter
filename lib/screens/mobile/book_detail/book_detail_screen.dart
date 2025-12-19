import 'package:flutter/material.dart';
import '../../../models/book.dart';
import '../../../widgets/loan/loan_request_button.dart';

class BookDetailScreen extends StatelessWidget {
  final Book book;

  const BookDetailScreen({
    Key? key,
    required this.book,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('책 상세'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image section
            _buildCoverSection(context),

            // Book information
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    book.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),

                  // Author
                  _buildInfoRow(
                    context,
                    icon: Icons.person,
                    label: '저자',
                    value: book.author,
                  ),
                  const SizedBox(height: 8),

                  // Category
                  _buildInfoRow(
                    context,
                    icon: Icons.category,
                    label: '카테고리',
                    value: book.category,
                  ),

                  // ISBN (if available)
                  if (book.isbn != null) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      context,
                      icon: Icons.qr_code,
                      label: 'ISBN',
                      value: book.isbn!,
                    ),
                  ],

                  // Publication year (if available)
                  if (book.publicationYear != null) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      context,
                      icon: Icons.calendar_today,
                      label: '출판년도',
                      value: book.publicationYear.toString(),
                    ),
                  ],

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Availability section
                  _buildAvailabilitySection(context),

                  // Description (if available)
                  if (book.description != null &&
                      book.description!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      '책 소개',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      book.description!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildCoverSection(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 300,
      color: Colors.grey[200],
      child: book.coverImageUrl != null && book.coverImageUrl!.isNotEmpty
          ? Image.network(
              book.coverImageUrl!,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return _buildPlaceholderImage();
              },
            )
          : _buildPlaceholderImage(),
    );
  }

  Widget _buildPlaceholderImage() {
    return const Center(
      child: Icon(
        Icons.book,
        size: 100,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildAvailabilitySection(BuildContext context) {
    final isAvailable = book.isAvailable;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAvailable
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAvailable ? Colors.green : Colors.red,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isAvailable ? Icons.check_circle : Icons.cancel,
            color: isAvailable ? Colors.green : Colors.red,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '대여 가능 여부',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isAvailable ? '대여 가능' : '대여 중',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isAvailable ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${book.availableQuantity}/${book.quantity} 권 가능',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LoanRequestButton(
          bookId: book.id,
          isAvailable: book.isAvailable,
          onSuccess: () {
            // Optionally refresh book detail or navigate
          },
        ),
      ),
    );
  }
}
