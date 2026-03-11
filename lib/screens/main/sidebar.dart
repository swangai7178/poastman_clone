import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../core/services/database_service.dart';
import '../../models/collection.dart';
import '../../models/project.dart';
import '../../models/request_model.dart';

class ProjectSidebar extends StatefulWidget {
  final List<Project> projects;
  final Function(Project, RequestModel) onRequestSelected;
  final VoidCallback onRefresh;

  const ProjectSidebar({
    super.key,
    required this.projects,
    required this.onRequestSelected,
    required this.onRefresh,
  });

  @override
  State<ProjectSidebar> createState() => _ProjectSidebarState();
}

class _ProjectSidebarState extends State<ProjectSidebar> {
  final uuid = const Uuid();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(right: BorderSide(color: Colors.white12.withOpacity(0.05))),
      ),
      child: ListView.builder(
        itemCount: widget.projects.length,
        itemBuilder: (context, index) => _buildProjectSection(widget.projects[index]),
      ),
    );
  }

  Widget _buildProjectSection(Project project) {
    return ExpansionTile(
      key: PageStorageKey('proj_${project.id}'),
      initiallyExpanded: true,
      leading: const Icon(Icons.account_tree_outlined, size: 18, color: Colors.blueAccent),
      title: Text(project.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildActionIcon(Icons.file_upload_outlined, "Import", () => _importCollection(project)),
        ],
      ),
      children: project.collections.map((col) => _buildCollectionNode(project, col)).toList(),
    );
  }

  Widget _buildCollectionNode(Project project, Collection collection) {
    return ExpansionTile(
      key: PageStorageKey('col_${collection.id}'),
      leading: const Icon(Icons.folder_open, size: 18, color: Colors.amber),
      title: Text(collection.name, style: const TextStyle(fontSize: 13)),
      children: [
        ...collection.requests.map((req) => _buildRequestItem(project, req)),
      ],
    );
  }

  Widget _buildRequestItem(Project project, RequestModel request) {
    return InkWell(
      onTap: () => widget.onRequestSelected(project, request),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const SizedBox(width: 24), // Indentation
            SizedBox(
              width: 38,
              child: Text(
                request.method,
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: _getMethodColor(request.method)),
              ),
            ),
            Expanded(child: Text(request.name, style: const TextStyle(fontSize: 12))),
          ],
        ),
      ),
    );
  }

  // --- RECURSIVE IMPORT LOGIC (Capturing the Body) ---

  Future<void> _importCollection(Project project) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
    if (result == null) return;

    final content = kIsWeb ? utf8.decode(result.files.single.bytes!) : await File(result.files.single.path!).readAsString();
    final Map<String, dynamic> data = json.decode(content);

    await _savePostmanCollection(project.id, data);
    widget.onRefresh();
  }

  Future<void> _savePostmanCollection(String projectId, Map<String, dynamic> data) async {
    final db = await DatabaseService.instance.database;
    final colId = uuid.v4();

    await db.transaction((txn) async {
      await txn.insert('collections', {
        'id': colId,
        'project_id': projectId,
        'name': data['info']?['name'] ?? "Imported Collection",
      });

      // Pass the folder name down to mimic hierarchy in the request name if needed
      await _processItemsRecursive(txn, colId, data['item'] ?? []);
    });
  }

  Future<void> _processItemsRecursive(dynamic txn, String colId, List<dynamic> items, [String prefix = ""]) async {
    for (var item in items) {
      if (item['item'] != null) {
        // This is a folder, recurse into it
        await _processItemsRecursive(txn, colId, item['item'], "${item['name']} / ");
      } else if (item['request'] != null) {
        final req = item['request'];
        
        // --- BODY EXTRACTION ---
        String bodyText = "";
        if (req['body'] != null && req['body']['mode'] == 'raw') {
          bodyText = req['body']['raw'] ?? "";
        }

        await txn.insert('requests', {
          'id': uuid.v4(),
          'collection_id': colId,
          'name': "$prefix${item['name']}", // Includes folder names for clarity
          'method': req['method'] ?? "GET",
          'url': req['url'] is Map ? (req['url']['raw'] ?? "") : (req['url'] ?? ""),
          'headers': json.encode(req['header'] ?? []),
          'body': bodyText, // Make sure your SQL table has a 'body' column!
          'query_params': '[]',
        });
      }
    }
  }

  // --- HELPERS ---

  Widget _buildActionIcon(IconData icon, String tooltip, VoidCallback onTap) {
    return IconButton(icon: Icon(icon, size: 16), tooltip: tooltip, onPressed: onTap, constraints: const BoxConstraints());
  }

  Color _getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case "GET": return Colors.green;
      case "POST": return Colors.blue;
      case "DELETE": return Colors.red;
      default: return Colors.orange;
    }
  }
}