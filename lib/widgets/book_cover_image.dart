import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Caching network image for book covers (T207).
///
/// Wraps `CachedNetworkImage` with consistent placeholder + error fallback
/// so the three call sites (책 카드 / 책 상세 / legacy 카드) share semantics:
///
/// - **null / empty URL** → placeholder.
/// - **loading** → low-effort shimmer (single-frame `Container` with the
///   same dimensions to avoid layout shift).
/// - **error** → placeholder.
///
/// Caching is handled by `cached_network_image`'s default disk + memory
/// LRU. Repeat fetches across screens hit the cache.
class BookCoverImage extends StatelessWidget {
  const BookCoverImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
  });

  final String? imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final hasUrl = imageUrl != null && imageUrl!.isNotEmpty;
    final image = hasUrl
        ? CachedNetworkImage(
            imageUrl: imageUrl!,
            fit: fit,
            width: width,
            height: height,
            placeholder: (_, __) => _Placeholder(width: width, height: height),
            errorWidget: (_, __, ___) =>
                _Placeholder(width: width, height: height),
          )
        : _Placeholder(width: width, height: height);

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({this.width, this.height});

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    // T247: placeholder가 책 표지를 대신하지만 정보 가치가 없는
    // 장식이라 screen reader에서는 제외.
    return ExcludeSemantics(
      child: Container(
        width: width,
        height: height,
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: Icon(
          Icons.book,
          size: width != null ? width! * 0.4 : 40,
          color: Colors.grey,
        ),
      ),
    );
  }
}
