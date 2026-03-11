import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/request_model.dart';
import '../../models/header_item.dart';

class RequestEditor extends StatefulWidget {
  final RequestModel request;
  final VoidCallback onSave;

  const RequestEditor({
    super.key, 
    required this.request, 
    required this.onSave
  });

  @override
  State<RequestEditor> createState() => _RequestEditorState();
}

class _RequestEditorState extends State<RequestEditor> {
  late TextEditingController _urlController;
  late TextEditingController _bodyController;

  // Response States
  bool _isSending = false;
  String? _responseBody;
  int? _statusCode;
  String? _responseTime;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.request.url);
    _bodyController = TextEditingController(text: widget.request.body);
    
    // Safety initialization for Hive nested lists
    widget.request.headersList ??= [];
    widget.request.queryParamsList ??= [];
  }

  @override
  void dispose() {
    _urlController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  // --- CORE LOGIC: PERSISTENCE & SYNC ---

  void _saveRequest() {
    widget.request.url = _urlController.text;
    widget.request.body = _bodyController.text;
    widget.onSave(); // Triggers Project.save() in MainPage
  }

  void _onUrlChanged(String value) {
    widget.request.url = value;
    try {
      final uri = Uri.parse(value);
      if (uri.hasQuery) {
        setState(() {
          widget.request.queryParamsList = uri.queryParameters.entries
              .map((e) => HeaderItem(key: e.key, value: e.value))
              .toList();
        });
      }
    } catch (_) {}
    _saveRequest();
  }

  void _syncUrlFromParams() {
    try {
      final baseUri = Uri.parse(_urlController.text.split('?')[0]);
      final Map<String, String> params = {
        for (var item in widget.request.queryParamsList!)
          if (item.key.isNotEmpty) item.key: item.value
      };

      final newUri = baseUri.replace(queryParameters: params.isEmpty ? null : params);
      
      setState(() {
        _urlController.text = Uri.decodeFull(newUri.toString());
        widget.request.url = _urlController.text;
      });
      _saveRequest();
    } catch (_) {}
  }

  // --- NETWORK EXECUTION ---

  Future<void> _sendRequest() async {
    setState(() {
      _isSending = true;
      _responseBody = null;
    });

    final stopwatch = Stopwatch()..start();
    _saveRequest();

    try {
      final url = Uri.parse(widget.request.url);
      final headers = {
        for (var item in widget.request.headersList!)
          if (item.key.isNotEmpty) item.key: item.value,
        'Content-Type': 'application/json',
      };

      http.Response response;
      
      // Dynamic Method Handling
      switch (widget.request.method.toUpperCase()) {
        case 'POST':
          response = await http.post(url, headers: headers, body: widget.request.body);
          break;
        case 'PUT':
          response = await http.put(url, headers: headers, body: widget.request.body);
          break;
        case 'DELETE':
          response = await http.delete(url, headers: headers);
          break;
        default: // GET
          response = await http.get(url, headers: headers);
      }

      stopwatch.stop();
      setState(() {
        _statusCode = response.statusCode;
        // Attempt to pretty-print JSON if possible
        try {
          final decoded = json.decode(response.body);
          _responseBody = const JsonEncoder.withIndent('  ').convert(decoded);
        } catch (_) {
          _responseBody = response.body;
        }
        _responseTime = "${stopwatch.elapsedMilliseconds} ms";
      });
    } catch (e) {
      setState(() {
        _statusCode = 0;
        _responseBody = "Network Error: ${e.toString()}";
        _responseTime = "0 ms";
      });
    } finally {
      setState(() => _isSending = false);
    }
  }

  // --- UI BUILDING ---

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildAddressBar(),
        Expanded(
          flex: 2, 
          child: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                const TabBar(
                  isScrollable: true,
                  labelColor: Colors.blueAccent,
                  indicatorColor: Colors.blueAccent,
                  tabs: [Tab(text: "Params"), Tab(text: "Headers"), Tab(text: "Body")],
                ),
                const Divider(height: 1),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildKeyValueTable(widget.request.queryParamsList!, isParams: true),
                      _buildKeyValueTable(widget.request.headersList!, isParams: false),
                      _buildBodyEditor(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1, thickness: 1),
        Expanded(
          flex: 1, 
          child: _buildResponsePanel(),
        ),
      ],
    );
  }

  Widget _buildAddressBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          _buildMethodDropdown(),
          Expanded(
            child: TextField(
              controller: _urlController,
              onChanged: _onUrlChanged,
              decoration: const InputDecoration(
                hintText: "https://api.example.com",
                border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _isSending ? null : _sendRequest,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            ),
            child: _isSending 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text("Send"),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), bottomLeft: Radius.circular(4)),
      ),
      child: DropdownButton<String>(
        value: widget.request.method,
        underline: const SizedBox(),
        items: ["GET", "POST", "PUT", "DELETE", "PATCH"]
            .map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontWeight: FontWeight.bold))))
            .toList(),
        onChanged: (val) {
          setState(() => widget.request.method = val!);
          _saveRequest();
        },
      ),
    );
  }

  Widget _buildKeyValueTable(List<HeaderItem> items, {required bool isParams}) {
    return ListView.builder(
      itemCount: items.length + 1,
      itemBuilder: (context, index) {
        final bool isLast = index == items.length;
        final item = isLast ? HeaderItem(key: '', value: '') : items[index];

        return Container(
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
          child: Row(
            children: [
              _buildTableCell(item.key, "Key", (val) {
                if (isLast && val.isNotEmpty) {
                  setState(() => items.add(HeaderItem(key: val, value: '')));
                } else {
                  item.key = val;
                }
                isParams ? _syncUrlFromParams() : _saveRequest();
              }),
              const VerticalDivider(width: 1),
              _buildTableCell(item.value, "Value", (val) {
                item.value = val;
                isParams ? _syncUrlFromParams() : _saveRequest();
              }),
              IconButton(
                icon: const Icon(Icons.close, size: 14),
                onPressed: isLast ? null : () {
                  setState(() => items.removeAt(index));
                  isParams ? _syncUrlFromParams() : _saveRequest();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTableCell(String value, String hint, Function(String) onChanged) {
    return Expanded(
      child: TextField(
        controller: TextEditingController(text: value)..selection = TextSelection.collapsed(offset: value.length),
        onChanged: onChanged,
        decoration: InputDecoration(hintText: hint, contentPadding: const EdgeInsets.all(12), border: InputBorder.none),
      ),
    );
  }

  Widget _buildBodyEditor() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _bodyController,
        maxLines: null,
        expands: true,
        onChanged: (_) => _saveRequest(),
        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
        decoration: const InputDecoration(
          hintText: '{ "example": "json" }',
          border: OutlineInputBorder(),
          fillColor: Color(0xFFF5F5F5),
          filled: true,
        ),
      ),
    );
  }

  Widget _buildResponsePanel() {
    if (_isSending) return const Center(child: CircularProgressIndicator());
    if (_responseBody == null) return const Center(child: Text("Hit Send to see a response", style: TextStyle(color: Colors.grey)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.grey[100],
          child: Row(
            children: [
              const Text("Status: "),
              Text("$_statusCode", style: TextStyle(color: _statusCode! < 400 ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
              const SizedBox(width: 20),
              const Text("Time: "),
              Text(_responseTime!, style: const TextStyle(color: Colors.blue)),
            ],
          ),
        ),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              child: SelectableText(
                _responseBody!,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}