import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:brewline/core/constants/app_sizes.dart';
import 'package:brewline/core/models/product.dart';
import 'package:brewline/core/repositories/product_repository.dart';
import 'package:brewline/core/services/product_image_store.dart';
import 'package:brewline/shared/ui/ui_button.dart';
import 'package:brewline/shared/ui/ui_modal.dart';
import 'package:brewline/shared/ui/ui_snack_bar.dart';
import 'package:brewline/shared/ui/ui_text.dart';

/// Catalog images the admin can pick from. Limited to what ships in
/// `assets/stack_imgs/` today; a future phase can add camera/gallery uploads.
const List<String> kProductImageOptions = [
  '',
  'assets/stack_imgs/expresso.jpg',
  'assets/stack_imgs/coca.jpg',
  'assets/stack_imgs/milk.jpg',
  'assets/stack_imgs/tea.jpg',
  'assets/stack_imgs/water.png',
];

/// Opens the add / edit product form as a bottom sheet on phones/tablets and a
/// dialog on desktop (see [showUiAdaptiveModal]).
///
/// [product] omitted → create mode; present → edit mode pre-filled.
Future<void> showProductFormSheet(BuildContext context, {Product? product}) {
  return showUiAdaptiveModal<void>(
    context,
    heightFactor: 0.95,
    content: _ProductFormSheet(isEditing: product != null, product: product),
  );
}

class _ProductFormSheet extends ConsumerStatefulWidget {
  final bool isEditing;
  final Product? product;

  const _ProductFormSheet({required this.isEditing, this.product});

  @override
  ConsumerState<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends ConsumerState<_ProductFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _category;
  late final TextEditingController _stock;
  late final TextEditingController _threshold;
  late bool _available;
  late String _imagePath;

  /// The user-picked gallery file awaiting copy into app storage on submit
  /// (never stored by reference — the OS temp path goes stale).
  XFile? _pendingPicked;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _name = TextEditingController(text: product?.name ?? '');
    _price = TextEditingController(
      text: product == null ? '' : product.price.toString(),
    );
    _category = TextEditingController(text: product?.category ?? '');
    _stock = TextEditingController(
      text: product == null || product.stockQuantity == 0
          ? ''
          : '${product.stockQuantity}',
    );
    _threshold = TextEditingController(
      text: product == null ? '' : '${product.lowStockThreshold}',
    );
    _available = product?.available ?? true;
    _imagePath = product?.imagePath ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _category.dispose();
    _stock.dispose();
    _threshold.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    final product = widget.product;
    final id = product?.id ?? 'p-${DateTime.now().millisecondsSinceEpoch}';

    // Copy a gallery pick into the app's own directory before upserting, so
    // `image_path` targets a stable file that survives restarts.
    var imagePath = _imagePath;
    final picked = _pendingPicked;
    if (picked != null) {
      final stored = await ProductImageStore.storePickedImage(
        sourcePath: picked.path,
        productId: id,
      );
      if (stored != null) imagePath = stored;
    }

    final updated = Product(
      id: id,
      name: _name.text.trim(),
      price: double.parse(_price.text.trim()),
      imagePath: imagePath,
      category: _category.text.trim(),
      available: _available,
      stockQuantity: int.tryParse(_stock.text.trim()) ?? 0,
      lowStockThreshold: int.tryParse(_threshold.text.trim()) ?? 0,
    );

    await ref.read(productMutationProvider.notifier).upsert(updated);

