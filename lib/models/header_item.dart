import 'package:hive/hive.dart';

part 'header_item.g.dart';

@HiveType(typeId: 3) // make sure typeId is unique
class HeaderItem extends HiveObject {
  @HiveField(0)
  String key;

  @HiveField(1)
  String value;

  HeaderItem({required this.key, required this.value});
}