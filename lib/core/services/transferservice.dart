import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:wire_touch/models/project.dart';

class TransferService {
  // EXPORT: Project -> JSON -> File
  static Future<void> exportProject(Project project) async {
    try {
      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Project Export',
        fileName: '${project.name.replaceAll(' ', '_')}_export.json',
      );

      if (outputPath != null) {
        final file = File(outputPath);
        final String jsonString = jsonEncode(project.toJson());
        await file.writeAsString(jsonString);
      }
    } catch (e) {
      print("Export failed: $e");
    }
  }

  // IMPORT: File -> JSON -> Project Object
  static Future<Project?> importProject() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        final Map<String, dynamic> jsonData = jsonDecode(content);
        
        return Project.fromJson(jsonData);
      }
    } catch (e) {
      print("Import failed: $e");
    }
    return null;
  }
}