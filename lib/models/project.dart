import 'package:wire_touch/models/collection.dart';

class Project {
  String id;
  String name;
  List<Collection> collections;

  Project({required this.id, required this.name, this.collections = const []});

  factory Project.fromMap(Map<String, dynamic> map) => 
      Project(id: map['id'], name: map['name'], collections: []);
}