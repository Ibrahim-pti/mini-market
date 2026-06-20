/// Normalizes a barcode string by converting Arabic/Kurdish digits
/// (٠١٢٣٤٥٦٧٨٩ and ۰۱۲۳۴۵۶۷۸۹) to Latin digits (0123456789).
///
/// This ensures barcodes always match regardless of the keyboard language
/// active when they were entered or scanned.
String normalizeBarcode(String input) {
  final buffer = StringBuffer();
  for (final codeUnit in input.runes) {
    // Arabic-Indic digits: ٠ (U+0660) – ٩ (U+0669)
    if (codeUnit >= 0x0660 && codeUnit <= 0x0669) {
      buffer.writeCharCode(0x0030 + (codeUnit - 0x0660));
    }
    // Extended Arabic-Indic digits (Persian/Kurdish): ۰ (U+06F0) – ۹ (U+06F9)
    else if (codeUnit >= 0x06F0 && codeUnit <= 0x06F9) {
      buffer.writeCharCode(0x0030 + (codeUnit - 0x06F0));
    }
    // Keep everything else as-is
    else {
      buffer.writeCharCode(codeUnit);
    }
  }
  return buffer.toString();
}
