import 'package:hive/hive.dart';

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
  Map<String, String>? headers;

  @HiveField(5)
  String? body;

  RequestModel({
    required this.id,
    required this.name,
    required this.method,
    required this.url,
    this.headers,
    this.body,
  });
}