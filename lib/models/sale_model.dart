class Sale {
  final int? id;
  final double totalAmount;
  final DateTime date;
  
  Sale({this.id, required this.totalAmount, required this.date});

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'],
      totalAmount: map['total_amount']?.toDouble() ?? 0.0,
      date: DateTime.parse(map['date']),
    );
  }
}
