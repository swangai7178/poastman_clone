import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/project.dart';
import '../../models/collection.dart';
import '../../models/request_model.dart';
import '../../core/services/database_service.dart'; // Our new SQL service

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

  Widget _buildProjectTile(Project project) {
    return ExpansionTile(
      key: PageStorageKey(project.id),
      leading: const Icon(Icons.workspaces_outline, size: 20, color: Colors.blueAccent),
      title: Text(project.name, style: const TextStyle(fontWeight: FontWeight.bold)),
      children: [
        ...project.collections.map((col) => _buildCollectionTile(project, col)),
        _buildAddButton("Add Collection", () => _addNewCollection(project)),
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
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getMethodColor(request.method)),
      ),
      title: Text(request.name, style: const TextStyle(fontSize: 13)),
      onTap: () => widget.onRequestSelected(project, request),
    );
  }

  // --- SQL LOGIC ---

  Future<void> _addNewCollection(Project project) async {
    final db = await DatabaseService.instance.database;
    final newId = uuid.v4();
    
    await db.insert('collections', {
      'id': newId,
      'project_id': project.id,
      'name': "New Collection",
    });

    widget.onRefresh(); // Refresh the main page data from SQL
  }

  Future<void> _addNewRequest(Project project, Collection collection) async {
    final db = await DatabaseService.instance.database;
    final newId = uuid.v4();

    await db.insert('requests', {
      'id': newId,
      'collection_id': collection.id,
      'name': "New Request",
      'method': "GET",
      'url': "",
      'headers': '[]', // Initializing as empty JSON lists
      'query_params': '[]',
    });

    widget.onRefresh();
  }

  // --- UI HELPERS ---

  Widget _buildAddButton(String label, VoidCallback onTap, {double indent = 32}) {
    return ListTile(
      contentPadding: EdgeInsets.only(left: indent),
      dense: true,
      leading: const Icon(Icons.add, size: 16),
      title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      onTap: onTap,
    );
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