    if (!mounted) return;
    Navigator.of(context).pop();
    showUiSnackBar(
      context,
      widget.isEditing
          ? '${updated.name} updated'
          : '${updated.name} added to the menu',
      type: UiSnackBarType.success,
    );
  }

  /// Opens the system image picker; on success keeps the XFile around so
  /// submit can copy it into app storage (see [_submit]).
  Future<void> _pickFromGallery() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;
      setState(() {
        _pendingPicked = picked;
        _imagePath = picked.path; // preview only; not persisted as-is
      });
    } catch (_) {
      if (!mounted) return;
      showUiSnackBar(
        context,
        'Couldn\'t open the gallery.',
        type: UiSnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Padding(
        padding: adaptiveModalPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  widget.isEditing ? Icons.edit_rounded : Icons.add_box_rounded,
                  color: colorScheme.primary,
                ),
                SizedBox(width: Space.md),
                UiText(
                  widget.isEditing ? 'Edit product' : 'Add product',
                  type: UiTextType.titleLarge,
                  fontWeight: FontWeight.w700,
                ),
              ],
            ),
            SizedBox(height: Space.xl),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Product name',
                      prefixIcon: Icon(Icons.local_cafe_rounded),
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'Enter a name'
                        : null,
                  ),
                ),
                SizedBox(width: Space.lg),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _price,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Price (DH)',
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                    validator: (value) =>
                        double.tryParse((value ?? '').trim()) == null
                        ? 'Enter a price'
                        : (double.parse(value!.trim()) <= 0
                              ? 'Must be positive'
                              : null),
                  ),
                ),
              ],
            ),
            SizedBox(height: Space.lg),
            TextFormField(
              controller: _category,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Category',
                hintText: 'e.g. Coffee, Soft drinks',
                prefixIcon: Icon(Icons.label_outline_rounded),
              ),
            ),
            SizedBox(height: Space.lg),
            _ImagePicker(
              selected: _imagePath,
              onSelected: (path) => setState(() {
                _imagePath = path;
                _pendingPicked =
                    null; // switching back to an asset clears gallery pick
              }),
              onPickGallery: _pickFromGallery,
            ),
            SizedBox(height: Space.lg),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _stock,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Stock on hand',
                      helperText: '0 = not tracked',
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                    ),
                    validator: _nonNegativeInt,
                  ),
                ),
                SizedBox(width: Space.lg),
                Expanded(
                  child: TextFormField(
                    controller: _threshold,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Low-stock alert below',
                      prefixIcon: Icon(Icons.notifications_active_outlined),
                    ),
                    validator: _nonNegativeInt,
                  ),
                ),
              ],
            ),
            SizedBox(height: Space.lg),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _available,
              onChanged: (value) => setState(() => _available = value),
              title: const UiText(
                'Available on the menu',
                type: UiTextType.titleSmall,
                fontWeight: FontWeight.w600,
              ),
              subtitle: UiText(
                'Hides the product from waiters when off',
                type: UiTextType.bodySmall,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: Space.xl),
            UiButton(
              _saving
                  ? 'Saving…'
                  : (widget.isEditing ? 'Save changes' : 'Add to menu'),
              icon: Icons.check_rounded,
              expand: true,
              onPressed: _saving ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }

  String? _nonNegativeInt(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    final parsed = int.tryParse(text);
    if (parsed == null || parsed < 0) return 'Whole number, 0 or more';
    return null;
  }
}

/// Thumbnail strip of catalog images ("no image" first) plus a gallery
/// upload entry point. A picked file renders inline so the admin sees exactly
/// what will be saved.
class _ImagePicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;
  final Future<void> Function() onPickGallery;

  const _ImagePicker({
    required this.selected,
    required this.onSelected,
    required this.onPickGallery,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isPicked = selected.isNotEmpty && !selected.startsWith('assets/');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UiText(
          'Menu photo',
          type: UiTextType.titleSmall,
          fontWeight: FontWeight.w600,
        ),
        SizedBox(height: Space.md),
        Wrap(
          spacing: Space.md,
          runSpacing: Space.md,
          children: [
            for (final path in kProductImageOptions)
              _Thumb(
                selected: selected == path,
                onTap: () => onSelected(path),
                child: path.isEmpty
                    ? Icon(
                        Icons.image_not_supported_outlined,
                        color: colorScheme.outline,
                      )
                    : Image.asset(path, fit: BoxFit.cover),
              ),
            _Thumb(
              selected: isPicked,
              onTap: onPickGallery,
              child: isPicked
                  ? Image.file(File(selected), fit: BoxFit.cover)
                  : Tooltip(
                      message: 'Import from gallery',
                      child: Icon(
                        Icons.add_photo_alternate_outlined,
                        color: colorScheme.outline,
                      ),
                    ),
            ),
          ],
        ),
        // Live preview of the picked file, kept separate so a low-res overlay
        // doesn't crop the 64px selection tile.
        if (isPicked) ...[
          SizedBox(height: Space.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(Rounded.lg),
            child: SizedBox(
              width: double.infinity,
              height: 160,
              child: Image.file(File(selected), fit: BoxFit.cover),
            ),
          ),
        ],
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  const _Thumb({
    required this.selected,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Rounded.lg),
      child: Container(
        width: 64,
        height: 64,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Rounded.lg),
          border: Border.all(
            color: selected ? colorScheme.primary : colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: ColoredBox(
          color: colorScheme.surfaceContainerHighest,
          child: child,
        ),
      ),
    );
  }
}
