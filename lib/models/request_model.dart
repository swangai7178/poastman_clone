import 'dart:convert';
import 'header_item.dart';

class RequestModel {
  String id;
  String name;
  String method;
  String url;
  String? body;
  List<HeaderItem>? headersList;
  List<HeaderItem>? queryParamsList;

  RequestModel({
    required this.id,
    required this.name,
    required this.method,
    required this.url,
    this.body,
    this.headersList,
    this.queryParamsList,
  });

  // SQL Map -> Object
  factory RequestModel.fromMap(Map<String, dynamic> map) {
    return RequestModel(
      id: map['id'],
      name: map['name'],
      method: map['method'],
      url: map['url'],
      body: map['body'],
      // Decode the JSON strings back into Lists
      headersList: map['headers'] != null 
          ? (jsonDecode(map['headers']) as List).map((i) => HeaderItem.fromJson(i)).toList()
          : [],
      queryParamsList: map['query_params'] != null 
          ? (jsonDecode(map['query_params']) as List).map((i) => HeaderItem.fromJson(i)).toList()
          : [],
    );
  }

  // Object -> SQL Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'method': method,
      'url': url,
      'body': body,
      // Encode the Lists into JSON strings for SQLite
      'headers': jsonEncode(headersList?.map((e) => e.toJson()).toList() ?? []),
      'query_params': jsonEncode(queryParamsList?.map((e) => e.toJson()).toList() ?? []),
    };
  }
}