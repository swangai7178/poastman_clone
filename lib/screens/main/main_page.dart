import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../core/services/hive_service.dart';
import '../../models/project.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final hiveService = HiveService();
  final uuid = const Uuid();

  List<Project> projects = [];
  Project? selectedProject; // Track which project is active in the workspace

  @override
  void initState() {
    super.initState();
    loadProjects();
  }

  // FIXED: Await the data BEFORE calling setState
  void loadProjects() async {
    final loadedProjects = await hiveService.getProjects();
    setState(() {
      projects = loadedProjects;
    });
  }

  void createProject() async {
    TextEditingController controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("New Project"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: "Project Name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;

              final project = Project(
                id: uuid.v4(),
                name: controller.text.trim(),
                collections: [],
              );

              await hiveService.addProject(project);
              
              setState(() {
                projects.add(project);
              });

              Navigator.pop(context);
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
      body: Row(
        children: [
          // --- LEFT SIDEBAR ---
          Container(
            width: 300,
            color: Theme.of(context).cardColor,
            child: Column(
              children: [
                _buildSidebarHeader(),
                const Divider(height: 1),
                Expanded(child: _buildProjectList()),
              ],
            ),
          ),

          // --- VERTICAL DIVIDER ---
          const VerticalDivider(width: 1, thickness: 1),

          // --- MAIN WORKSPACE ---
          Expanded(
            child: selectedProject == null
                ? _buildEmptyState()
                : _buildProjectWorkspace(selectedProject!),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "WIRE TOUCH",
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          IconButton(
            onPressed: createProject,
            icon: const Icon(Icons.add_box_outlined, size: 20),
            tooltip: "New Project",
          ),
        ],
      ),
    );
  }

  Widget _buildProjectList() {
    if (projects.isEmpty) {
      return const Center(child: Text("No projects found"));
    }

    return ListView.builder(
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        return ExpansionTile(
          key: PageStorageKey(project.id),
          leading: const Icon(Icons.folder, size: 20, color: Colors.amber),
          title: Text(project.name, style: const TextStyle(fontSize: 14)),
          trailing: IconButton(
            icon: const Icon(Icons.more_vert, size: 18),
            onPressed: () {
              // Add project options menu (delete/rename) here
            },
          ),
          children: [
            // Nested Collections/Requests
            ...project.collections.map((col) => ListTile(
                  contentPadding: const EdgeInsets.only(left: 48),
                  title: Text(col.name, style: const TextStyle(fontSize: 13)),
                  onTap: () {
                    setState(() => selectedProject = project);
                  },
                )),
            ListTile(
              contentPadding: const EdgeInsets.only(left: 48),
              leading: const Icon(Icons.add, size: 16),
              title: const Text("Add Request", style: TextStyle(fontSize: 12)),
              onTap: () {
                // Logic to add a new request to this project
              },
            )
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lan_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text("Select a project or request to view details"),
        ],
      ),
    );
  }

  Widget _buildProjectWorkspace(Project project) {
    return Column(
      children: [
        AppBar(
          title: Text(project.name),
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        ),
        const Expanded(
          child: Center(
            child: Text("Request Editor Goes Here (Method, URL, Headers, etc.)"),
          ),
        ),
      ],
    );
  }
}