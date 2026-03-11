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
        border: Border(right: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: ListView.builder(
        itemCount: widget.projects.length,
        itemBuilder: (context, index) => _buildProjectSection(widget.projects[index]),
      ),
    );
  }

  // --- PROJECT SECTION ---
  Widget _buildProjectSection(Project project) {
    return ExpansionTile(
      key: PageStorageKey('proj_${project.id}'),
      initiallyExpanded: true,
      leading: const Icon(Icons.account_tree_outlined, size: 18, color: Colors.blueAccent),
      title: Text(
        project.name.toUpperCase(),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
      ),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, size: 18),
        onSelected: (val) => _handleProjectAction(val, project),
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'import', child: Text("Import Collection")),
          const PopupMenuItem(value: 'delete', child: Text("Delete Project", style: TextStyle(color: Colors.red))),
        ],
      ),
      children: project.collections.map((col) => _buildCollectionNode(project, col)).toList(),
    );
  }

  // --- COLLECTION NODE ---
  Widget _buildCollectionNode(Project project, Collection collection) {
    return ExpansionTile(
      key: PageStorageKey('col_${collection.id}'),
      tilePadding: const EdgeInsets.only(left: 12, right: 8),
      leading: const Icon(Icons.folder_outlined, size: 18, color: Colors.amber),
      title: Text(collection.name, style: const TextStyle(fontSize: 13)),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, size: 16, color: Colors.grey),
        onPressed: () => _deleteCollection(collection.id),
      ),
      children: [
        ...collection.requests.map((req) => _buildRequestItem(project, req)),
      ],
    );
  }

  // --- REQUEST ITEM ---
  Widget _buildRequestItem(Project project, RequestModel request) {
    return InkWell(
      onTap: () => widget.onRequestSelected(project, request),
      child: Padding(
        padding: const EdgeInsets.only(left: 32, top: 6, bottom: 6, right: 12),
        child: Row(
          children: [
            SizedBox(
              width: 35,
              child: Text(
                request.method,
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: _getMethodColor(request.method)),
              ),
            ),
            Expanded(
              child: Text(
                request.name,
                style: const TextStyle(fontSize: 12, overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- LOGIC: DELETION & IMPORT ---

  void _handleProjectAction(String action, Project project) {
    if (action == 'import') {
      _importCollection(project);
    } else if (action == 'delete') {
      _deleteProject(project.id);
    }
  }

  Future<void> _deleteProject(String id) async {
    final db = await DatabaseService.instance.database;
    await db.delete('projects', where: 'id = ?', whereArgs: [id]);
    widget.onRefresh();
  }

  Future<void> _deleteCollection(String id) async {
    final db = await DatabaseService.instance.database;
    await db.delete('collections', where: 'id = ?', whereArgs: [id]);
    widget.onRefresh();
  }

  Future<void> _importCollection(Project project) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null) return;

      final content = kIsWeb 
          ? utf8.decode(result.files.single.bytes!) 
          : await File(result.files.single.path!).readAsString();

      final Map<String, dynamic> data = json.decode(content);
      await _savePostmanCollection(project.id, data);
      widget.onRefresh();
    } catch (e) {
      debugPrint("Import Error: $e");
    }
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

      await _processItemsRecursive(txn, colId, data['item'] ?? []);
    });
  }

  Future<void> _processItemsRecursive(dynamic txn, String colId, List<dynamic> items, [String folderName = ""]) async {
    for (var item in items) {
      if (item['item'] != null) {
        // Recurse into folders (e.g., Auth, Manifest)
        // We pass the folder name so requests show as "Auth / Login"
        String currentPath = folderName.isEmpty ? item['name'] : "$folderName / ${item['name']}";
        await _processItemsRecursive(txn, colId, item['item'], currentPath);
      } else if (item['request'] != null) {
        final req = item['request'];
        
        // Extract Body
        String bodyText = "";
        if (req['body'] != null && req['body']['mode'] == 'raw') {
          bodyText = req['body']['raw'] ?? "";
        }

        await txn.insert('requests', {
          'id': uuid.v4(),
          'collection_id': colId,
          'name': folderName.isEmpty ? item['name'] : "$folderName / ${item['name']}",
          'method': (req['method'] ?? "GET").toString().toUpperCase(),
          'url': req['url'] is Map ? (req['url']['raw'] ?? "") : (req['url'] ?? ""),
          'headers': json.encode(req['header'] ?? []),
          'body': bodyText,
          'query_params': '[]',
        });
      }
    }
  }

  // --- HELPERS ---

  Color _getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case "GET": return Colors.green;
      case "POST": return Colors.blue;
      case "PUT": return Colors.orange;
      case "DELETE": return Colors.red;
      default: return Colors.grey;
    }
  }
}