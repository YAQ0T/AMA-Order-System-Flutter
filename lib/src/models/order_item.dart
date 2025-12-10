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
  final int quantity;
  final String? status;
  final double? price;

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      name: json['name'] as String? ?? '',
      quantity: json['quantity'] is int
          ? json['quantity'] as int
          : int.tryParse('${json['quantity']}') ?? 0,
      status: json['status'] as String?,
      price: json['price'] == null ? null : double.tryParse('${json['price']}'),
    );
  }
}
