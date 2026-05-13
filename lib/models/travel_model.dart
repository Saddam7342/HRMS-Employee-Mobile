class TravelRequest {
  final String id;
  final String destination;
  final String purpose;
  final DateTime fromDate;
  final DateTime toDate;
  final String status;
  final double? estimatedBudget;
  final DateTime? createdAt;

  TravelRequest({
    required this.id,
    required this.destination,
    required this.purpose,
    required this.fromDate,
    required this.toDate,
    required this.status,
    this.estimatedBudget,
    this.createdAt,
  });

  factory TravelRequest.fromJson(Map<String, dynamic> j) => TravelRequest(
        id: j['id'] ?? '',
        destination: j['destination'] ?? '',
        purpose: j['purpose'] ?? '',
        fromDate: DateTime.tryParse(j['fromDate'] ?? '')?.toLocal() ?? DateTime.now(),
        toDate: DateTime.tryParse(j['toDate'] ?? '')?.toLocal() ?? DateTime.now(),
        status: j['status'] ?? 'Pending',
        estimatedBudget: j['estimatedBudget'] != null
            ? ((j['estimatedBudget']) as num).toDouble()
            : null,
        createdAt: j['createdAt'] != null ? DateTime.tryParse(j['createdAt'])?.toLocal() : null,
      );

  int get tripDays => toDate.difference(fromDate).inDays + 1;
}
