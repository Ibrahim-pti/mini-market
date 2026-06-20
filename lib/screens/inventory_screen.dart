import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../models/item_model.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'item_dialog.dart';
import '../widgets/barcode_scanner_listener.dart';
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}
class _InventoryScreenState extends State<InventoryScreen> {
  final NumberFormat _currencyFormat = NumberFormat('#,##0', 'en_US');
  final TextEditingController _searchCtrl = TextEditingController();
  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width > 600;
    return BarcodeScannerListener(
      onBarcodeScanned: (barcode) {
        _searchCtrl.text = barcode;
        context.read<InventoryProvider>().search(barcode);
      },
      child: Container(
        color: AppColors.background,
        padding: EdgeInsets.all(isDesktop ? 28.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: [
              Text('بەرهەمەکان',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink)),
              _AddButton(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => const ItemDialog(),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Search
          TextField(
            controller: _searchCtrl,
            onChanged: (val) => context.read<InventoryProvider>().search(val),
            decoration: InputDecoration(
              hintText: 'گەڕان بەدوای کاڵا یان بارکۆد...',
              prefixIcon: Icon(Icons.search_rounded),
              filled: true,
              fillColor: AppColors.surface,
            ),
          ),
          const SizedBox(height: 20),
          // Table
          Expanded(
            child: Consumer<InventoryProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.searchResults.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 64, color: AppColors.muted),
                        const SizedBox(height: 16),
                        Text('هیچ کاڵایەک نەدۆزرایەوە',
                            style: TextStyle(
                                color: AppColors.inkSoft,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppShadows.card,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      // Table header
                      Container(
                        color: AppColors.surfaceAlt,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        child: Row(
                          children: [
                            SizedBox(width: 52),
                            _HeaderCell('بارکۆد', flex: 2),
                            _HeaderCell('ناوی کاڵا', flex: 3),
                            _HeaderCell('نرخ', flex: 2),
                            SizedBox(
                              width: 96,
                              child: Text('کردارەکان',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.inkSoft)),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          itemCount: provider.searchResults.length,
                          separatorBuilder: (_, __) => Divider(
                              height: 1, color: AppColors.border),
                          itemBuilder: (context, index) {
                            final item = provider.searchResults[index];
                            return _itemRow(context, provider, item);
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
    );
  }
  Widget _itemRow(
      BuildContext context, InventoryProvider provider, Item item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // Image
          Container(
            width: 44,
            height: 44,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
            ),
            child: item.imagePath != null
                ? Image.file(File(item.imagePath!), fit: BoxFit.cover)
                : Icon(Icons.inventory_2_outlined,
                    color: AppColors.muted, size: 22),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(item.barcode,
                style: TextStyle(
                    fontWeight: FontWeight.w500, color: AppColors.inkSoft)),
          ),
          Expanded(
            flex: 3,
            child: Text(item.name,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: AppColors.ink)),
          ),
          Expanded(
            flex: 2,
            child: Text('${_currencyFormat.format(item.price)} د.ع',
                style: TextStyle(
                    color: AppColors.ink, fontWeight: FontWeight.w600)),
          ),
          SizedBox(
            width: 96,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _iconAction(
                  Icons.edit_rounded,
                  AppColors.primary,
                  AppColors.violetSoft,
                  () => showDialog(
                      context: context,
                      builder: (_) => ItemDialog(item: item)),
                ),
                const SizedBox(width: 8),
                _iconAction(
                  Icons.delete_rounded,
                  AppColors.rose,
                  AppColors.roseSoft,
                  () => _confirmDelete(context, provider, item),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _iconAction(
      IconData icon, Color color, Color bg, VoidCallback onTap) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
  void _confirmDelete(
      BuildContext context, InventoryProvider provider, Item item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('سڕینەوەی کاڵا'),
        content: Text('دڵنیایت لە سڕینەوەی "${item.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                Text('نەخێر', style: TextStyle(color: AppColors.muted)),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deleteItem(item.id!);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.rose),
            child: Text('بەڵێ، سڕینەوە'),
          ),
        ],
      ),
    );
  }
}
class _HeaderCell extends StatelessWidget {
  final String text;
  final int flex;
  const _HeaderCell(this.text, {this.flex = 1});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(text,
          style: TextStyle(
              fontWeight: FontWeight.bold, color: AppColors.inkSoft)),
    );
  }
}
class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: AppShadows.glow(AppColors.primary),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, color: Colors.white, size: 22),
              SizedBox(width: 8),
              Text('زیادکردنی مادە',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }
}
