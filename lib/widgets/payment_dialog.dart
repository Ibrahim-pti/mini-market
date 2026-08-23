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
  bool _isCreditMode = false;

  // Credit mode fields
  final TextEditingController _customerNameCtrl = TextEditingController();
  final TextEditingController _customerPhoneCtrl = TextEditingController();
  final TextEditingController _creditNotesCtrl = TextEditingController();
  final TextEditingController _creditInitialPayCtrl = TextEditingController(text: '0');

  @override
  void dispose() {
    _customerNameCtrl.dispose();
    _customerPhoneCtrl.dispose();
    _creditNotesCtrl.dispose();
    _creditInitialPayCtrl.dispose();
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
    final dialogH = maxH < 620 ? maxH : 620.0;
    final dialogW = maxW < 850 ? maxW : 850.0;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppColors.background,
      child: Container(
        width: dialogW,
        height: dialogH,
        padding: const EdgeInsets.all(0),
        child: Row(
          children: [
            // Left Side: Calculator / Quick Fill
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(24),
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
                      _isCreditMode ? 'بڕی پێشەکی (ئەگەر کڕیار بەشێکی دابێت)' : 'بڕی پێدراو (لەلایەن کڕیارەوە)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.inkSoft,
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Input Display
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: (_isCreditMode ? const Color(0xFFD97706) : AppColors.primary).withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Text(
                        _inputAmountStr.isEmpty ? '0' : _currencyFormat.format(_givenAmount),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: _isCreditMode ? const Color(0xFFD97706) : AppColors.primaryDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Quick Cash Buttons
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _quickBtn(5000),
                        _quickBtn(10000),
                        _quickBtn(25000),
                        _quickBtn(50000),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Numpad Grid
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: _padRow([_numBtn('7'), _numBtn('8'), _numBtn('9')]),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: _padRow([_numBtn('4'), _numBtn('5'), _numBtn('6')]),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: _padRow([_numBtn('1'), _numBtn('2'), _numBtn('3')]),
                          ),
                          const SizedBox(height: 10),
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
            // Right Side: Mode Switch & Totals/Debt Form
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mode Switcher (Cash vs Credit)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _isCreditMode = false),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: !_isCreditMode ? AppColors.surface : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: !_isCreditMode ? AppShadows.soft : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.payments_rounded,
                                      size: 18,
                                      color: !_isCreditMode ? AppColors.primary : AppColors.muted,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'نەختینە (کاش)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: !_isCreditMode ? AppColors.primary : AppColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _isCreditMode = true),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _isCreditMode ? const Color(0xFFD97706) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: _isCreditMode ? AppShadows.soft : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.account_balance_wallet_rounded,
                                      size: 18,
                                      color: _isCreditMode ? Colors.white : AppColors.muted,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'فرۆشتن بە قەرز',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: _isCreditMode ? Colors.white : AppColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (!_isCreditMode) ...[
                      Text('کورتەی وەسڵ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.ink)),
                      const SizedBox(height: 20),
                      _summaryRow('کۆی گشتی', widget.totalAmount, AppColors.ink, 22),
                      const Divider(height: 32),
                      _summaryRow('بڕی پێدراو', _givenAmount, AppColors.primary, 18),
                      const SizedBox(height: 16),
                      _summaryRow(
                        'ماوە',
                        _changeAmount,
                        _givenAmount >= widget.totalAmount ? AppColors.emerald : AppColors.rose,
                        24,
                      ),
                      const Spacer(),
                      // Confirm Cash Sale Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _givenAmount >= widget.totalAmount || _givenAmount == 0
                              ? () => Navigator.pop(
                                    context,
                                    PaymentResult(
                                      confirmed: true,
                                      isCredit: false,
                                      givenAmount: _givenAmount,
                                    ),
                                  )
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: const Text('پەسەندکردن و فرۆشتن', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ] else ...[
                      // Credit Sale Fields
                      Text('زانیاری کڕیار بۆ قەرز', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.ink)),
                      const SizedBox(height: 12),
                      // Known Debtors Autocomplete
                      Consumer<DebtProvider>(
                        builder: (context, debtProv, _) {
                          final knownNames = debtProv.allDebts
                              .where((d) => d.type == 'customer')
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
                                  prefixIcon: Icon(Icons.person_outline_rounded),
                                  isDense: true,
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
                          prefixIcon: Icon(Icons.phone_outlined),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _creditNotesCtrl,
                        decoration: const InputDecoration(
                          labelText: 'تێبینی (ئارەزوومەندانە)',
                          prefixIcon: Icon(Icons.notes_rounded),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('کۆی قەرز:', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                          Text(
                            '${_currencyFormat.format(widget.totalAmount)} د.ع',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                      if (_givenAmount > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('بڕی پێشەکی دراو:', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                            Text(
                              '${_currencyFormat.format(_givenAmount)} د.ع',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF10B981)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('ماوەی قەرز:', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                            Text(
                              '${_currencyFormat.format((widget.totalAmount - _givenAmount).clamp(0.0, widget.totalAmount))} د.ع',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.rose),
                            ),
                          ],
                        ),
                      ],
                      const Spacer(),
                      // Confirm Credit Sale Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: () {
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
                                notes: _creditNotesCtrl.text.trim().isEmpty ? null : _creditNotesCtrl.text.trim(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('پەسەندکردن و تۆمارکردن بە قەرز', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD97706),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, PaymentResult(confirmed: false)),
                        style: TextButton.styleFrom(foregroundColor: AppColors.muted),
                        child: const Text('پاشگەزبوونەوە', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickBtn(double amount) {
    return InkWell(
      onTap: () => _addQuickCash(amount),
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          _currencyFormat.format(amount),
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink, fontSize: 14),
        ),
      ),
    );
  }

  Widget _padRow(List<Widget> btns) {
    return Row(
      children: [
        Expanded(child: btns[0]),
        const SizedBox(width: 10),
        Expanded(child: btns[1]),
        const SizedBox(width: 10),
        Expanded(child: btns[2]),
      ],
    );
  }

  Widget _numBtn(String val, {Color? color, Color? textColor}) {
    return InkWell(
      onTap: () => _onNumpadPress(val),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: color ?? AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
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
            fontSize: 24,
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
        Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.inkSoft)),
        Text(
          '${_currencyFormat.format(amount)} د.ع',
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
