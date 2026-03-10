import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../core/services/hive_service.dart';
import '../../models/project.dart';
import '../../models/collection.dart';
import '../collections/collections_page.dart';

class ProjectDetailPage extends StatefulWidget {

  final Project project;

  const ProjectDetailPage({super.key, required this.project});

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {

  final hiveService = HiveService();
  final uuid = const Uuid();

  late Project project;

  @override
  void initState() {
    super.initState();
    project = widget.project;
  }

  void createCollection() {

    TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context){

        return AlertDialog(
          title: const Text("New Collection"),

          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: "Collection Name",
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

                final collection = Collection(
                  id: uuid.v4(),
                  name: controller.text,
                  requests: [],
                );

                await hiveService.addCollection(
                  project.id,
                  collection,
                );

                setState(() {
                  project.collections.add(collection);
                });

                Navigator.pop(context);
              },
              child: const Text("Create"),
            ),
          ],
        );
      },
    );
  }

  void deleteCollection(String id) async {

    await hiveService.deleteCollection(project.id, id);

    setState(() {
      project.collections.removeWhere((c) => c.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: Text(project.name),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: createCollection,
        child: const Icon(Icons.add),
      ),

      body: project.collections.isEmpty
          ? const Center(
              child: Text("No Collections Yet"),
            )
          : ListView.builder(
              itemCount: project.collections.length,
              itemBuilder: (context, index){

                final collection = project.collections[index];

                return ListTile(

                  title: Text(collection.name),

                  onTap: (){
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CollectionsPage(
                          projectId: project.id,
                          collection: collection,
                        ),
                      ),
                    );
                  },

                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: (){
                      deleteCollection(collection.id);
                    },
                  ),
                );
              },
            ),
    );
  }
}