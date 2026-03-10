import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';

import '../../models/request_model.dart';
import '../../models/header_item.dart';

class RequestBuilderPage extends StatefulWidget {
  final String projectId;
  final String collectionId;
  final RequestModel request;

  const RequestBuilderPage({
    super.key,
    required this.projectId,
    required this.collectionId,
    required this.request,
  });

  @override
  State<RequestBuilderPage> createState() => _RequestBuilderPageState();
}

class _RequestBuilderPageState extends State<RequestBuilderPage> {
  late String method;
  late TextEditingController urlController;
  late TextEditingController bodyController;

  List<HeaderItem> headers = [];
  String responseText = "";
  int statusCode = 0;

  @override
  void initState() {
    super.initState();

    method = widget.request.method;
    urlController = TextEditingController(text: widget.request.url);
    bodyController = TextEditingController(text: widget.request.body);

    headers = widget.request.headersList ?? [];
  }

  Future<void> sendRequest() async {
    final url = Uri.parse(urlController.text);

    Map<String, String> headersMap = {
      for (var h in headers) h.key: h.value,
    };

    http.Response response;

    try {
      switch (method) {
        case "POST":
          response = await http.post(url, headers: headersMap, body: bodyController.text);
          break;
        case "PUT":
          response = await http.put(url, headers: headersMap, body: bodyController.text);
          break;
        case "DELETE":
          response = await http.delete(url, headers: headersMap);
          break;
        default:
          response = await http.get(url, headers: headersMap);
      }

      setState(() {
        statusCode = response.statusCode;

        try {
          responseText = const JsonEncoder.withIndent('  ').convert(jsonDecode(response.body));
        } catch (e) {
          responseText = response.body;
        }
      });

      // Save request to Hive history
      final historyBox = Hive.box<RequestModel>('history');
      historyBox.add(widget.request);
    } catch (e) {
      setState(() {
        responseText = e.toString();
      });
    }
  }

  void addHeader() async {
    TextEditingController keyController = TextEditingController();
    TextEditingController valueController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Header"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: keyController, decoration: const InputDecoration(hintText: "Key")),
            TextField(controller: valueController, decoration: const InputDecoration(hintText: "Value")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (keyController.text.isNotEmpty) {
                setState(() {
                  headers.add(HeaderItem(key: keyController.text, value: valueController.text));
                });
              }
              Navigator.pop(context);
            },
            child: const Text("Add"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.request.name)),
      body: Column(
        children: [
          /// METHOD + URL + SEND
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                DropdownButton<String>(
                  value: method,
                  items: ["GET", "POST", "PUT", "DELETE", "PATCH"]
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) => setState(() => method = v!),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: urlController,
                    decoration: const InputDecoration(hintText: "Enter API URL", border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(onPressed: sendRequest, child: const Text("SEND")),
              ],
            ),
          ),

          /// BODY
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: bodyController,
              maxLines: 6,
              decoration: const InputDecoration(labelText: "Body (JSON)", border: OutlineInputBorder()),
            ),
          ),

          /// HEADERS
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Headers", style: TextStyle(fontWeight: FontWeight.bold)),
                ...headers.map((h) => Row(
                      children: [
                        Expanded(child: Text(h.key)),
                        Expanded(child: Text(h.value)),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            setState(() {
                              headers.remove(h);
                            });
                          },
                        ),
                      ],
                    )),
                ElevatedButton(onPressed: addHeader, child: const Text("Add Header")),
              ],
            ),
          ),

          const Divider(),

          /// RESPONSE
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text("Response Status: $statusCode", style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              child: SingleChildScrollView(
                child: Text(responseText, style: const TextStyle(fontFamily: "monospace")),
              ),
            ),
          ),
        ],
      ),
    );
  }
}