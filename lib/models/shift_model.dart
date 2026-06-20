class Shift {
  int? id;
  String startTime;
  String? endTime;
  double startingCash;
  double? expectedEndingCash;
  double? actualEndingCash;
  String status; // 'open' or 'closed'

  Shift({
    this.id,
    required this.startTime,
    this.endTime,
    required this.startingCash,
    this.expectedEndingCash,
    this.actualEndingCash,
    this.status = 'open',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'start_time': startTime,
      'end_time': endTime,
      'starting_cash': startingCash,
      'expected_ending_cash': expectedEndingCash,
      'actual_ending_cash': actualEndingCash,
      'status': status,
    };
  }

  factory Shift.fromMap(Map<String, dynamic> map) {
    return Shift(
      id: map['id'],
      startTime: map['start_time'],
      endTime: map['end_time'],
      startingCash: map['starting_cash'],
      expectedEndingCash: map['expected_ending_cash'],
      actualEndingCash: map['actual_ending_cash'],
      status: map['status'],
    );
  }
}
