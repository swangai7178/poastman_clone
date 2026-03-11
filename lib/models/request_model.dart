import 'package:hive/hive.dart';
import 'package:wire_touch/models/header_item.dart';

part 'request_model.g.dart';

@HiveType(typeId: 2)

class RequestModel extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String name;
  @HiveField(2)
  String method;
  @HiveField(3)
  String url;
  @HiveField(4)
  List<HeaderItem>? headersList;
  @HiveField(5)
  String? body;

  RequestModel({
    required this.id, required this.name, required this.method, 
    required this.url, this.headersList, this.body
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'method': method, 'url': url, 'body': body,
    'headersList': headersList?.map((e) => e.toJson()).toList(),
  };

  factory RequestModel.fromJson(Map<String, dynamic> json) => RequestModel(
    id: json['id'],
    name: json['name'],
    method: json['method'],
    url: json['url'],
    body: json['body'],
    headersList: (json['headersList'] as List?)?.map((e) => HeaderItem.fromJson(e)).toList(),
  );
}