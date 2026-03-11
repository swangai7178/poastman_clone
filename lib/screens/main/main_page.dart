import 'package:flutter/material.dart';
import 'package:wire_touch/screens/main/request_widget.dart';
import 'package:wire_touch/screens/main/sidebar.dart';
import '../../models/project.dart';
import '../../models/collection.dart';
import '../../models/request_model.dart';
import '../../core/services/database_service.dart'; // Import SQLite Service
import 'package:uuid/uuid.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  List<Project> _projects = [];
  RequestModel? _activeRequest;
  Project? _activeProject;
  bool _isLoading = true;
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // --- NEW: SQLite DATA LOADING ---
  // We fetch the relational tree: Projects -> Collections -> Requests
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final db = await DatabaseService.instance.database;

    // 1. Fetch all Projects
    final List<Map<String, dynamic>> projectMaps = await db.query('projects');
    List<Project> loadedProjects = [];

    for (var pMap in projectMaps) {
      final project = Project.fromMap(pMap);

      // 2. Fetch Collections for this project
      final List<Map<String, dynamic>> colMaps = await db.query(
        'collections',
        where: 'project_id = ?',
        whereArgs: [project.id],
      );

      for (var cMap in colMaps) {
        final collection = Collection.fromMap(cMap);

        // 3. Fetch Requests for this collection
        final List<Map<String, dynamic>> reqMaps = await db.query(
          'requests',
          where: 'collection_id = ?',
          whereArgs: [collection.id],
        );

        collection.requests = reqMaps.map((r) => RequestModel.fromMap(r)).toList();
        project.collections.add(collection);
      }
      loadedProjects.add(project);
    }

    setState(() {
      _projects = loadedProjects;
      _isLoading = false;
    });
  }

  void _handleRequestSelected(Project project, RequestModel request) {
    setState(() {
      _activeProject = project;
      _activeRequest = request;
    });
  }

  // Logic to create a new top-level Project in SQLite
  Future<void> _createNewProject() async {
    final TextEditingController nameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Create New Project"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: "Enter project name"),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final db = await DatabaseService.instance.database;
                await db.insert('projects', {
                  'id': _uuid.v4(),
                  'name': nameController.text,
                });
                Navigator.pop(context);
                _loadData(); // Refresh the list
              }
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("WIRE TOUCH", style: TextStyle(fontSize: 14, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        actions: [
          IconButton(icon: const Icon(Icons.settings_outlined, size: 20), onPressed: () {}),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // --- SIDEBAR ---
                Container(
                  width: 280,
                  decoration: BoxDecoration(
                    border: Border(right: BorderSide(color: Theme.of(context).dividerColor)),
                  ),
                  child: Column(
                    children: [
                      _buildSidebarActions(),
                      const Divider(height: 1),
                      Expanded(
                        child: ProjectSidebar(
                          projects: _projects,
                          onRequestSelected: _handleRequestSelected,
                          onRefresh: _loadData,
                        ),
                      ),
                    ],
                  ),
                ),

                // --- WORKSPACE ---
                Expanded(
                  child: _activeRequest == null || _activeProject == null
                      ? _buildEmptyState()
                      : RequestEditor(
                          key: ValueKey(_activeRequest!.id),
                          request: _activeRequest!,
                          onSave: () async {
                            // Update the specific request in SQLite
                            final db = await DatabaseService.instance.database;
                            await db.update(
                              'requests',
                              _activeRequest!.toMap(),
                              where: 'id = ?',
                              whereArgs: [_activeRequest!.id],
                            );
                            debugPrint("Request saved to SQLite: ${_activeRequest!.name}");
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildSidebarActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const Text("Collections", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const Spacer(),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.add_box_outlined, size: 18),
            onPressed: _createNewProject,
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.file_download_outlined, size: 18),
            onPressed: () {}, // Import logic
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.api_outlined, size: 64, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text("No Request Selected", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          const Text("Choose a request from the sidebar to start.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}