import 'package:hive/hive.dart';
import '../../models/project.dart';
import '../../models/collection.dart';
import '../../models/request_model.dart';

class HiveService {

  static final HiveService _instance = HiveService._internal();

  factory HiveService() {
    return _instance;
  }

  HiveService._internal();

  final Box<Project> projectBox = Hive.box<Project>('projects');

  // ---------------------------
  // PROJECTS
  // ---------------------------

  List<Project> getProjects() {
    return projectBox.values.toList();
  }

  Future<void> createProject(Project project) async {
    await projectBox.put(project.id, project);
  }

  Future<void> deleteProject(String projectId) async {
    await projectBox.delete(projectId);
  }

  Project? getProject(String projectId) {
    return projectBox.get(projectId);
  }

  // ---------------------------
  // COLLECTIONS
  // ---------------------------

  Future<void> addCollection(
      String projectId, Collection collection) async {

    final project = projectBox.get(projectId);

    if (project != null) {
      project.collections.add(collection);
      await project.save();
    }
  }

  Future<void> deleteCollection(
      String projectId, String collectionId) async {

    final project = projectBox.get(projectId);

    if (project != null) {
      project.collections.removeWhere(
              (collection) => collection.id == collectionId);

      await project.save();
    }
  }

  // ---------------------------
  // REQUESTS
  // ---------------------------

  Future<void> addRequest(
      String projectId,
      String collectionId,
      RequestModel request) async {

    final project = projectBox.get(projectId);

    if (project != null) {

      final collection = project.collections
          .firstWhere((c) => c.id == collectionId);

      collection.requests.add(request);

      await project.save();
    }
  }

  Future<void> deleteRequest(
      String projectId,
      String collectionId,
      String requestId) async {

    final project = projectBox.get(projectId);

    if (project != null) {

      final collection = project.collections
          .firstWhere((c) => c.id == collectionId);

      collection.requests
          .removeWhere((request) => request.id == requestId);

      await project.save();
    }
  }
}