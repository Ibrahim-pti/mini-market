import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/debt_provider.dart';

class PaymentResult {
  final bool confirmed;
  final bool isCredit;
  final String? customerName;
  final String? phone;
  final double givenAmount;
  final String? notes;

  PaymentResult({
    required this.confirmed,
    this.isCredit = false,
    this.customerName,
    this.phone,
    this.givenAmount = 0.0,
    this.notes,
  });
}

class PaymentDialog extends StatefulWidget {
  final double totalAmount;

  const PaymentDialog({super.key, required this.totalAmount});

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final NumberFormat _currencyFormat = NumberFormat('#,##0', 'en_US');
  String _inputAmountStr = '';
  bool _isCredit = false;

  final TextEditingController _customerNameCtrl = TextEditingController();
  final TextEditingController _customerPhoneCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _customerNameCtrl.dispose();
    _customerPhoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _givenAmount {
    if (_inputAmountStr.isEmpty) return 0.0;
    return double.tryParse(_inputAmountStr) ?? 0.0;
  }

  double get _changeAmount {
    if (_givenAmount < widget.totalAmount) return 0.0;
    return _givenAmount - widget.totalAmount;
  }

  double get _debtAmount {
    if (_givenAmount >= widget.totalAmount) return 0.0;
    return widget.totalAmount - _givenAmount;
  }

  void _onNumpadPress(String val) {
    setState(() {
      if (val == 'C') {
        _inputAmountStr = '';
      } else if (val == '⌫') {
        if (_inputAmountStr.isNotEmpty) {
          _inputAmountStr = _inputAmountStr.substring(0, _inputAmountStr.length - 1);
        }
      } else if (val == 'Exact') {
        _inputAmountStr = widget.totalAmount.toStringAsFixed(0);
      } else {
        if (_inputAmountStr.length < 12) {
          _inputAmountStr += val;
        }
      }
    });
  }

