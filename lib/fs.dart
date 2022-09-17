import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';

class FileSystemWrapper {
  Future<Directory> get notesPath async {
    final Directory directory = await getApplicationDocumentsDirectory();
    return Directory('${directory.path}/notes/');
  }

  makeDir() async {
    final dir = await notesPath;
    if (await dir.exists()) {
      return dir.path;
    } else {
      final Directory dirNew = await dir.create(recursive: true);
      return dirNew.path;
    }
  }

  readDir() async {
    final dir = await notesPath;
    return dir.listSync(recursive: true, followLinks: false).toList();
  }

  trimFiles(List<FileSystemEntity> files) async {
    final dirPrefix = (await notesPath).path.toString();
    return files
        .map((file) => file.path.toString().substring(dirPrefix.length))
        .toList();
  }

  readFile(String file) async {
    final dirPrefix = (await notesPath).path;
    final fileContent = await File("$dirPrefix$file").readAsString();
    return jsonDecode(fileContent);
  }

  writeFile(content, String fileName) async {
    final notesDir = await notesPath;
    final file = File('${notesDir.path}$fileName');
    await file.writeAsString(content);
  }
}
