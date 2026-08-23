class DebtPayment {
  final int? id;
  final int debtId;
  final double amount;
  final DateTime date;
  final String? notes;

  DebtPayment({
    this.id,
    required this.debtId,
    required this.amount,
    required this.date,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'debt_id': debtId,
      'amount': amount,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }

  factory DebtPayment.fromMap(Map<String, dynamic> map) {
    return DebtPayment(
      id: map['id'] as int?,
      debtId: (map['debt_id'] as num).toInt(),
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      notes: map['notes'] as String?,
    );
  }
}
