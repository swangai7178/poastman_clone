
import 'package:http/http.dart' as http;
import '../../models/request_model.dart';

class HttpService {
  static Future<http.Response> sendRequest(RequestModel request) async {
    final url = Uri.parse(request.url);
    
    // Map our HeaderItem list to a Map<String, String>
    final Map<String, String> headers = {
      for (var item in request.headersList ?? [])
        if (item.key.isNotEmpty) item.key: item.value,
      'Content-Type': 'application/json', // Default for Postman clones
    };

    switch (request.method.toUpperCase()) {
      case 'POST':
        return await http.post(url, headers: headers, body: request.body);
      case 'PUT':
        return await http.put(url, headers: headers, body: request.body);
      case 'DELETE':
        return await http.delete(url, headers: headers);
      case 'GET':
      default:
        return await http.get(url, headers: headers);
    }
  }
}