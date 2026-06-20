import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _display = '0';
  double? _operand;
  String? _op;
  bool _startNew = true;
  bool _justEvaluated = false;

  String _format(double v) {
    if (v.isNaN || v.isInfinite) return 'هەڵە';
    if (v == v.roundToDouble() && v.abs() < 1e15) {
      return v.toInt().toString();
    }
    return v.toString();
  }

  double _compute(double a, double b, String op) {
    switch (op) {
      case '+':
        return a + b;
      case '−':
        return a - b;
      case '×':
        return a * b;
      case '÷':
        return b == 0 ? double.nan : a / b;
    }
    return b;
  }

  void _onDigit(String d) {
    setState(() {
      if (_display == 'هەڵە') _display = '0';
      if (_startNew || _display == '0') {
        _display = d;
        _startNew = false;
      } else {
        _display += d;
      }
      _justEvaluated = false;
    });
  }

  void _onDot() {
    setState(() {
      if (_startNew) {
        _display = '0';
        _startNew = false;
      }
      if (!_display.contains('.')) _display += '.';
      _justEvaluated = false;
    });
  }

  void _onOperator(String op) {
    setState(() {
      final value = double.tryParse(_display) ?? 0;
      if (_operand == null) {
        _operand = value;
      } else if (!_startNew) {
        final result = _compute(_operand!, value, _op!);
        _operand = result;
        _display = _format(result);
      }
      _op = op;
      _startNew = true;
      _justEvaluated = false;
    });
  }

  void _onEquals() {
    if (_op == null || _operand == null) return;
    setState(() {
      final value = double.tryParse(_display) ?? 0;
      final result = _compute(_operand!, value, _op!);
      _display = _format(result);
      _operand = null;
      _op = null;
      _startNew = true;
      _justEvaluated = true;
    });
  }

  void _onClear() {
    setState(() {
      _display = '0';
      _operand = null;
      _op = null;
      _startNew = true;
      _justEvaluated = false;
    });
  }

  void _onSign() {
    setState(() {
      if (_display == '0' || _display == 'هەڵە') return;
      _display = _display.startsWith('-')
          ? _display.substring(1)
          : '-$_display';
    });
  }

  void _onPercent() {
    setState(() {
      final value = double.tryParse(_display) ?? 0;
      _display = _format(value / 100);
      _justEvaluated = true;
      _startNew = true;
    });
  }

  void _onBackspace() {
    setState(() {
      if (_justEvaluated || _startNew || _display == 'هەڵە') return;
      if (_display.length <= 1 || (_display.length == 2 && _display.startsWith('-'))) {
        _display = '0';
        _startNew = true;
      } else {
        _display = _display.substring(0, _display.length - 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Display
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppShadows.card,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SizedBox(
                        height: 22,
                        child: Text(
                          _operand != null && _op != null
                              ? '${_format(_operand!)} $_op'
                              : '',
                          style: TextStyle(
                              color: AppColors.muted, fontSize: 18),
                        ),
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          _display,
                          maxLines: 1,
                          style: TextStyle(
                              color: AppColors.ink,
                              fontSize: 48,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Keypad
                _row([
                  _key('C', type: _KeyType.danger, onTap: _onClear),
                  _key('±', type: _KeyType.muted, onTap: _onSign),
                  _key('%', type: _KeyType.muted, onTap: _onPercent),
                  _key('÷', type: _KeyType.op, onTap: () => _onOperator('÷')),
                ]),
                _row([
                  _key('7', onTap: () => _onDigit('7')),
                  _key('8', onTap: () => _onDigit('8')),
                  _key('9', onTap: () => _onDigit('9')),
                  _key('×', type: _KeyType.op, onTap: () => _onOperator('×')),
                ]),
                _row([
                  _key('4', onTap: () => _onDigit('4')),
                  _key('5', onTap: () => _onDigit('5')),
                  _key('6', onTap: () => _onDigit('6')),
                  _key('−', type: _KeyType.op, onTap: () => _onOperator('−')),
                ]),
                _row([
                  _key('1', onTap: () => _onDigit('1')),
                  _key('2', onTap: () => _onDigit('2')),
                  _key('3', onTap: () => _onDigit('3')),
                  _key('+', type: _KeyType.op, onTap: () => _onOperator('+')),
                ]),
                _row([
                  _key('⌫', type: _KeyType.muted, onTap: _onBackspace),
                  _key('0', onTap: () => _onDigit('0')),
                  _key('.', onTap: _onDot),
                  _key('=', type: _KeyType.equals, onTap: _onEquals),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(List<Widget> children) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: children),
      ),
    );
  }

  Widget _key(String label,
      {_KeyType type = _KeyType.digit, required VoidCallback onTap}) {
    late Color bg;
    late Color fg;
    Gradient? gradient;
    switch (type) {
      case _KeyType.digit:
        bg = AppColors.surface;
        fg = AppColors.ink;
        break;
      case _KeyType.muted:
        bg = AppColors.surfaceAlt;
        fg = AppColors.inkSoft;
        break;
      case _KeyType.op:
        bg = AppColors.violetSoft;
        fg = AppColors.primaryDark;
        break;
      case _KeyType.danger:
        bg = AppColors.roseSoft;
        fg = AppColors.rose;
        break;
      case _KeyType.equals:
        bg = AppColors.primary;
        fg = Colors.white;
        gradient = AppGradients.brand;
        break;
    }
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Material(
          color: gradient == null ? bg : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Ink(
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: type == _KeyType.digit
                  ? Border.all(color: AppColors.border)
                  : null,
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                      color: fg,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _KeyType { digit, muted, op, danger, equals }
