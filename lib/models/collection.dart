import 'package:wire_touch/models/request_model.dart';

class Collection {
  String id;
  String name;
  List<RequestModel> requests;

  Collection({required this.id, required this.name, this.requests = const []});

  factory Collection.fromMap(Map<String, dynamic> map) => 
      Collection(id: map['id'], name: map['name'], requests: []);
}