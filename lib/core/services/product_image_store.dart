/// Copies gallery-picked product photos into the app's own documents
/// directory so `products.image_path` always points at a **stable local
/// file** instead of the OS temp path, which can vanish or rotate between
/// sessions.
///
/// Spec root: `improve.md` §2.1. `image_path` stores a relative path like
/// `product_images/p-001.jpg`; [absolutePath] re-resolves it at render time.
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Sub-directory (relative to the app documents dir) holding product photos.
const String kProductImagesDir = 'product_images';

class ProductImageStore {
  ProductImageStore._();

  /// Copies [sourcePath] into the app documents so the pick survives restarts.
  ///
  /// Returns the stable relative path to store in `products.image_path`, or
  /// `null` when the source file is missing already.
  static Future<String?> storePickedImage({
    required String sourcePath,
    required String productId,
  }) async {
    final source = File(sourcePath);
    if (!await source.exists()) return null;

    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, kProductImagesDir));
    await dir.create(recursive: true);

    final extension = p.extension(sourcePath).toLowerCase();
    final target = File(
      p.join(dir.path, '$productId${extension.isEmpty ? '.jpg' : extension}'),
    );
    await source.copy(target.path);
    return '$kProductImagesDir/$productId$extension';
  }

  /// Absolute on-disk path for a stored relative [imagePath].
  static Future<String> absolutePath(String imagePath) async {
    final docs = await getApplicationDocumentsDirectory();
    return p.join(docs.path, imagePath);
  }
}
