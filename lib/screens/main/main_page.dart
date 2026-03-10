import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../core/services/hive_service.dart';
import '../../models/project.dart';
import '../projects/project_detail_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final hiveService = HiveService();
  final uuid = const Uuid();

  List<Project> projects = [];

  @override
  void initState() {
    super.initState();
    loadProjects();
  }

  void loadProjects() async {
    final loadedProjects = hiveService.getProjects();
    setState(() async {
      projects = await loadedProjects;
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
          decoration: const InputDecoration(hintText: "Project Name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if(controller.text.trim().isEmpty) return;

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

  void deleteProject(String id) async {
    await hiveService.deleteProject(id);
    setState(() {
      projects.removeWhere((p) => p.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Wire Touch"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: createProject,
        child: const Icon(Icons.add),
      ),
      body: projects.isEmpty
          ? const Center(child: Text("No Projects Yet"))
          : ListView.separated(
              itemCount: projects.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final project = projects[index];

                return Dismissible(
                  key: ValueKey(project.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => deleteProject(project.id),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: ListTile(
                    title: Text(project.name),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProjectDetailPage(project: project),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}