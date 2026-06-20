import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class PaymentDialog extends StatefulWidget {
  final double totalAmount;

  const PaymentDialog({super.key, required this.totalAmount});

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final NumberFormat _currencyFormat = NumberFormat('#,##0', 'en_US');
  String _inputAmountStr = '';

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
        // Prevent too long inputs
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppColors.background,
      child: Container(
        width: 800,
        height: 600,
        padding: const EdgeInsets.all(0),
        child: Row(
          children: [
            // Left Side: Calculator/Numpad
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Text('بڕی پێدراو (لەلایەن کڕیارەوە)',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.inkSoft)),
                    const SizedBox(height: 16),
                    // Input Display
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
                      ),
                      child: Text(
                        _inputAmountStr.isEmpty
                            ? '0'
                            : _currencyFormat.format(_givenAmount),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Quick Cash Buttons
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        _quickBtn(5000),
                        _quickBtn(10000),
                        _quickBtn(25000),
                        _quickBtn(50000),
                      ],
                    ),
                    const Spacer(),
                    // Numpad Grid
                    Expanded(
                      flex: 6,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return GridView.count(
                            crossAxisCount: 3,
                            childAspectRatio: 1.6,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              _numBtn('7'), _numBtn('8'), _numBtn('9'),
                              _numBtn('4'), _numBtn('5'), _numBtn('6'),
                              _numBtn('1'), _numBtn('2'), _numBtn('3'),
                              _numBtn('C', color: AppColors.roseSoft, textColor: AppColors.rose),
                              _numBtn('0'),
                              _numBtn('000'),
                            ],
                          );
                        }
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Right Side: Totals and Confirm
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('کورتەی وەسڵ',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.ink)),
                    const SizedBox(height: 32),
                    _summaryRow('کۆی گشتی', widget.totalAmount, AppColors.ink, 24),
                    Divider(height: 48),
                    _summaryRow('بڕی پێدراو', _givenAmount, AppColors.primary, 20),
                    const SizedBox(height: 24),
                    _summaryRow('ماوە', _changeAmount, _givenAmount >= widget.totalAmount ? AppColors.emerald : AppColors.rose, 28),
                    
                    const Spacer(),
                    // Confirm Button
                    SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: ElevatedButton(
                        onPressed: _givenAmount >= widget.totalAmount || _givenAmount == 0
                            ? () => Navigator.pop(context, true)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: Text('پەسەندکردن و فرۆشتن',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.muted,
                        ),
                        child: Text('پاشگەزبوونەوە', style: TextStyle(fontSize: 18)),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text('${_currencyFormat.format(amount)}',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink, fontSize: 16)),
      ),
    );
  }

  Widget _numBtn(String val, {Color? color, Color? textColor}) {
    return InkWell(
      onTap: () => _onNumpadPress(val),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color ?? AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          val,
          style: TextStyle(
            fontSize: 28,
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
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.inkSoft)),
        Text('${_currencyFormat.format(amount)} د.ع',
            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
