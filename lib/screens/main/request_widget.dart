import 'package:flutter/material.dart';
import '../../models/request_model.dart';
import '../../models/header_item.dart';

class RequestEditor extends StatefulWidget {
  final RequestModel request;
  final VoidCallback onSave; // The callback to trigger the parent Project.save()

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

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.request.url);
    _bodyController = TextEditingController(text: widget.request.body);
    
    // Ensure nested lists aren't null for UI rendering
    widget.request.headersList ??= [];
    widget.request.queryParamsList ??= [];
  }

  @override
  void dispose() {
    _urlController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  // FIXED: Instead of request.save(), we use the callback
  void _saveRequest() {
    widget.request.url = _urlController.text;
    widget.request.body = _bodyController.text;
    widget.onSave(); // This tells the parent Project to save to Hive
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildAddressBar(),
        Expanded(
          child: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                const TabBar(
                  isScrollable: true,
                  tabs: [Tab(text: "Params"), Tab(text: "Headers"), Tab(text: "Body")],
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
              decoration: const InputDecoration(
                hintText: "https://api.example.com",
                border: OutlineInputBorder(borderRadius: BorderRadius.zero),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => _saveRequest(), 
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 19),
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

        return Row(
          children: [
            Expanded(
              child: TextField(
                controller: TextEditingController(text: item.key)..selection = TextSelection.collapsed(offset: item.key.length),
                decoration: const InputDecoration(hintText: "Key", contentPadding: EdgeInsets.all(12)),
                onChanged: (val) {
                  if (isNewRow && val.isNotEmpty) {
                    setState(() => items.add(HeaderItem(key: val, value: '')));
                  } else {
                    item.key = val;
                  }
                  isParams ? _syncUrlFromParams() : _saveRequest();
                },
              ),
            ),
            Expanded(
              child: TextField(
                controller: TextEditingController(text: item.value)..selection = TextSelection.collapsed(offset: item.value.length),
                decoration: const InputDecoration(hintText: "Value", contentPadding: EdgeInsets.all(12)),
                onChanged: (val) {
                  item.value = val;
                  isParams ? _syncUrlFromParams() : _saveRequest();
                },
              ),
            ),
            if (!isNewRow) IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () {
              setState(() => items.removeAt(index));
              isParams ? _syncUrlFromParams() : _saveRequest();
            }),
          ],
        );
      },
    );
  }

  Widget _buildBodyEditor() {
    return TextField(
      controller: _bodyController,
      maxLines: null,
      expands: true,
      onChanged: (_) => _saveRequest(),
      style: const TextStyle(fontFamily: 'monospace'),
      decoration: const InputDecoration(hintText: '{ "json": "here" }', contentPadding: EdgeInsets.all(12)),
    );
  }
}