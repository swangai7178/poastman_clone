import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../core/services/hive_service.dart';
import '../../models/collection.dart';
import '../../models/request_model.dart';
import '../requests/request_builder_page.dart';

class CollectionsPage extends StatefulWidget {

  final String projectId;
  final Collection collection;

  const CollectionsPage({
    super.key,
    required this.projectId,
    required this.collection,
  });

  @override
  State<CollectionsPage> createState() => _CollectionsPageState();
}

class _CollectionsPageState extends State<CollectionsPage> {

  final hiveService = HiveService();
  final uuid = const Uuid();

  late Collection collection;

  @override
  void initState() {
    super.initState();
    collection = widget.collection;
  }

  void createRequest() {

    TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context){

        return AlertDialog(
          title: const Text("New Request"),

          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: "Request Name",
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

                final request = RequestModel(
                  id: uuid.v4(),
                  name: controller.text,
                  method: "GET",
                  url: "",
                  headersList: [],
                  body: "",
                );

                await hiveService.addRequest(
                  widget.projectId,
                  collection.id,
                  request,
                );

                setState(() {
                  collection.requests.add(request);
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

  void deleteRequest(String id) async {

    await hiveService.deleteRequest(
      widget.projectId,
      collection.id,
      id,
    );

    setState(() {
      collection.requests.removeWhere((r) => r.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: Text(collection.name),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: createRequest,
        child: const Icon(Icons.add),
      ),

      body: collection.requests.isEmpty
          ? const Center(
              child: Text("No Requests Yet"),
            )
          : ListView.builder(
              itemCount: collection.requests.length,
              itemBuilder: (context, index){

                final request = collection.requests[index];

                return ListTile(

                  title: Text(request.name),

                  subtitle: Text("${request.method} ${request.url}"),

                  onTap: (){
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RequestBuilderPage(
                          projectId: widget.projectId,
                          collectionId: collection.id,
                          request: request,
                        ),
                      ),
                    );
                  },

                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: (){
                      deleteRequest(request.id);
                    },
                  ),
                );
              },
            ),
    );
  }
}