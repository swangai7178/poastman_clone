import 'package:hive/hive.dart';
import '../../models/project.dart';
import '../../models/collection.dart';
import '../../models/request_model.dart';

class HiveService {

  /// Projects Box
  Box<Project> get projectsBox => Hive.box<Project>('projects');

  /// History Box
  Box<RequestModel> get historyBox => Hive.box<RequestModel>('history');

  /// 1️⃣ PROJECTS

  Future<List<Project>> getProjects() async {
    return projectsBox.values.toList();
  }

  Future<void> addProject(Project project) async {
    await projectsBox.put(project.id, project);
  }

  Future<void> deleteProject(String projectId) async {
    await projectsBox.delete(projectId);
  }

  /// 2️⃣ COLLECTIONS

  Future<void> addCollection(String projectId, Collection collection) async {
    final project = projectsBox.get(projectId);
    if (project != null) {
      project.collections.add(collection);
      await project.save();
    }
  }

  Future<void> deleteCollection(String projectId, String collectionId) async {
    final project = projectsBox.get(projectId);
    if (project != null) {
      project.collections.removeWhere((c) => c.id == collectionId);
      await project.save();
    }
  }

  /// 3️⃣ REQUESTS

  Future<void> addRequest(String projectId, String collectionId, RequestModel request) async {
    final project = projectsBox.get(projectId);
    if (project != null) {
      final collection = project.collections.firstWhere((c) => c.id == collectionId);
      collection.requests.add(request);
      await project.save();
    }
  }

  Future<void> deleteRequest(String projectId, String collectionId, String requestId) async {
    final project = projectsBox.get(projectId);
    if (project != null) {
      final collection = project.collections.firstWhere((c) => c.id == collectionId);
      collection.requests.removeWhere((r) => r.id == requestId);
      await project.save();
    }
  }

  /// 4️⃣ HISTORY

  Future<void> addToHistory(RequestModel request) async {
    await historyBox.add(request);
  }

  Future<List<RequestModel>> getHistory() async {
    return historyBox.values.toList();
  }
}