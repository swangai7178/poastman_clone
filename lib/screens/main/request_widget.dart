import 'package:flutter/material.dart';
import '../../models/request_model.dart';
import '../../models/header_item.dart';

class RequestEditor extends StatefulWidget {
  final RequestModel request;

  const RequestEditor({super.key, required this.request});

  @override
  State<RequestEditor> createState() => _RequestEditorState();
}

class _RequestEditorState extends State<RequestEditor> {
  late TextEditingController _urlController;
  late TextEditingController _bodyController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.request.url);
    _bodyController = TextEditingController(text: widget.request.body);
    
    // Ensure lists are initialized so we don't hit null errors in the UI
    widget.request.headersList ??= [];
    widget.request.queryParamsList ??= [];
  }

  @override
  void dispose() {
    _urlController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  // --- LOGIC: SYNC PARAMS AND URL ---

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
    } catch (_) {
      // Handle invalid URI gracefully
    }
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

  void _saveRequest() {
    widget.request.url = _urlController.text;
    widget.request.body = _bodyController.text;
    widget.request.save(); // Persist to Hive
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // --- 1. ADDRESS BAR ---
        _buildAddressBar(),

        // --- 2. TABS SECTION ---
        Expanded(
          child: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                const TabBar(
                  isScrollable: true,
                  labelColor: Colors.blue,
                  unselectedLabelColor: Colors.grey,
                  indicatorSize: TabBarIndicatorSize.label,
                  tabs: [
                    Tab(text: "Params"),
                    Tab(text: "Headers"),
                    Tab(text: "Body"),
                  ],
                ),
                const Divider(height: 1),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildKeyValueEditor(widget.request.queryParamsList!, isParams: true),
                      _buildKeyValueEditor(widget.request.headersList!, isParams: false),
                      _buildBodyEditor(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddressBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), bottomLeft: Radius.circular(4)),
            ),
            child: DropdownButton<String>(
              value: widget.request.method,
              underline: const SizedBox(),
              items: ["GET", "POST", "PUT", "DELETE", "PATCH"]
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (val) {
                setState(() => widget.request.method = val!);
                _saveRequest();
              },
            ),
          ),
          Expanded(
            child: TextField(
              controller: _urlController,
              onChanged: _onUrlChanged,
              decoration: InputDecoration(
                hintText: "https://api.example.com/v1/resource",
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _saveRequest,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 19),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(topRight: Radius.circular(4), bottomRight: Radius.circular(4)),
              ),
            ),
            child: const Text("Send"),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyValueEditor(List<HeaderItem> items, {required bool isParams}) {
    return ListView.builder(
      itemCount: items.length + 1,
      itemBuilder: (context, index) {
        final bool isNewRow = index == items.length;
        final item = isNewRow ? HeaderItem(key: '', value: '') : items[index];

        return Container(
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
          child: Row(
            children: [
              _buildTableField(item.key, "Key", (val) {
                if (isNewRow && val.isNotEmpty) {
                  setState(() => items.add(HeaderItem(key: val, value: '')));
                } else {
                  item.key = val;
                }
                isParams ? _syncUrlFromParams() : _saveRequest();
              }),
              const VerticalDivider(width: 1),
              _buildTableField(item.value, "Value", (val) {
                item.value = val;
                isParams ? _syncUrlFromParams() : _saveRequest();
              }),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: isNewRow ? null : () {
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

  Widget _buildTableField(String initialValue, String hint, Function(String) onChanged) {
    return Expanded(
      child: TextField(
        controller: TextEditingController(text: initialValue)
          ..selection = TextSelection.collapsed(offset: initialValue.length),
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          contentPadding: const EdgeInsets.all(12),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildBodyEditor() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.grey.shade50,
      child: TextField(
        controller: _bodyController,
        onChanged: (_) => _saveRequest(),
        maxLines: null,
        expands: true,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
        decoration: const InputDecoration(
          hintText: '{ "key": "value" }',
          border: InputBorder.none,
        ),
      ),
    );
  }
}