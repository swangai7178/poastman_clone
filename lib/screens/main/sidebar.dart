import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:wire_touch/core/services/transferservice.dart';
import '../../models/project.dart';
import '../../models/collection.dart';
import '../../models/request_model.dart';// The Export logic we built

class ProjectSidebar extends StatefulWidget {
  final List<Project> projects;
  final Function(RequestModel) onRequestSelected;
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

  // 1. PROJECT LEVEL
  Widget _buildProjectTile(Project project) {
    return ExpansionTile(
      key: PageStorageKey(project.id),
      leading: const Icon(Icons.workspaces_outline, size: 20, color: Colors.blueAccent),
      title: Text(project.name, style: const TextStyle(fontWeight: FontWeight.bold)),
      trailing: _buildProjectMenu(project),
      children: [
        ...project.collections.map((col) => _buildCollectionTile(project, col)),
        _buildAddButton("Add Collection", () => _addNewCollection(project)),
      ],
    );
  }

  // 2. COLLECTION LEVEL
  Widget _buildCollectionTile(Project project, Collection collection) {
    return ExpansionTile(
      key: PageStorageKey(collection.id),
      tilePadding: const EdgeInsets.only(left: 32, right: 16),
      leading: const Icon(Icons.folder_open, size: 18, color: Colors.amber),
      title: Text(collection.name, style: const TextStyle(fontSize: 14)),
      children: [
        ...collection.requests.map((req) => _buildRequestTile(req)),
        _buildAddButton("Add Request", () => _addNewRequest(collection), indent: 48),
      ],
    );
  }

  // 3. REQUEST LEVEL (The Leaf Node)
  Widget _buildRequestTile(RequestModel request) {
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
      onTap: () => widget.onRequestSelected(request),
    );
  }

  // --- HELPER UI ELEMENTS ---

  Widget _buildProjectMenu(Project project) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 18),
      onSelected: (value) async {
        if (value == 'export') {
          await TransferService.exportProject(project);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Project Exported Successfully")),
            );
          }
        } else if (value == 'delete') {
          // Add your hive delete logic here
          widget.onRefresh();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'export', child: Text("Export JSON")),
        const PopupMenuItem(value: 'delete', child: Text("Delete Project", style: TextStyle(color: Colors.red))),
      ],
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

  // --- LOGIC: ADDING ITEMS ---

  void _addNewCollection(Project project) {
    setState(() {
      project.collections.add(Collection(
        id: uuid.v4(),
        name: "New Collection",
        requests: [],
      ));
    });
    project.save(); // Persist to Hive
  }

  void _addNewRequest(Collection collection) {
    setState(() {
      collection.requests.add(RequestModel(
        id: uuid.v4(),
        name: "New Request",
        method: "GET",
        url: "",
      ));
    });
    collection.save(); // Persist to Hive
  }

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