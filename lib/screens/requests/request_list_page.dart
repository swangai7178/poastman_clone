import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:wire_touch/core/services/api_service.dart';

import '../../models/request_model.dart';
import '../requests/request_builder_page.dart';

class RequestListPage extends StatefulWidget {
  final String projectId;
  final String collectionId;
  final String collectionName;
  final List<RequestModel> requests;

  const RequestListPage({
    super.key,
    required this.projectId,
    required this.collectionId,
    required this.collectionName,
    required this.requests,
  });

  @override
  State<RequestListPage> createState() => _RequestListPageState();
}

class _RequestListPageState extends State<RequestListPage> {

  final hiveService = HiveService();
  final uuid = const Uuid();

  late List<RequestModel> requests;

  @override
  void initState() {
    super.initState();
    requests = widget.requests;
  }

  void createRequest() async {
    TextEditingController controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("New Request"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "Request Name",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if(controller.text.trim().isEmpty) return;

              final request = RequestModel(
                id: uuid.v4(),
                name: controller.text.trim(),
                method: "GET",
                url: "",
                headersList: [],
                body: "",
                queryParamsList: [],
              );

              await hiveService.addRequest(
                widget.projectId,
                widget.collectionId,
                request,
              );

              setState(() {
                requests.add(request);
              });

              Navigator.pop(context);
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  void deleteRequest(String id) async {
    await hiveService.deleteRequest(widget.projectId, widget.collectionId, id);

    setState(() {
      requests.removeWhere((r) => r.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text(widget.collectionName)),
      floatingActionButton: FloatingActionButton(
        onPressed: createRequest,
        child: const Icon(Icons.add),
      ),
      body: requests.isEmpty
          ? const Center(child: Text("No Requests Yet"))
          : ListView.builder(
              itemCount: requests.length,
              itemBuilder: (_, index){
                final req = requests[index];
                return Dismissible(
                  key: ValueKey(req.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => deleteRequest(req.id),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: ListTile(
                    title: Text(req.name),
                    subtitle: Text("${req.method} ${req.url}"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RequestBuilderPage(
                            projectId: widget.projectId,
                            collectionId: widget.collectionId,
                            request: req,
                          ),
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