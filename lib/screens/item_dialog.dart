import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../providers/inventory_provider.dart';
import '../models/item_model.dart';
import '../theme/app_theme.dart';
import '../widgets/barcode_scanner_listener.dart';
import '../utils/number_formatter.dart';
class ItemDialog extends StatefulWidget {
  final Item? item;
  const ItemDialog({super.key, this.item});
  @override
  State<ItemDialog> createState() => _ItemDialogState();
}
class _ItemDialogState extends State<ItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _barcodeCtrl;
  late TextEditingController _nameCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _costPriceCtrl;
  late TextEditingController _quantityCtrl;
  String? _selectedImagePath;
  final FocusNode _barcodeFocus = FocusNode();
  @override
  void initState() {
    super.initState();
    _barcodeCtrl = TextEditingController(text: widget.item?.barcode ?? '');
    _nameCtrl = TextEditingController(text: widget.item?.name ?? '');
    _priceCtrl = TextEditingController(
      text: widget.item?.price.toString() ?? '',
    );
    _costPriceCtrl = TextEditingController(
      text: widget.item?.costPrice.toString() ?? '0.0',
    );
    _quantityCtrl = TextEditingController(
      text: widget.item?.quantity.toString() ?? '0',
    );
    _selectedImagePath = widget.item?.imagePath;
    if (widget.item == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Request immediately
        _barcodeFocus.requestFocus();
        // Also request after dialog animation completes (approx 300ms)
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _barcodeFocus.requestFocus();
          }
        });
      });
    }
  }
  @override
  void dispose() {
    _barcodeCtrl.dispose();
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _costPriceCtrl.dispose();
    _quantityCtrl.dispose();
    _barcodeFocus.dispose();
    super.dispose();
  }
  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      final appDir = await getApplicationSupportDirectory();
      final imagesDir = Directory(p.join(appDir.path, 'item_images'));
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}';
      final savedFile = await file.copy(p.join(imagesDir.path, fileName));
      setState(() {
        _selectedImagePath = savedFile.path;
      });
    }
  }
  void _save() async {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<InventoryProvider>(context, listen: false);
      final newItem = Item(
        id: widget.item?.id,
        barcode: _barcodeCtrl.text.trim(),
        name: _nameCtrl.text.trim(),
        price: double.parse(_priceCtrl.text.trim()),
        costPrice: double.parse(_costPriceCtrl.text.trim()),
        quantity: int.parse(_quantityCtrl.text.trim()),
        imagePath: _selectedImagePath,
      );
      if (widget.item == null) {
        bool success = await provider.addItem(newItem);
        if (!success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ئەم بارکۆدە پێشتر تۆمارکراوە!')),
          );
          return;
        }
      } else {
        await provider.updateItem(newItem);
      }
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return BarcodeScannerListener(
      onBarcodeScanned: (barcode) {
        setState(() {
          _barcodeCtrl.text = barcode;
        });
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(
          widget.item == null ? 'زیادکردنی کاڵا' : 'گۆڕانکاری لە کاڵا',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.ink,
          ),
        ),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 140,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.border),
                        image: _selectedImagePath != null
                            ? DecorationImage(
                                image: FileImage(File(_selectedImagePath!)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _selectedImagePath == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: AppGradients.violet,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.add_a_photo_rounded,
                                    size: 28,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'وێنە هەڵبژێرە',
                                  style: TextStyle(
                                    color: AppColors.inkSoft,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _barcodeCtrl,
                    focusNode: _barcodeFocus,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.left,
                    decoration: InputDecoration(
                      labelText: 'بارکۆد',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    validator: (v) => v!.isEmpty ? 'تکایە بارکۆد بنووسە' : null,
                    onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'ناوی کاڵا',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    validator: (v) =>
                        v!.isEmpty ? 'تکایە ناوی کاڵا بنووسە' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _priceCtrl,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.left,
                    decoration: InputDecoration(
                      labelText: 'نرخی فرۆشتن (د.ع)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [EnglishNumberFormatter()],
                    validator: (v) {
                      if (v!.isEmpty) return 'تکایە نرخی فرۆشتن بنووسە';
                      if (double.tryParse(v) == null)
                        return 'تکایە ژمارە بنووسە';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _costPriceCtrl,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.left,
                    decoration: InputDecoration(
                      labelText: 'نرخی کڕین / تێچوو (د.ع)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [EnglishNumberFormatter()],
                    validator: (v) {
                      if (v!.isEmpty) return 'تکایە نرخی کڕین بنووسە';
                      if (double.tryParse(v) == null)
                        return 'تکایە ژمارە بنووسە';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _quantityCtrl,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.left,
                    decoration: InputDecoration(
                      labelText: 'بڕ (عەدەد)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [EnglishNumberFormatter()],
                    validator: (v) {
                      if (v!.isEmpty) return 'تکایە بڕ بنووسە';
                      if (int.tryParse(v) == null)
                        return 'تکایە ژمارەی دروست بنووسە';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'پاشگەزبوونەوە',
              style: TextStyle(color: AppColors.muted),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: Text(
                'پاشەکەوتکردن',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
