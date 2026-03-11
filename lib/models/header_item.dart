import 'package:hive/hive.dart';

part 'header_item.g.dart';

@HiveType(typeId: 3) // make sure typeId is unique
@HiveType(typeId: 3)
class HeaderItem extends HiveObject {
  @HiveField(0)
  String key;
  @HiveField(1)
  String value;

  HeaderItem({required this.key, required this.value});

  Map<String, dynamic> toJson() => {'key': key, 'value': value};
  factory HeaderItem.fromJson(Map<String, dynamic> json) => 
      HeaderItem(key: json['key'], value: json['value']);
}