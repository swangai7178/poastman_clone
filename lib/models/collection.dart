import 'package:wire_touch/models/request_model.dart';

class Collection {
  String id;
  String name;
  String? parentId; // To track nested folders in SQL
  List<Collection> subFolders; // Nested folders
  List<RequestModel> requests; // API requests at this level

  Collection({
    required this.id,
    required this.name,
    this.parentId,
    this.subFolders = const [],
    this.requests = const [],
  });

  factory Collection.fromMap(Map<String, dynamic> map) => Collection(
        id: map['id'],
        name: map['name'],
        parentId: map['parent_id'],
        subFolders: [],
        requests: [],
      );
}