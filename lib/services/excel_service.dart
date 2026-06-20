import 'dart:io';
import 'package:excel/excel.dart';
import '../models/item_model.dart';
import 'package:file_picker/file_picker.dart';

class ExcelService {
  static Future<bool> exportItemsToExcel(List<Item> items) async {
    try {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['کاڵاکان'];
      
      // Delete default Sheet1 if exists and we created a new one
      if (excel.tables.keys.contains('Sheet1')) {
        excel.delete('Sheet1');
      }

      // Headers
      sheetObject.appendRow([
        TextCellValue('بارکۆد'),
        TextCellValue('ناوی کاڵا'),
        TextCellValue('نرخی کڕین'),
        TextCellValue('نرخی فرۆشتن'),
        TextCellValue('بڕ'),
        TextCellValue('جۆر'),
      ]);

      // Data
      for (var item in items) {
        sheetObject.appendRow([
          TextCellValue(item.barcode),
          TextCellValue(item.name),
          DoubleCellValue(item.costPrice),
          DoubleCellValue(item.price),
          IntCellValue(item.quantity),
          TextCellValue(item.category ?? ''),
        ]);
      }

      var fileBytes = excel.save();
      if (fileBytes != null) {
        String? selectedDirectory = await FilePicker.getDirectoryPath();

        if (selectedDirectory != null) {
          String fileName = 'mini_market_items_${DateTime.now().millisecondsSinceEpoch}.xlsx';
          String outputFile = '$selectedDirectory/$fileName';
          File(outputFile)
            ..createSync(recursive: true)
            ..writeAsBytesSync(fileBytes);
          return true;
        }
      }
      return false;
    } catch (e) {
      print("Error exporting excel: $e");
      return false;
    }
  }

  static Future<List<Item>?> importItemsFromExcel() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result != null && result.files.single.path != null) {
        var bytes = File(result.files.single.path!).readAsBytesSync();
        var excel = Excel.decodeBytes(bytes);
        List<Item> items = [];

        for (var table in excel.tables.keys) {
          var sheet = excel.tables[table]!;
          // Skip header row
          for (int i = 1; i < sheet.maxRows; i++) {
            var row = sheet.row(i);
            if (row.isEmpty || row[0] == null) continue;

            try {
              String barcode = row[0]!.value.toString();
              String name = row.length > 1 && row[1] != null ? row[1]!.value.toString() : 'کاڵای نەناسراو';
              double costPrice = row.length > 2 && row[2] != null ? double.tryParse(row[2]!.value.toString()) ?? 0.0 : 0.0;
              double price = row.length > 3 && row[3] != null ? double.tryParse(row[3]!.value.toString()) ?? 0.0 : 0.0;
              int quantity = row.length > 4 && row[4] != null ? double.tryParse(row[4]!.value.toString())?.toInt() ?? 0 : 0;
              String category = row.length > 5 && row[5] != null ? row[5]!.value.toString() : '';

              items.add(Item(
                barcode: barcode,
                name: name,
                costPrice: costPrice,
                price: price,
                quantity: quantity,
                category: category.isNotEmpty ? category : null,
              ));
            } catch (e) {
              print("Error parsing row \$i: \$e");
            }
          }
        }
        return items;
      }
      return null;
    } catch (e) {
      print("Error importing excel: \$e");
      return null;
    }
  }
}
