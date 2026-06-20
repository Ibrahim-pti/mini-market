import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../providers/inventory_provider.dart';
import '../models/item_model.dart';
import '../theme/app_theme.dart';
import '../widgets/barcode_scanner_listener.dart';
import '../utils/number_formatter.dart';
class ItemEntryScreen extends StatefulWidget {
  final Item? item;
  const ItemEntryScreen({super.key, this.item});
  @override
  State<ItemEntryScreen> createState() => _ItemEntryScreenState();
}
class _ItemEntryScreenState extends State<ItemEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  // Controllers
  late TextEditingController _barcodeCtrl;
  late TextEditingController _nameCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _costPriceCtrl;
  late TextEditingController _wholesalePriceCtrl;
  late TextEditingController _quantityCtrl;
  late TextEditingController _expiryDateCtrl;
  late TextEditingController _categoryCtrl;
  final FocusNode _barcodeFocus = FocusNode();
  String? _selectedImagePath;
  String _unitType = 'دانە';
  @override
  void initState() {
    super.initState();
    _barcodeCtrl = TextEditingController(text: widget.item?.barcode ?? '');
    _nameCtrl = TextEditingController(text: widget.item?.name ?? '');
    _priceCtrl = TextEditingController(text: widget.item?.price.toString() ?? '');
    _costPriceCtrl = TextEditingController(text: widget.item?.costPrice.toString() ?? '');
    _wholesalePriceCtrl = TextEditingController(text: widget.item?.wholesalePrice.toString() ?? '');
    _quantityCtrl = TextEditingController(text: widget.item?.quantity.toString() ?? '');
    _expiryDateCtrl = TextEditingController(text: widget.item?.expiryDate ?? '');
    _categoryCtrl = TextEditingController(text: widget.item?.category ?? '');
    _unitType = widget.item?.unitType ?? 'دانە';
    _selectedImagePath = widget.item?.imagePath;
    // Aggressively request focus for barcode when opening screen
    if (widget.item == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _barcodeFocus.requestFocus();
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) _barcodeFocus.requestFocus();
        });
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _barcodeFocus.requestFocus();
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
    _wholesalePriceCtrl.dispose();
    _quantityCtrl.dispose();
    _expiryDateCtrl.dispose();
    _categoryCtrl.dispose();
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
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}';
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
        price: double.tryParse(_priceCtrl.text.trim()) ?? 0.0,
        costPrice: 0.0, // Simplified out
        wholesalePrice: 0.0, // Simplified out
        quantity: 999999, // Always infinite
        expiryDate: '', // Simplified out
        category: '', // Simplified out
        unitType: 'دانە', // Simplified out
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
   
  Widget _buildTextField(String label, TextEditingController controller, {FocusNode? focusNode, bool isNumber = false, String? prefixText, Function(String)? onSubmitted, bool isBarcode = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        autofocus: focusNode != null,
        keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        inputFormatters: (isNumber || isBarcode) ? [EnglishNumberFormatter()] : null,
        textDirection: (isNumber || isBarcode) ? TextDirection.ltr : TextDirection.rtl,
        textAlign: (isNumber || isBarcode) ? TextAlign.left : TextAlign.right,
        decoration: InputDecoration(
          labelText: label,
          prefixText: prefixText,
        ),
        onFieldSubmitted: onSubmitted ?? (_) => FocusScope.of(context).nextFocus(),
        validator: (v) => v!.isEmpty ? 'تکایە پڕی بکەوە' : null,
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    return BarcodeScannerListener(
      onBarcodeScanned: (barcode) {
        setState(() {
          _barcodeCtrl.text = barcode;
        });
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(widget.item == null ? 'تۆمارکردنی کاڵای نوێ' : 'گۆڕانکاری لە کاڵا'),
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.ink,
          elevation: 0,
          scrolledUnderElevation: 0,
          shape: Border(bottom: BorderSide(color: AppColors.border)),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _save,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.save_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text('پاشەکەوتکردن',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
                child: Flex(
                  direction: isDesktop ? Axis.horizontal : Axis.vertical,
                  crossAxisAlignment: isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.stretch,
                  children: [
                    // Column 1: Item Images and Type
                    isDesktop ? Expanded(
                      flex: 1,
                      child: _buildImageColumn(),
                    ) : _buildImageColumn(),
                    // Column 2: Simplified Basic Info
                    isDesktop ? Expanded(
                      flex: 2,
                      child: _buildInfoColumn(context),
                    ) : _buildInfoColumn(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildImageColumn() {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'وێنەی کاڵا',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.ink),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 220,
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.border),
                  image: _selectedImagePath != null
                      ? DecorationImage(image: FileImage(File(_selectedImagePath!)), fit: BoxFit.cover)
                      : null,
                ),
                child: _selectedImagePath == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              gradient: AppGradients.violet,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.add_a_photo_rounded, size: 30, color: Colors.white),
                          ),
                          const SizedBox(height: 14),
                          Text('وێنە هەڵبژێرە', style: TextStyle(color: AppColors.inkSoft, fontWeight: FontWeight.bold)),
                        ],
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildInfoColumn(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'زانیاری کاڵا',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.ink),
            ),
            const SizedBox(height: 24),
            _buildTextField(
              'بارکۆد', 
              _barcodeCtrl, 
              focusNode: _barcodeFocus,
              isBarcode: true,
              onSubmitted: (_) => FocusScope.of(context).nextFocus(),
            ),
            const SizedBox(height: 16),
            _buildTextField('ناوی کاڵا', _nameCtrl),
            const SizedBox(height: 16),
            _buildTextField('نرخی فرۆشتن', _priceCtrl, isNumber: true, prefixText: 'IQD '),
          ],
        ),
      ),
    );
  }
}
