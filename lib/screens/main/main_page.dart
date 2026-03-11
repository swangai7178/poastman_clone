import 'package:flutter/material.dart';
import 'package:wire_touch/screens/main/request_widget.dart';
import 'package:wire_touch/screens/main/sidebar.dart';
import '../../models/project.dart';
import '../../models/request_model.dart';
import '../../core/services/hive_service.dart';// The editor widget we discussed

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final HiveService _hiveService = HiveService();
  List<Project> _projects = [];
  RequestModel? _activeRequest;
  bool _isLoading = true;

  // Inside _MainPageState

Project? _activeProject; // Add this to track the parent

void _handleRequestSelected(Project project, RequestModel request) {
  setState(() {
    _activeProject = project;
    _activeRequest = request;
  });
}

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await _hiveService.getProjects();
    setState(() {
      _projects = data;
      _isLoading = false;
    });
  }
  

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The AppBar is kept minimal like Postman
      appBar: AppBar(
        title: const Text("WIRE TOUCH", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // --- SIDEBAR AREA ---
               Container(
  width: 300,
  decoration: BoxDecoration(
    color: Theme.of(context).cardColor,
    // Using the built-in theme divider color
    border: Border(
      right: BorderSide(color: Theme.of(context).dividerColor),
    ),
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

                // --- MAIN WORKSPACE AREA ---
                Expanded(
  child: _activeRequest == null || _activeProject == null
      ? _buildEmptyState()
      : RequestEditor(
          key: ValueKey(_activeRequest!.id),
          request: _activeRequest!,
          onSave: () {
            // This is the fix: Save the root project object
            // which is the one actually connected to the Hive box.
            _activeProject!.save(); 
            debugPrint("Data persisted to Hive for: ${_activeProject!.name}");
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
          const Text("Collections", style: TextStyle(fontWeight: FontWeight.w600)),
          const Spacer(),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.create_new_folder_outlined, size: 20),
            onPressed: () {
              // Logic to create a new top-level Project
            },
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.file_download_outlined, size: 20),
            onPressed: () async {
              // Import Logic here
              _loadData(); 
            },
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
          Icon(Icons.rocket_launch_outlined, size: 80, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 20),
          const Text(
            "Select a request from the sidebar\nor create a new one to begin testing.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// Extension to handle theme-based divider colors easily
extension ContextExt on BuildContext {
  Color dividerColor(BuildContext context) => 
      Theme.of(context).brightness == Brightness.light 
          ? Colors.grey.shade300 
          : Colors.grey.shade800;
}