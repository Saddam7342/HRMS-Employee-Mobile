class ExpenseClaim {
  final String id;
  final String title;
  final String category;
  final double amount;
  final String currency;
  final String status;
  final DateTime claimDate;
  final String? description;
  final String? receiptUrl;

  ExpenseClaim({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.currency,
    required this.status,
    required this.claimDate,
    this.description,
    this.receiptUrl,
  });

  factory ExpenseClaim.fromJson(Map<String, dynamic> j) => ExpenseClaim(
        id: j['id'] ?? '',
        title: j['title'] ?? j['description'] ?? 'Expense',
        category: j['category'] ?? j['categoryName'] ?? '',
        amount: ((j['amount'] ?? 0) as num).toDouble(),
        currency: j['currency'] ?? 'PKR',
        status: j['status'] ?? 'Pending',
        claimDate: DateTime.tryParse(j['claimDate'] ?? j['createdAt'] ?? '')?.toLocal() ?? DateTime.now(),
        description: j['description'],
        receiptUrl: j['receiptUrl'],
      );
}

class ExpenseCategory {
  final String id;
  final String name;

  ExpenseCategory({required this.id, required this.name});

  factory ExpenseCategory.fromJson(Map<String, dynamic> j) => ExpenseCategory(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
      );
}
