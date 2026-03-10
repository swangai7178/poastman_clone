import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../core/services/hive_service.dart';
import '../../models/project.dart';
import 'project_detail_page.dart';

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {

  final hiveService = HiveService();
  final uuid = const Uuid();

  List<Project> projects = [];

  @override
  void initState() {
    super.initState();
    loadProjects();
  }

  void loadProjects() {
    setState(() async {
      projects = await hiveService.getProjects();
    });
  }

  void createProject() async {

    TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context){

        return AlertDialog(
          title: const Text("New Project"),

          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: "Project Name",
            ),
          ),

          actions: [

            TextButton(
              onPressed: (){
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),

            ElevatedButton(
              onPressed: () async {

                final project = Project(
                  id: uuid.v4(),
                  name: controller.text,
                  collections: [],
                );

                await hiveService.addProject(project);

                Navigator.pop(context);

                loadProjects();
              },
              child: const Text("Create"),
            ),
          ],
        );
      },
    );
  }

  void deleteProject(String id) async {

    await hiveService.deleteProject(id);

    loadProjects();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Projects"),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: createProject,
        child: const Icon(Icons.add),
      ),

      body: projects.isEmpty
          ? const Center(
              child: Text("No Projects Yet"),
            )
          : ListView.builder(
              itemCount: projects.length,
              itemBuilder: (context, index){

                final project = projects[index];

                return ListTile(
                  title: Text(project.name),

                  onTap: (){
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProjectDetailPage(
                          project: project,
                        ),
                      ),
                    );
                  },

                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: (){
                      deleteProject(project.id);
                    },
                  ),
                );
              },
            ),
    );
  }
}