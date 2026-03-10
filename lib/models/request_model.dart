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

  @HiveField(6)
List<HeaderItem>? queryParamsList; 

  RequestModel({
    required this.id,
    required this.name,
    required this.method,
    required this.url,
    this.headersList,
    this.body,
    this.queryParamsList,
  });
}