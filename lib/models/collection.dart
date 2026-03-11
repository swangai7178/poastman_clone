import 'package:wire_touch/models/request_model.dart';

class Collection {
  final String id;
  final String name;
  final String? parentId;
  final String projectId;
  List<Collection> subFolders = []; // Must be mutable
  List<RequestModel> requests = [];  // Must be mutable

  Collection({required this.id, required this.name, required this.projectId, this.parentId});

  factory Collection.fromMap(Map<String, dynamic> map) {
    return Collection(
      id: map['id'],
      name: map['name'],
      projectId: map['project_id'],
      parentId: map['parent_id'],
    );
  }
}