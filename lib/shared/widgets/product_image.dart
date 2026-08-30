import 'dart:io';

import 'package:flutter/material.dart';

import 'package:brewline/core/services/product_image_store.dart';

/// Renders a product photo from either a bundled `assets/...` path (default
/// catalog) or a file path copied by [ProductImageStore] (gallery uploads).
///
/// Missing/empty images never show a broken-image icon — they fall back to a
/// generic cup placeholder on `colorScheme.surfaceContainerHighest`.
class ProductImage extends StatelessWidget {
  final String path;
  final BoxFit fit;
  final double iconSize;

  const ProductImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.iconSize = 40,
  });

  bool get _isAsset => path.startsWith('assets/');

  @override
  Widget build(BuildContext context) {
    if (path.isEmpty) return _placeholder(context);
    if (_isAsset) {
      return Image.asset(
        path,
        fit: fit,
        errorBuilder: (_, _, _) => _placeholder(context),
      );
    }

    // File uploads: resolve the stable app-docs path, then decode. Failed or
    // moved files land on the same placeholder via errorBuilder.
    return FutureBuilder<String>(
      future: ProductImageStore.absolutePath(path),
      builder: (context, snapshot) {
        final abs = snapshot.data;
        if (abs == null) return _placeholder(context);
        return Image.file(
          File(abs),
          fit: fit,
          errorBuilder: (_, _, _) => _placeholder(context),
        );
      },
    );
  }

  Widget _placeholder(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        Icons.local_cafe_rounded,
        size: iconSize,
        color: colorScheme.outline,
      ),
    );
  }
}
