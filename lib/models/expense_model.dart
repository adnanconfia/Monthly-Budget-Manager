class ExpenseModel {
  final String id;
  final String title;
  final double amount;
  final String categoryId;
  final String note;
  final DateTime date;

  ExpenseModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.categoryId,
    this.note = '',
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'amount': amount,
    'categoryId': categoryId,
    'note': note,
    'date': date.toIso8601String(),
  };

  factory ExpenseModel.fromJson(Map<String, dynamic> json) => ExpenseModel(
    id: json['id'] as String,
    title: json['title'] as String,
    amount: (json['amount'] as num).toDouble(),
    categoryId: json['categoryId'] as String,
    note: json['note'] as String? ?? '',
    date: DateTime.parse(json['date'] as String),
  );
}