import 'package:hive/hive.dart';
import 'collection.dart';

part 'project.g.dart';
@HiveType(typeId: 0)
class Project extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String name;
  @HiveField(2)
  List<Collection> collections;

  Project({required this.id, required this.name, this.collections = const []});

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name,
    'collections': collections.map((e) => e.toJson()).toList(),
  };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
    id: json['id'],
    name: json['name'],
    collections: (json['collections'] as List).map((e) => Collection.fromJson(e)).toList(),
  );
}