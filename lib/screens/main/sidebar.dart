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
        itemBuilder: (context, index) => _buildProjectNode(widget.projects[index]),
      ),
    );
  }

  // --- UI TREE BUILDING ---

  Widget _buildProjectNode(Project project) {
    return ExpansionTile(
      key: PageStorageKey('proj_${project.id}'),
      initiallyExpanded: true,
      leading: const Icon(Icons.inventory_2_outlined, size: 18, color: Colors.blueAccent),
      title: Text(
        project.name.toUpperCase(),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildActionIcon(Icons.create_new_folder_outlined, "New Root Folder", () => _showFolderDialog(project.id, null)),
          _buildActionIcon(Icons.file_upload_outlined, "Import Postman", () => _importPostman(project)),
          _buildActionIcon(Icons.delete_outline, "Delete Project", () => _deleteProject(project.id)),
        ],
      ),
      children: project.collections
          .where((c) => c.parentId == null)
          .map((col) => _buildRecursiveFolder(project, col))
          .toList(),
    );
  }

  Widget _buildRecursiveFolder(Project project, Collection folder) {
    return ExpansionTile(
      key: PageStorageKey('folder_${folder.id}'),
      tilePadding: const EdgeInsets.only(left: 16, right: 8),
      leading: const Icon(Icons.folder_outlined, size: 18, color: Colors.amber),
      title: Text(folder.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildActionIcon(Icons.add_box_outlined, "New API", () => _showRequestDialog(folder.id)),
          _buildActionIcon(Icons.create_new_folder_outlined, "New Subfolder", () => _showFolderDialog(project.id, folder.id)),
          _buildActionIcon(Icons.delete_outline, "Delete Folder", () => _deleteCollection(folder.id)),
        ],
      ),
      children: [
        // 1. Render Subfolders (Recursive Call)
        ...folder.subFolders.map((sub) => _buildRecursiveFolder(project, sub)),
        
        // 2. Render Requests belonging to this folder level
        ...folder.requests.map((req) => _buildRequestLeaf(project, req)),
      ],
    );
  }

  Widget _buildRequestLeaf(Project project, RequestModel request) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 48, right: 12),
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: SizedBox(
        width: 35,
        child: Text(
          request.method,
          style: TextStyle(
            fontSize: 9, 
            fontWeight: FontWeight.bold, 
            color: _getMethodColor(request.method)
          ),
        ),
      ),
      title: Text(
        request.name, 
        style: const TextStyle(fontSize: 12),
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => widget.onRequestSelected(project, request),
    );
  }

  // --- MANUAL CREATION DIALOGS ---

  Future<void> _showFolderDialog(String projectId, String? parentId) async {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(parentId == null ? "New Root Folder" : "New Subfolder"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: "Enter folder name"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await _createFolder(projectId, parentId, controller.text);
                Navigator.pop(context);
                widget.onRefresh();
              }
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  Future<void> _showRequestDialog(String collectionId) async {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("New API Request"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: "e.g., Get All Users"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await _createManualRequest(collectionId, controller.text);
                Navigator.pop(context);
                widget.onRefresh();
              }
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  // --- DATABASE OPERATIONS ---

  Future<void> _createFolder(String projectId, String? parentId, String name) async {
    final db = await DatabaseService.instance.database;
    await db.insert('collections', {
      'id': uuid.v4(),
      'project_id': projectId,
      'parent_id': parentId,
      'name': name,
    });
  }

  Future<void> _createManualRequest(String collectionId, String name) async {
    final db = await DatabaseService.instance.database;
    await db.insert('requests', {
      'id': uuid.v4(),
      'collection_id': collectionId,
      'name': name,
      'method': 'GET',
      'url': '',
      'body': '',
      'headers': '[]',
      'query_params': '[]',
    });
  }

  Future<void> _importPostman(Project project) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['json']
      );
      if (result == null) return;

      final content = kIsWeb 
          ? utf8.decode(result.files.single.bytes!) 
          : await File(result.files.single.path!).readAsString();

      final Map<String, dynamic> data = json.decode(content);
      final db = await DatabaseService.instance.database;

      await db.transaction((txn) async {
        final rootId = uuid.v4();
        await txn.insert('collections', {
          'id': rootId,
          'project_id': project.id,
          'name': data['info']?['name'] ?? "Imported Collection",
          'parent_id': null,
        });
        await _saveItemsRecursive(txn, project.id, rootId, data['item'] ?? []);
      });
      widget.onRefresh();
    } catch (e) {
      debugPrint("Import Error: $e");
    }
  }

  Future<void> _saveItemsRecursive(dynamic txn, String projId, String parentId, List<dynamic> items) async {
    for (var item in items) {
      if (item['item'] != null) {
        final folderId = uuid.v4();
        await txn.insert('collections', {
          'id': folderId,
          'project_id': projId,
          'name': item['name'],
          'parent_id': parentId,
        });
        await _saveItemsRecursive(txn, projId, folderId, item['item']);
      } else if (item['request'] != null) {
        final req = item['request'];
        String urlString = req['url'] is Map ? (req['url']['raw'] ?? "") : (req['url']?.toString() ?? "");
        String bodyString = "";
        if (req['body'] != null && req['body']['mode'] == 'raw') {
          bodyString = req['body']['raw'] ?? "";
        }

        await txn.insert('requests', {
          'id': uuid.v4(),
          'collection_id': parentId,
          'name': item['name'],
          'method': (req['method'] ?? "GET").toString().toUpperCase(),
          'url': urlString,
          'body': bodyString,
          'headers': json.encode(req['header'] ?? []),
          'query_params': '[]',
        });
      }
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

  // --- HELPERS ---

  Widget _buildActionIcon(IconData icon, String tooltip, VoidCallback onTap) {
    return IconButton(
      icon: Icon(icon, size: 16, color: Colors.grey),
      tooltip: tooltip,
      constraints: const BoxConstraints(),
      padding: const EdgeInsets.all(8),
      onPressed: onTap,
    );
  }

  Color _getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case "GET": return Colors.green;
      case "POST": return Colors.blue;
      case "PUT": return Colors.orange;
      case "DELETE": return Colors.red;
      case "PATCH": return Colors.purple;
      default: return Colors.grey;
    }
  }
}