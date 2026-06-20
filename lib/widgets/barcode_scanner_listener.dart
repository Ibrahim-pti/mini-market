import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/barcode_utils.dart';

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
    // Only the topmost route should react to scans. When a dialog (e.g. the
    // add-item dialog) is open above this listener, its own route is no longer
    // current, so we ignore the scan here and let the dialog's listener handle
    // it. This prevents a scanned barcode from leaking into the search field
    // behind the open dialog.
    if (!mounted) return false;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return false;

    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (_barcodeBuffer.length >= 3) {
          // A complete barcode was scanned — normalize digits
          widget.onBarcodeScanned(normalizeBarcode(_barcodeBuffer));
        }
        _barcodeBuffer = '';
      } else if (event.character != null) {
        final now = DateTime.now();
        if (_lastKeyPressTime == null ||
            now.difference(_lastKeyPressTime!) > widget.scanTimeout) {
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
