import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BarcodeScannerListener extends StatefulWidget {
  final Widget child;
  final ValueChanged<String> onBarcodeScanned;
  final Duration scanTimeout;

  const BarcodeScannerListener({
    super.key,
    required this.child,
    required this.onBarcodeScanned,
    this.scanTimeout = const Duration(milliseconds: 100),
  });

  @override
  State<BarcodeScannerListener> createState() => _BarcodeScannerListenerState();
}

class _BarcodeScannerListenerState extends State<BarcodeScannerListener> {
  String _barcodeBuffer = '';
  DateTime? _lastKeyPressTime;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (_barcodeBuffer.length >= 3) {
          // A complete barcode was scanned
          widget.onBarcodeScanned(_barcodeBuffer);
        }
        _barcodeBuffer = '';
      } else if (event.character != null) {
        final now = DateTime.now();
        if (_lastKeyPressTime == null || now.difference(_lastKeyPressTime!) > widget.scanTimeout) {
          // Slow typing -> Reset buffer (this might be a human typing in a normal text field)
          _barcodeBuffer = event.character!;
        } else {
          // Fast typing (Scanner) -> Append to buffer
          _barcodeBuffer += event.character!;
        }
        _lastKeyPressTime = now;
      }
    }
    // Always return false so we don't accidentally block normal text fields 
    // when the user is actually typing normally.
    return false; 
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
