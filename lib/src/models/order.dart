import 'order_item.dart';
import 'order_log.dart';
import 'user.dart';

const kOrderCities = [
  'نابلس',
  'الخليل',
  'جنين',
  'طولكرم',
  'بديا',
  'قلقيليا',
  'رامالله',
  'بيت لحم',
  'الداخل',
];

const kDefaultOrderCity = 'نابلس';

class OrderModel {
  const OrderModel({
    required this.id,
    required this.status,
    required this.createdAt,
    this.title,
    this.description,
    this.city,
    this.maker,
    this.accounter,
    this.assignedTakers = const [],
    this.items = const [],
    this.history = const [],
  });

  final int id;
  final String status;
  final DateTime createdAt;
  final String? title;
  final String? description;
  final String? city;
  final AppUser? maker;
  final AppUser? accounter;
  final List<AppUser> assignedTakers;
  final List<OrderItemModel> items;
  final List<OrderLogEntry> history;

  String get titleOrFallback => title?.isNotEmpty == true ? title! : 'Order #$id';

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      title: json['title'] as String?,
      description: json['description'] as String?,
      city: json['city'] as String?,
      maker: json['Maker'] == null ? null : AppUser.fromJson(json['Maker'] as Map<String, dynamic>),
      accounter: json['Accounter'] == null
          ? null
          : AppUser.fromJson(json['Accounter'] as Map<String, dynamic>),
      assignedTakers: (json['AssignedTakers'] as List<dynamic>? ?? [])
          .map((u) => AppUser.fromJson(u as Map<String, dynamic>))
          .toList(),
      items: (json['Items'] as List<dynamic>? ?? [])
          .map((item) => OrderItemModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      history: (json['History'] as List<dynamic>? ?? [])
          .map((log) => OrderLogEntry.fromJson(log as Map<String, dynamic>))
          .toList(),
    );
  }
}

class OrderDraft {
  OrderDraft({
    this.title,
    this.description,
    this.city = kDefaultOrderCity,
    this.items = const [],
    this.assignedTakerIds = const [],
    this.accounterId,
    this.status,
  });

  String? title;
  String? description;
  String city;
  List<OrderItemInput> items;
  List<int> assignedTakerIds;
  int? accounterId;
  String? status;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'city': city,
      'items': items.map((e) => e.toJson()).toList(),
      'assignedTakerIds': assignedTakerIds,
      'accounterId': accounterId,
      if (status != null) 'status': status,
    };
  }
}

class OrderItemInput {
  OrderItemInput({this.name = '', this.quantity = 1.0, this.price});

  String name;
  double quantity;
  double? price;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'price': price,
    };
  }
}
