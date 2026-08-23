import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  String _paymentType = 'cash'; // 'cash' or 'debt'

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

  double get _remainingDebt {
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
    final maxH = media.size.height - media.viewInsets.vertical - 40;
    final maxW = media.size.width - 40;
    final dialogH = maxH < 650 ? maxH : 650.0;
    final dialogW = maxW < 880 ? maxW : 880.0;

    final isDebt = _paymentType == 'debt';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.digit0): () => _onNumpadPress('0'),
          const SingleActivator(LogicalKeyboardKey.digit1): () => _onNumpadPress('1'),
          const SingleActivator(LogicalKeyboardKey.digit2): () => _onNumpadPress('2'),
          const SingleActivator(LogicalKeyboardKey.digit3): () => _onNumpadPress('3'),
          const SingleActivator(LogicalKeyboardKey.digit4): () => _onNumpadPress('4'),
          const SingleActivator(LogicalKeyboardKey.digit5): () => _onNumpadPress('5'),
          const SingleActivator(LogicalKeyboardKey.digit6): () => _onNumpadPress('6'),
          const SingleActivator(LogicalKeyboardKey.digit7): () => _onNumpadPress('7'),
          const SingleActivator(LogicalKeyboardKey.digit8): () => _onNumpadPress('8'),
          const SingleActivator(LogicalKeyboardKey.digit9): () => _onNumpadPress('9'),
          const SingleActivator(LogicalKeyboardKey.numpad0): () => _onNumpadPress('0'),
          const SingleActivator(LogicalKeyboardKey.numpad1): () => _onNumpadPress('1'),
          const SingleActivator(LogicalKeyboardKey.numpad2): () => _onNumpadPress('2'),
          const SingleActivator(LogicalKeyboardKey.numpad3): () => _onNumpadPress('3'),
          const SingleActivator(LogicalKeyboardKey.numpad4): () => _onNumpadPress('4'),
          const SingleActivator(LogicalKeyboardKey.numpad5): () => _onNumpadPress('5'),
          const SingleActivator(LogicalKeyboardKey.numpad6): () => _onNumpadPress('6'),
          const SingleActivator(LogicalKeyboardKey.numpad7): () => _onNumpadPress('7'),
          const SingleActivator(LogicalKeyboardKey.numpad8): () => _onNumpadPress('8'),
          const SingleActivator(LogicalKeyboardKey.numpad9): () => _onNumpadPress('9'),
          const SingleActivator(LogicalKeyboardKey.backspace): () => _onNumpadPress('⌫'),
          const SingleActivator(LogicalKeyboardKey.delete): () => _onNumpadPress('C'),
        },
        child: Focus(
          autofocus: true,
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
                  // Left Side: Calculator / Numpad
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
                            isDebt ? 'بڕی دراو بە نەختینە (لەم وەسڵەدا)' : 'بڕی پێدراو (لەلایەن کڕیارەوە)',
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
                                color: (isDebt ? const Color(0xFFD97706) : AppColors.primary).withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                            child: Text(
                              _inputAmountStr.isEmpty ? '0' : _currencyFormat.format(_givenAmount),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: isDebt ? const Color(0xFFD97706) : AppColors.primaryDark,
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
                                Expanded(child: _padRow([_numBtn('7'), _numBtn('8'), _numBtn('9')])),
                                const SizedBox(height: 8),
                                Expanded(child: _padRow([_numBtn('4'), _numBtn('5'), _numBtn('6')])),
                                const SizedBox(height: 8),
                                Expanded(child: _padRow([_numBtn('1'), _numBtn('2'), _numBtn('3')])),
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

                  // Right Side: Form Layout matching requested structure
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: پارەدان
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'پارەدان',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.ink),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (isDebt ? const Color(0xFFD97706) : AppColors.primary).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(AppRadius.pill),
                                ),
                                child: Text(
                                  isDebt ? 'فرۆشتنی قەرز' : 'فرۆشتنی نەختینە',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isDebt ? const Color(0xFFD97706) : AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Structured Breakdown Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                              boxShadow: AppShadows.card,
                            ),
                            child: Column(
                              children: [
                                // 1. کۆی پارە
                                _fieldRow(
                                  title: 'کۆی پارە',
                                  value: '${_currencyFormat.format(widget.totalAmount)} د.ع',
                                  valueColor: AppColors.ink,
                                  isBold: true,
                                ),
                                const Divider(height: 16),

                                // 2. جۆری پارەدان (نەختینە یان قەرز)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('جۆری پارەدان', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.inkSoft)),
                                    Row(
                                      children: [
                                        _typeBtn(
                                          label: '💵 نەختینە',
                                          selected: _paymentType == 'cash',
                                          selectedColor: AppColors.primary,
                                          onTap: () => setState(() => _paymentType = 'cash'),
                                        ),
                                        const SizedBox(width: 8),
                                        _typeBtn(
                                          label: '📋 قەرز',
                                          selected: _paymentType == 'debt',
                                          selectedColor: const Color(0xFFD97706),
                                          onTap: () => setState(() => _paymentType = 'debt'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const Divider(height: 16),

                                // 3. بڕی پارەدان لەم وەسڵە
                                _fieldRow(
                                  title: isDebt ? 'بڕی دراو (نەختینە)' : 'بڕی پارەدان لەم وەصلە',
                                  value: '${_currencyFormat.format(_givenAmount)} د.ع',
                                  valueColor: isDebt ? const Color(0xFF10B981) : AppColors.primary,
                                  isBold: true,
                                ),
                                const Divider(height: 16),

                                // 4. باقی قەرز / ماوە
                                if (isDebt)
                                  _fieldRow(
                                    title: 'باقی قەرز (دەبێتە قەرز)',
                                    value: '${_currencyFormat.format(_remainingDebt)} د.ع',
                                    valueColor: _remainingDebt > 0 ? const Color(0xFFD97706) : const Color(0xFF10B981),
                                    isBold: true,
                                    isBig: true,
                                  )
                                else
                                  _fieldRow(
                                    title: 'ماوە (گەڕاوە)',
                                    value: '${_currencyFormat.format(_changeAmount)} د.ع',
                                    valueColor: _givenAmount >= widget.totalAmount ? const Color(0xFF10B981) : AppColors.rose,
                                    isBold: true,
                                    isBig: true,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Customer fields if Debt is selected
                          if (isDebt) ...[
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Autocomplete customer name
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
                                                labelText: 'ناوی کڕیار (قەرزدار) *',
                                                prefixIcon: Icon(Icons.person_outline_rounded, size: 18),
                                                isDense: true,
                                                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 8),
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
                                    const SizedBox(height: 8),
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

                          // Confirmation Button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                if (isDebt) {
                                  if (_customerNameCtrl.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('تکایە ناوی کڕیار بنووسە')),
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
                                      const SnackBar(content: Text('بڕی پێدراو کەمترە لە کۆی پارە! دەتوانیت جۆری پارەدان بکەیتە قەرز.')),
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
                              icon: Icon(isDebt ? Icons.account_balance_wallet_rounded : Icons.check_rounded, size: 20),
                              label: Text(
                                isDebt
                                    ? (_givenAmount > 0
                                        ? 'تۆمارکردنی قەرز (${_currencyFormat.format(_remainingDebt)} د.ع باقی قەرز)'
                                        : 'تۆمارکردن بە قەرز (تەواوی بڕەکە)')
                                    : 'پەسەندکردن و فرۆشتن',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDebt ? const Color(0xFFD97706) : AppColors.primary,
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
                            height: 40,
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
        ),
      ),
    );
  }

  Widget _typeBtn({
    required String label,
    required bool selected,
    required Color selectedColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? selectedColor : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? selectedColor : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: selected ? Colors.white : AppColors.inkSoft,
          ),
        ),
      ),
    );
  }

  Widget _fieldRow({
    required String title,
    required String value,
    required Color valueColor,
    bool isBold = false,
    bool isBig = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: isBig ? 14.5 : 13.5,
            fontWeight: isBig ? FontWeight.bold : FontWeight.w600,
            color: AppColors.inkSoft,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBig ? 17 : 14.5,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
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
}
