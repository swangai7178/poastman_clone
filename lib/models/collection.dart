import 'package:hive/hive.dart';
import 'request_model.dart';

part 'collection.g.dart';

@HiveType(typeId: 1)
class Collection extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String name;
  @HiveField(2)
  List<RequestModel> requests;

  Collection({required this.id, required this.name, this.requests = const []});

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name,
    'requests': requests.map((e) => e.toJson()).toList(),
  };

  factory Collection.fromJson(Map<String, dynamic> json) => Collection(
    id: json['id'],
    name: json['name'],
    requests: (json['requests'] as List).map((e) => RequestModel.fromJson(e)).toList(),
  );
}