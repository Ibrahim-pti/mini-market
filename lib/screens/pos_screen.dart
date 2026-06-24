import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../models/item_model.dart';
import '../models/cart_item.dart';
import '../theme/app_theme.dart';
import '../widgets/barcode_scanner_listener.dart';
import '../widgets/payment_dialog.dart';
import '../utils/barcode_utils.dart';
import 'package:intl/intl.dart' show NumberFormat;

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});
  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _Cart {
  final int number;
  final List<CartItem> items;

  _Cart({required this.number, List<CartItem>? items}) : items = items ?? [];

  int get count => items.fold(0, (sum, c) => sum + c.quantity);
}

class _PosScreenState extends State<PosScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final NumberFormat _currencyFormat = NumberFormat('#,##0', 'en_US');
  final List<_Cart> _carts = [_Cart(number: 1)];
  int _activeIndex = 0;
  int _cartCounter = 1;
  String _query = '';

  List<CartItem> get _cartItems => _carts[_activeIndex].items;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScanSubmitted(String barcode) async {
    if (barcode.trim().isEmpty) {
      return;
    }
    final provider = Provider.of<InventoryProvider>(context, listen: false);
    final result = await provider.scanItemForPOS(barcode.trim());
    if (result == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ئەم بارکۆدە نەدۆزرایەوە: $barcode')),
        );
      }
    } else {
      _addItemToCart(result);
    }
  }

  void _addItemToCart(Item item) {
    int index = _cartItems.indexWhere((c) => c.item.id == item.id);
    if (index >= 0) {
      setState(() => _cartItems[index].quantity++);
    } else {
      setState(() => _cartItems.insert(0, CartItem(item: item)));
    }
  }

  // کاتێک هەموو سەبەتەکان تەواوبوون و تەنها یەک سەبەتەی بەتاڵ ماوە،
  // ژمارەکردن دەست پێ دەکاتەوە لە کڕیار ١.
  void _resetNumberingIfClear() {
    if (_carts.length == 1 && _carts[0].items.isEmpty) {
      _cartCounter = 1;
      _carts[0] = _Cart(number: 1);
      _activeIndex = 0;
    }
  }

  void _addNewCart() {
    setState(() {
      _cartCounter++;
      _carts.add(_Cart(number: _cartCounter));
      _activeIndex = _carts.length - 1;
    });
  }

  void _switchCart(int index) {
    if (index == _activeIndex) return;
    setState(() => _activeIndex = index);
  }

  void _closeCart(int index) {
    if (_carts.length == 1) {
      // دوایین سەبەتە: تەنها بەتاڵی بکە، مەیسڕەوە
      setState(() {
        _carts[0].items.clear();
        _resetNumberingIfClear();
      });
      return;
    }
    setState(() {
      _carts.removeAt(index);
      if (_activeIndex >= _carts.length) {
        _activeIndex = _carts.length - 1;
      } else if (index < _activeIndex) {
        _activeIndex--;
      }
      _resetNumberingIfClear();
    });
  }

  void _toast(String msg, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  void _checkout() async {
    if (_cartItems.isEmpty) return;
    final provider = Provider.of<InventoryProvider>(context, listen: false);
    int? saleId = await provider.checkoutCart(_cartItems);
    if (saleId != null) {
      setState(() {
        // ئەگەر زیاتر لە یەک سەبەتە هەیە، تابەکە دابخە؛ ئەگەرنا تەنها بەتاڵی بکە
        if (_carts.length > 1) {
          _carts.removeAt(_activeIndex);
          if (_activeIndex >= _carts.length) _activeIndex = _carts.length - 1;
        } else {
          _cartItems.clear();
        }
        _resetNumberingIfClear();
      });
      if (mounted) {
        _toast('فرۆشتنەکە بە سەرکەوتوویی تۆمارکرا', color: AppColors.emerald);
      }
    } else {
      if (mounted) _toast('کڕیار پارەی پێویستی نەداوە!', color: AppColors.rose);
    }
  }

  Future<void> _openPayment(double total) async {
    if (_cartItems.isEmpty) return;
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => PaymentDialog(totalAmount: total),
    );
    if (confirmed == true) _checkout();
  }

  @override
  Widget build(BuildContext context) {
    return BarcodeScannerListener(
      onBarcodeScanned: _onScanSubmitted,
      child: Container(
        color: AppColors.background,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 820;
            if (wide) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _productsPane()),
                    const SizedBox(width: 16),
                    SizedBox(width: 380, child: _cartPane()),
                  ],
                ),
              );
            }
            return Column(
              children: [
                Expanded(
                    flex: 5,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: _productsPane(),
                    )),
                Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: _cartPane(),
                    )),
              ],
            );
          },
        ),
      ),
    );
  }

  // ----------------------------- Products -----------------------------

  Widget _productsPane() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _query = v.trim()),
          decoration: InputDecoration(
            hintText: 'گەڕان بەدوای کاڵا یان بارکۆد...',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _query = '');
                    },
                  ),
            filled: true,
            fillColor: AppColors.surface,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Consumer<InventoryProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return Center(
                    child: CircularProgressIndicator(color: AppColors.primary));
              }
              final q = _query.toLowerCase();
              final items = provider.items.where((it) {
                if (q.isEmpty) return true;
                return it.name.toLowerCase().contains(q) ||
                    normalizeBarcode(it.barcode)
                        .toLowerCase()
                        .contains(normalizeBarcode(q)) ||
                    (it.category ?? '').toLowerCase().contains(q);
              }).toList();

              if (items.isEmpty) return _emptyProducts();

              return LayoutBuilder(builder: (context, c) {
                int cols = c.maxWidth > 1100
                    ? 5
                    : (c.maxWidth > 820 ? 4 : (c.maxWidth > 560 ? 3 : 2));
                return GridView.builder(
                  padding: EdgeInsets.zero,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    childAspectRatio: 0.78,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, i) => _productCard(items[i]),
                );
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _emptyProducts() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 48, color: AppColors.borderStrong),
          const SizedBox(height: 12),
          Text(
            _query.isEmpty
                ? 'هیچ کاڵایەک لە کۆگا نییە'
                : 'هیچ کاڵایەک نەدۆزرایەوە',
            style: TextStyle(color: AppColors.muted, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _productCard(Item item) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              color: AppColors.surfaceAlt,
              padding: const EdgeInsets.all(8),
              child: _itemImage(item),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('${_currencyFormat.format(item.price)} د.ع',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: SizedBox(
              width: double.infinity,
              child: Material(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: InkWell(
                  onTap: () => _addItemToCart(item),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded,
                            color: AppColors.primary, size: 16),
                        const SizedBox(width: 4),
                        Text('زیادکردن',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemImage(Item item) {
    if (item.imagePath != null && item.imagePath!.isNotEmpty) {
      if (item.imagePath!.startsWith('http')) {
        return Image.network(item.imagePath!,
            fit: BoxFit.contain, errorBuilder: (c, e, s) => _fallbackIcon());
      }
      return Image.file(File(item.imagePath!),
          fit: BoxFit.contain, errorBuilder: (c, e, s) => _fallbackIcon());
    }
    return _fallbackIcon();
  }

  Widget _fallbackIcon() => Center(
      child: Icon(Icons.inventory_2_outlined,
          color: AppColors.borderStrong, size: 38));

  // ------------------------------- Cart -------------------------------

  Widget _cartPane() {
    double total = _cartItems.fold(0, (sum, c) => sum + c.totalPrice);
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
          _cartTabs(),
          Divider(height: 1, color: AppColors.border),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                Icon(Icons.shopping_cart_rounded,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('کڕیار ${_carts[_activeIndex].number}',
                    style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
                const Spacer(),
                if (_cartItems.isNotEmpty)
                  InkWell(
                    onTap: () => setState(() {
                      _cartItems.clear();
                      _resetNumberingIfClear();
                    }),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          Icon(Icons.delete_sweep_rounded,
                              size: 16, color: AppColors.rose),
                          const SizedBox(width: 4),
                          Text('بەتاڵکردن',
                              style: TextStyle(
                                  color: AppColors.rose,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.border),
          Expanded(
            child: _cartItems.isEmpty
                ? _emptyCart()
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _cartItems.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: AppColors.border),
                    itemBuilder: (context, i) => _cartTile(_cartItems[i], i),
                  ),
          ),
          _totals(total),
        ],
      ),
    );
  }

  Widget _cartTabs() {
    return Container(
      height: 48,
      color: AppColors.surfaceAlt,
      child: Row(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              itemCount: _carts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, i) {
                final cart = _carts[i];
                final active = i == _activeIndex;
                return InkWell(
                  onTap: () => _switchCart(i),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(
                          color:
                              active ? AppColors.primary : AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Text('کڕیار ${cart.number}',
                            style: TextStyle(
                                color: active ? Colors.white : AppColors.inkSoft,
                                fontSize: 13,
                                fontWeight: FontWeight.bold)),
                        if (cart.count > 0) ...[
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: active
                                  ? Colors.white.withValues(alpha: 0.25)
                                  : AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('${cart.count}',
                                style: TextStyle(
                                    color: active
                                        ? Colors.white
                                        : AppColors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                        if (_carts.length > 1) ...[
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () => _closeCart(i),
                            borderRadius: BorderRadius.circular(20),
                            child: Icon(Icons.close_rounded,
                                size: 15,
                                color: active
                                    ? Colors.white
                                    : AppColors.muted),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          InkWell(
            onTap: _addNewCart,
            child: Container(
              width: 44,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: AppColors.border)),
              ),
              child: Icon(Icons.add_rounded,
                  color: AppColors.primary, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCart() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.remove_shopping_cart_outlined,
              size: 44, color: AppColors.borderStrong),
          const SizedBox(height: 12),
          Text('سەبەتەکە بەتاڵە',
              style: TextStyle(color: AppColors.muted, fontSize: 15)),
          const SizedBox(height: 4),
          Text('کاڵا هەڵبژێرە یان بارکۆد بخوێنەرەوە',
              style: TextStyle(color: AppColors.muted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _cartTile(CartItem cartItem, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cartItem.item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: AppColors.ink)),
                const SizedBox(height: 2),
                Text('${_currencyFormat.format(cartItem.item.price)} د.ع',
                    style: TextStyle(fontSize: 12, color: AppColors.muted)),
              ],
            ),
          ),
          // qty stepper
          Row(
            children: [
              _qtyBtn(Icons.remove_rounded, () {
                setState(() {
                  if (cartItem.quantity > 1) {
                    cartItem.quantity--;
                  } else {
                    _cartItems.removeAt(index);
                  }
                });
              }),
              Container(
                width: 34,
                alignment: Alignment.center,
                child: Text('${cartItem.quantity}',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink)),
              ),
              _qtyBtn(Icons.add_rounded, () {
                setState(() => cartItem.quantity++);
              }),
            ],
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 78,
            child: Text(_currencyFormat.format(cartItem.totalPrice),
                textAlign: TextAlign.left,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: AppColors.ink)),
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xs),
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.xs),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 15, color: AppColors.inkSoft),
      ),
    );
  }

  Widget _totals(double total) {
    final empty = _cartItems.isEmpty;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('کۆی گشتی',
                  style: TextStyle(
                      color: AppColors.inkSoft,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              Text('${_currencyFormat.format(total)} د.ع',
                  style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: empty ? null : () => _openPayment(total),
              icon: const Icon(Icons.point_of_sale_rounded, size: 20),
              label: const Text('پارەدان و تۆمارکردن'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    empty ? AppColors.borderStrong : AppColors.primary,
                disabledBackgroundColor: AppColors.borderStrong,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
