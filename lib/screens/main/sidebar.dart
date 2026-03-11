import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart'; // Required for kIsWeb
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
    return ListView.builder(
      itemCount: widget.projects.length,
      itemBuilder: (context, index) {
        final project = widget.projects[index];
        return _buildProjectTile(project);
      },
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildProjectTile(Project project) {
    return ExpansionTile(
      key: PageStorageKey(project.id),
      leading: const Icon(Icons.workspaces_outline, size: 20, color: Colors.blueAccent),
      title: Text(project.name, style: const TextStyle(fontWeight: FontWeight.bold)),
      children: [
        ...project.collections.map((col) => _buildCollectionTile(project, col)),
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Row(
            children: [
              Expanded(
                child: _buildAddButton("Add Collection", () => _addNewCollection(project)),
              ),
              Tooltip(
                message: "Import Collection (JSON)",
                child: IconButton(
                  icon: const Icon(Icons.file_upload_outlined, size: 18, color: Colors.blueGrey),
                  onPressed: () => _importCollection(project),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCollectionTile(Project project, Collection collection) {
    return ExpansionTile(
      key: PageStorageKey(collection.id),
      title: Text(collection.name, style: const TextStyle(fontSize: 14)),
      children: [
        ...collection.requests.map((req) => _buildRequestTile(project, req)),
        _buildAddButton("Add Request", () => _addNewRequest(project, collection), indent: 48),
      ],
    );
  }

  Widget _buildRequestTile(Project project, RequestModel request) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 56),
      leading: Text(
        request.method,
        style: TextStyle(
          fontSize: 10, 
          fontWeight: FontWeight.bold, 
          color: _getMethodColor(request.method),
        ),
      ),
      title: Text(request.name, style: const TextStyle(fontSize: 13)),
      onTap: () => widget.onRequestSelected(project, request),
    );
  }

  Widget _buildAddButton(String label, VoidCallback onTap, {double indent = 32}) {
    return ListTile(
      contentPadding: EdgeInsets.only(left: indent),
      dense: true,
      leading: const Icon(Icons.add, size: 16),
      title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      onTap: onTap,
    );
  }

  // --- BUSINESS & SQL LOGIC ---

  Future<void> _importCollection(Project project) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null) return;

      String content;
      if (kIsWeb) {
        // On Web, we use the bytes directly
        content = utf8.decode(result.files.single.bytes!);
      } else {
        // On Desktop/Mobile, we use the file path
        final file = File(result.files.single.path!);
        content = await file.readAsString();
      }

      final dynamic decodedData = json.decode(content);
      
      // Support both single objects or lists of collections
      if (decodedData is Map<String, dynamic>) {
        await _saveImportedCollection(project.id, decodedData);
      } else if (decodedData is List) {
        for (var item in decodedData) {
          await _saveImportedCollection(project.id, item as Map<String, dynamic>);
        }
      }

      widget.onRefresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Import successful")),
        );
      }
    } catch (e) {
      debugPrint("Import Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveImportedCollection(String projectId, Map<String, dynamic> data) async {
    final db = await DatabaseService.instance.database;
    final collectionId = uuid.v4();

    // Perform as a transaction to ensure atomic updates
    await db.transaction((txn) async {
      await txn.insert('collections', {
        'id': collectionId,
        'project_id': projectId,
        'name': data['name'] ?? data['info']?['name'] ?? "Imported Collection",
      });

      // Handle items/requests (matches standard Postman-like structures)
      final List requests = data['item'] ?? data['requests'] ?? [];
      for (var item in requests) {
        final requestId = uuid.v4();
        // Extracting request details safely
        final reqData = item['request'] ?? item; 
        
        await txn.insert('requests', {
          'id': requestId,
          'collection_id': collectionId,
          'name': item['name'] ?? "Unnamed Request",
          'method': (reqData['method'] ?? "GET").toString().toUpperCase(),
          'url': reqData['url'] is Map ? (reqData['url']['raw'] ?? "") : (reqData['url'] ?? ""),
          'headers': json.encode(reqData['header'] ?? reqData['headers'] ?? []),
          'query_params': json.encode(reqData['url'] is Map ? (reqData['url']['query'] ?? []) : []),
        });
      }
    });
  }

  Future<void> _addNewCollection(Project project) async {
    final db = await DatabaseService.instance.database;
    await db.insert('collections', {
      'id': uuid.v4(),
      'project_id': project.id,
      'name': "New Collection",
    });
    widget.onRefresh();
  }

  Future<void> _addNewRequest(Project project, Collection collection) async {
    final db = await DatabaseService.instance.database;
    await db.insert('requests', {
      'id': uuid.v4(),
      'collection_id': collection.id,
      'name': "New Request",
      'method': "GET",
      'url': "",
      'headers': '[]',
      'query_params': '[]',
    });
    widget.onRefresh();
  }

  // --- HELPERS ---

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