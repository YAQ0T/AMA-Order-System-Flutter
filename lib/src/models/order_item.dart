class OrderItemModel {
  const OrderItemModel({
    required this.id,
    required this.name,
    required this.quantity,
    this.status,
    this.price,
  });

  final int id;
  final String name;
  final double quantity;
  final String? status;
  final double? price;

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    final rawQty = json['quantity'];
    return OrderItemModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      name: json['name'] as String? ?? '',
      quantity: rawQty is num ? rawQty.toDouble() : double.tryParse('$rawQty') ?? 0,
      status: json['status'] as String?,
      price: json['price'] == null ? null : double.tryParse('${json['price']}'),
    );
  }
}
