import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../models/request_model.dart';
import '../../models/header_item.dart';

class RequestEditor extends StatefulWidget {
  final RequestModel request;
  final VoidCallback onSave;

  const RequestEditor({super.key, required this.request, required this.onSave});

  @override
  State<RequestEditor> createState() => _RequestEditorState();
}

class _RequestEditorState extends State<RequestEditor> {
  late TextEditingController _urlController;
  late TextEditingController _bodyController;

  bool _isSending = false;
  String? _responseBody;
  int? _statusCode;
  String? _responseTime;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.request.url);
    _bodyController = TextEditingController(text: widget.request.body);
    widget.request.headersList ??= [];
    widget.request.queryParamsList ??= [];
  }

  @override
  void dispose() {
    _urlController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  // --- LOGIC ---

  void _saveRequest() {
    widget.request.url = _urlController.text;
    widget.request.body = _bodyController.text;
    widget.onSave();
  }

  // --- UI COMPONENTS ---

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          _buildAddressBar(),
          const Divider(height: 1),
          Expanded(
            flex: 3,
            child: _buildConfigTabs(),
          ),
          const Divider(height: 1, thickness: 2),
          Expanded(
            flex: 2,
            child: _buildResponsePanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressBar() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          _buildMethodDropdown(),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white12),
              ),
              child: TextField(
                controller: _urlController,
                style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                decoration: const InputDecoration(
                  hintText: "Enter URL or paste text",
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onChanged: (val) {
                  widget.request.url = val;
                  _saveRequest();
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildSendButton(),
        ],
      ),
    );
  }

  Widget _buildMethodDropdown() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _getMethodColor(widget.request.method).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _getMethodColor(widget.request.method).withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: widget.request.method,
          style: TextStyle(color: _getMethodColor(widget.request.method), fontWeight: FontWeight.bold, fontSize: 12),
          items: ["GET", "POST", "PUT", "DELETE", "PATCH"]
              .map((m) => DropdownMenuItem(value: m, child: Text(m)))
              .toList(),
          onChanged: (val) {
            setState(() => widget.request.method = val!);
            _saveRequest();
          },
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return SizedBox(
      height: 40,
      child: ElevatedButton(
        onPressed: _isSending ? null : _sendRequest,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        child: _isSending 
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Text("Send", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildConfigTabs() {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            indicatorSize: TabBarIndicatorSize.label,
            indicatorWeight: 3,
            tabs: const [Tab(text: "Params"), Tab(text: "Headers"), Tab(text: "Body")],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildTable(widget.request.queryParamsList!),
                _buildTable(widget.request.headersList!),
                _buildMonospaceEditor(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(List<HeaderItem> items) {
    return ListView.builder(
      itemCount: items.length + 1,
      itemBuilder: (context, index) {
        final isLast = index == items.length;
        final item = isLast ? HeaderItem(key: '', value: '') : items[index];

        return Container(
          height: 35,
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white10))),
          child: Row(
            children: [
              _buildCell(item.key, "Key", (v) {
                if (isLast && v.isNotEmpty) {
                  setState(() => items.add(HeaderItem(key: v, value: '')));
                } else {
                  item.key = v;
                }
                _saveRequest();
              }),
              const VerticalDivider(width: 1),
              _buildCell(item.value, "Value", (v) {
                item.value = v;
                _saveRequest();
              }),
              SizedBox(
                width: 30,
                child: !isLast ? IconButton(
                  icon: const Icon(Icons.close, size: 14),
                  onPressed: () => setState(() => items.removeAt(index)),
                ) : null,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCell(String val, String hint, Function(String) onCHanged) {
    return Expanded(
      child: TextField(
        controller: TextEditingController(text: val)..selection = TextSelection.collapsed(offset: val.length),
        onChanged: onCHanged,
        style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 11, color: Colors.grey),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildMonospaceEditor() {
    return Container(
      color: Colors.black.withOpacity(0.02),
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: _bodyController,
        maxLines: null,
        onChanged: (_) => _saveRequest(),
        style: const TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.5),
        decoration: const InputDecoration(border: InputBorder.none, hintText: '// Raw JSON Body'),
      ),
    );
  }

  Widget _buildResponsePanel() {
    if (_isSending) return const Center(child: CircularProgressIndicator());
    if (_responseBody == null) return const Center(child: Text("Ready", style: TextStyle(color: Colors.grey, fontSize: 12)));

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: Colors.black.withOpacity(0.05),
          child: Row(
            children: [
              _statusChip(),
              const SizedBox(width: 12),
              Text(_responseTime ?? "", style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.copy, size: 14), onPressed: () {}),
            ],
          ),
        ),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              child: SelectableText(_responseBody!, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusChip() {
    final success = _statusCode != null && _statusCode! < 400;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: success ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        "$_statusCode ${_getStatusText(_statusCode!)}",
        style: TextStyle(color: success ? Colors.green : Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  // --- NETWORK ---

  Future<void> _sendRequest() async {
    setState(() => _isSending = true);
    final sw = Stopwatch()..start();
    try {
      final uri = Uri.parse(_urlController.text);
      final headers = {for (var h in widget.request.headersList!) if (h.key.isNotEmpty) h.key: h.value};
      
      http.Response res;
      if (widget.request.method == "POST") {
        res = await http.post(uri, headers: headers, body: _bodyController.text);
      } else if (widget.request.method == "PUT") res = await http.put(uri, headers: headers, body: _bodyController.text);
      else if (widget.request.method == "DELETE") res = await http.delete(uri, headers: headers);
      else res = await http.get(uri, headers: headers);

      _statusCode = res.statusCode;
      _responseTime = "${sw.elapsedMilliseconds}ms";
      try {
        _responseBody = const JsonEncoder.withIndent('  ').convert(json.decode(res.body));
      } catch (_) {
        _responseBody = res.body;
      }
    } catch (e) {
      _responseBody = e.toString();
      _statusCode = 500;
    } finally {
      setState(() => _isSending = false);
    }
  }

  Color _getMethodColor(String m) {
    switch (m) {
      case "GET": return Colors.green;
      case "POST": return Colors.blue;
      case "DELETE": return Colors.red;
      case "PUT": return Colors.orange;
      default: return Colors.purple;
    }
  }

  String _getStatusText(int code) {
    if (code == 200) return "OK";
    if (code == 201) return "Created";
    if (code == 401) return "Unauthorized";
    if (code == 404) return "Not Found";
    return "";
  }
}