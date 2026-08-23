class Debt {
  final int? id;
  final String personName;
  final String? phone;
  final double amount;
  final double paidAmount;
  /// 'customer' (قەرزی سەر کڕیار) or 'supplier' (قەرزی سەر خۆمان / دابینکەر)
  final String type;
  final DateTime date;
  final DateTime? dueDate;
  final String? notes;

  Debt({
    this.id,
    required this.personName,
    this.phone,
    required this.amount,
    this.paidAmount = 0.0,
    this.type = 'customer',
    required this.date,
    this.dueDate,
    this.notes,
  });

  double get remainingAmount => (amount - paidAmount) > 0 ? (amount - paidAmount) : 0.0;
  bool get isFullyPaid => remainingAmount <= 0.001;
  bool get isPartiallyPaid => paidAmount > 0 && !isFullyPaid;
  double get paymentPercentage => amount > 0 ? ((paidAmount / amount) * 100).clamp(0.0, 100.0) : 0.0;

  bool get isOverdue {
    if (isFullyPaid || dueDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return today.isAfter(due);
  }

  Debt copyWith({
    int? id,
    String? personName,
    String? phone,
    double? amount,
    double? paidAmount,
    String? type,
    DateTime? date,
    DateTime? dueDate,
    String? notes,
  }) {
    return Debt(
      id: id ?? this.id,
      personName: personName ?? this.personName,
      phone: phone ?? this.phone,
      amount: amount ?? this.amount,
      paidAmount: paidAmount ?? this.paidAmount,
      type: type ?? this.type,
      date: date ?? this.date,
      dueDate: dueDate ?? this.dueDate,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'personName': personName,
      'phone': phone,
      'amount': amount,
      'paid_amount': paidAmount,
      'type': type,
      'date': date.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'notes': notes,
    };
  }

  factory Debt.fromMap(Map<String, dynamic> map) {
    return Debt(
      id: map['id'] as int?,
      personName: (map['personName'] ?? map['person_name'] ?? '') as String,
      phone: map['phone'] as String?,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (map['paid_amount'] as num?)?.toDouble() ?? 0.0,
      type: (map['type'] ?? 'customer') as String,
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      dueDate: map['due_date'] != null ? DateTime.tryParse(map['due_date'].toString()) : null,
      notes: map['notes'] as String?,
    );
  }
}