  void _addQuickCash(double amount) {
    setState(() {
      _inputAmountStr = amount.toStringAsFixed(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final maxH = media.size.height - media.viewInsets.vertical - 48;
    final maxW = media.size.width - 48;
    final dialogH = maxH < 650 ? maxH : 650.0;
    final dialogW = maxW < 880 ? maxW : 880.0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppColors.background,
        child: Container(
          width: dialogW,
          height: dialogH,
          padding: EdgeInsets.zero,
          child: Row(
            children: [
              // Left Side: Calculator / Quick Fill Numpad
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _isCredit
                            ? 'بڕی پێدراو بە نەختینە (ئەگەر کڕیار بەشێکی دابێت)'
                            : 'بڕی پێدراو (لەلایەن کڕیارەوە)',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.inkSoft,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Input Display
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: (_isCredit ? const Color(0xFFD97706) : AppColors.primary).withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: Text(
                          _inputAmountStr.isEmpty ? '0' : _currencyFormat.format(_givenAmount),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: _isCredit ? const Color(0xFFD97706) : AppColors.primaryDark,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Quick Cash Buttons
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          _quickBtn(5000),
                          _quickBtn(10000),
                          _quickBtn(25000),
                          _quickBtn(50000),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Numpad Grid
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(
                              child: _padRow([_numBtn('7'), _numBtn('8'), _numBtn('9')]),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: _padRow([_numBtn('4'), _numBtn('5'), _numBtn('6')]),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: _padRow([_numBtn('1'), _numBtn('2'), _numBtn('3')]),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: _padRow([
                                _numBtn('C', color: AppColors.roseSoft, textColor: AppColors.rose),
                                _numBtn('0'),
                                _numBtn('000'),
                              ]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Right Side: Unified Summary & Credit Checkbox / Fields
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'کورتەی وەسڵ',
                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppColors.ink),
                      ),
                      const SizedBox(height: 14),

                      // Totals Summary Box
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            _summaryRow('کۆی گشتی', widget.totalAmount, AppColors.ink, 18),
                            const Divider(height: 16),
                            _summaryRow('بڕی پێدراو (نەختینە)', _givenAmount, AppColors.primary, 16),
                            const SizedBox(height: 6),
                            if (!_isCredit)
                              _summaryRow(
                                'ماوە (گەڕاوە)',
                                _changeAmount,
                                _givenAmount >= widget.totalAmount ? AppColors.emerald : AppColors.rose,
                                18,
                              )
                            else
                              _summaryRow(
                                'بڕی قەرز (ماوە)',
                                _debtAmount,
                                _debtAmount > 0 ? const Color(0xFFD97706) : AppColors.emerald,
                                18,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Credit Checkbox Tile
                      InkWell(
                        onTap: () => setState(() => _isCredit = !_isCredit),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: _isCredit ? const Color(0xFFD97706).withValues(alpha: 0.1) : AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _isCredit ? const Color(0xFFD97706) : AppColors.border,
                              width: _isCredit ? 1.6 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                value: _isCredit,
                                activeColor: const Color(0xFFD97706),
                                onChanged: (v) => setState(() => _isCredit = v ?? false),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'فرۆشتن بە قەرز (تۆمارکردن بۆ کڕیار)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: _isCredit ? const Color(0xFFD97706) : AppColors.ink,
                                      ),
                                    ),
                                    Text(
                                      _isCredit
                                          ? (_givenAmount == 0
                                              ? 'تەواوی بڕەکە (کامل ${_currencyFormat.format(widget.totalAmount)} د.ع) وەک قەرز دەمێنێتەوە'
                                              : 'بڕی ${_currencyFormat.format(_debtAmount)} د.ع بە قەرز تۆمار دەکرێت')
                                          : 'ئەگەر پارەی نەختینە نییە چێکی بکە بۆ تۆمارکردنی قەرز',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: _isCredit ? const Color(0xFFD97706) : AppColors.muted,
                                        fontWeight: _isCredit ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Expandable Customer Fields when Credit is Checked
                      if (_isCredit) ...[
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Known Customer Autocomplete
                                Consumer<DebtProvider>(
                                  builder: (context, debtProv, _) {
                                    final knownNames = debtProv.allDebts
                                        .map((d) => d.personName)
                                        .toSet()
                                        .toList();

                                    return Autocomplete<String>(
                                      initialValue: TextEditingValue(text: _customerNameCtrl.text),
                                      optionsBuilder: (textEditingValue) {
                                        if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                                        return knownNames.where((name) =>
                                            name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                                      },
                                      onSelected: (selection) {
                                        _customerNameCtrl.text = selection;
                                        final match = debtProv.allDebts.firstWhere((d) => d.personName == selection);
                                        if (match.phone != null) {
                                          _customerPhoneCtrl.text = match.phone!;
                                        }
                                      },
                                      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                                        return TextField(
                                          controller: textEditingController,
                                          focusNode: focusNode,
                                          onChanged: (v) => _customerNameCtrl.text = v,
                                          decoration: const InputDecoration(
                                            labelText: 'ناوی کڕیار *',
                                            prefixIcon: Icon(Icons.person_outline_rounded, size: 18),
                                            isDense: true,
                                            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                                const SizedBox(height: 10),

                                TextField(
                                  controller: _customerPhoneCtrl,
                                  keyboardType: TextInputType.phone,
                                  decoration: const InputDecoration(
                                    labelText: 'ژمارەی مۆبایل (ئارەزوومەندانە)',
                                    prefixIcon: Icon(Icons.phone_outlined, size: 18),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  ),
                                ),
                                const SizedBox(height: 10),

                                TextField(
                                  controller: _notesCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'تێبینی (ئارەزوومەندانە)',
                                    prefixIcon: Icon(Icons.notes_rounded, size: 18),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ] else ...[
                        const Spacer(),
                      ],

                      const SizedBox(height: 12),

                      // Main Confirmation Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (_isCredit) {
                              if (_customerNameCtrl.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('تکایە ناوی کڕیار دیاری بکە')),
                                );
                                return;
                              }
                              Navigator.pop(
                                context,
                                PaymentResult(
                                  confirmed: true,
                                  isCredit: true,
                                  customerName: _customerNameCtrl.text.trim(),
                                  phone: _customerPhoneCtrl.text.trim().isEmpty ? null : _customerPhoneCtrl.text.trim(),
                                  givenAmount: _givenAmount,
                                  notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
                                ),
                              );
                            } else {
                              if (_givenAmount < widget.totalAmount && _givenAmount > 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('بڕی پێدراو کەمترە لە کۆی گشتی! دەتوانیت فرۆشتن بە قەرز چێک بکەیت.')),
                                );
                                return;
                              }
                              Navigator.pop(
                                context,
                                PaymentResult(
                                  confirmed: true,
                                  isCredit: false,
                                  givenAmount: _givenAmount,
                                ),
                              );
                            }
                          },
                          icon: Icon(_isCredit ? Icons.account_balance_wallet_rounded : Icons.check_rounded, size: 20),
                          label: Text(
                            _isCredit
                                ? (_givenAmount > 0
                                    ? 'تۆمارکردن بە قەرز (${_currencyFormat.format(_debtAmount)} د.ع ماوە)'
                                    : 'تۆمارکردن بە قەرز (تەواوی بڕەکە)')
                                : 'پەسەندکردن و فرۆشتن',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isCredit ? const Color(0xFFD97706) : AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Cancel Button
                      SizedBox(
                        width: double.infinity,
                        height: 42,
                        child: TextButton(
                          onPressed: () => Navigator.pop(context, PaymentResult(confirmed: false)),
                          style: TextButton.styleFrom(foregroundColor: AppColors.muted),
                          child: const Text('پاشگەزبوونەوە', style: TextStyle(fontSize: 15)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickBtn(double amount) {
    return InkWell(
      onTap: () => _addQuickCash(amount),
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          _currencyFormat.format(amount),
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink, fontSize: 13.5),
        ),
      ),
    );
  }

  Widget _padRow(List<Widget> btns) {
    return Row(
      children: [
        Expanded(child: btns[0]),
        const SizedBox(width: 8),
        Expanded(child: btns[1]),
        const SizedBox(width: 8),
        Expanded(child: btns[2]),
      ],
    );
  }

  Widget _numBtn(String val, {Color? color, Color? textColor}) {
    return InkWell(
      onTap: () => _onNumpadPress(val),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color ?? AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          val,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: textColor ?? AppColors.ink,
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String title, double amount, Color color, double fontSize) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(title, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.inkSoft)),
        Text(
          '${_currencyFormat.format(amount)} د.ع',
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
