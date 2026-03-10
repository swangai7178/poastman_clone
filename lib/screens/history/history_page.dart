import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../models/request_model.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {

  late Box historyBox;

  @override
  void initState() {
    super.initState();
    historyBox = Hive.box('history');
  }

  @override
  Widget build(BuildContext context) {
    final history = historyBox.values.toList();

    return Scaffold(
      appBar: AppBar(title: const Text("History")),
      body: history.isEmpty
          ? const Center(child: Text("No history yet"))
          : ListView.builder(
              itemCount: history.length,
              itemBuilder: (_, i) {
                final RequestModel req = history[i];
                return ListTile(
                  title: Text(req.name),
                  subtitle: Text("${req.method} ${req.url}"),
                  onTap: () {
                    // TODO: Open request in builder
                  },
                );
              },
            ),
    );
  }
}