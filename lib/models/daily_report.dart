/// Aggregated sales for a single day, used by the Reports screen.
class DailySalesReport {
  final String day; // 'YYYY-MM-DD'
  final int invoiceCount; // number of sales/invoices that day
  final double total; // total revenue that day
  final double profit; // gross profit that day

  DailySalesReport({
    required this.day,
    required this.invoiceCount,
    required this.total,
    required this.profit,
  });

  DateTime get date => DateTime.parse(day);
}

/// A single line in an invoice (one product sold).
class SaleLineItem {
  final String name;
  final int quantity;
  final double price; // price at the time of sale

  SaleLineItem({
    required this.name,
    required this.quantity,
    required this.price,
  });

  double get subtotal => quantity * price;
}
