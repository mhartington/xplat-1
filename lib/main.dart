import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'fs.dart';

void main() {
  runApp(
    const MaterialApp(
      home: HomePage(),
    ),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final fs = FileSystemWrapper();
  List<String> notes = [];
  @override
  void initState() {
    super.initState();
    _initFileSystem();
  }

  _initFileSystem() async {
    await fs.makeDir();
    await getFiles();
  }

  getFiles() async {
    final List<FileSystemEntity> files = await fs.readDir();
    notes = await fs.trimFiles(files);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notes"), actions: [
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const EditPage(),
              ),
            ).then((_) => {getFiles()});
          },
          icon: const Icon(Icons.add),
        ),
      ]),
      body: ListView(
          children: notes
              .map((note) => ListTile(
                  title: Text(note),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditPage(note: note),
                      ),
                    ).then((_) => getFiles());
                  }))
              .toList()),
    );
  }
}

class EditPage extends StatefulWidget {
  const EditPage({super.key, this.note});
  // ignore: prefer_typing_uninitialized_variables
  final note;
  @override
  EditPageState createState() => EditPageState();
}

class EditPageState extends State<EditPage> {
  final fs = FileSystemWrapper();
  final List<dynamic> content = [];
  QuillController? _controller; // = QuillController.basic();

  writeNote(context) async {
    String name;
    if (widget.note == null) {
      name = "${DateTime.now().toString()}.txt";
    } else {
      name = widget.note;
    }
    final content =
        jsonEncode(_controller?.document.toDelta().toJson()).toString();
    await fs.writeFile(content, name);
    Navigator.pop(context, true);
  }

  deleteNote(context) async {
    await fs.deleteFile(widget.note);
    Navigator.pop(context, false);
  }

  @override
  void initState() {
    super.initState();
    loadFile();
  }

  loadFile() async {
    if (widget.note != null) {
      final fileContent = await fs.readFile(widget.note);
      final doc = Document.fromJson(fileContent);
      setState(() {
        _controller = QuillController(
            document: doc, selection: const TextSelection.collapsed(offset: 0));
      });
    } else {
      final doc = Document()..insert(0, '');
      setState(() {
        _controller = QuillController(
            document: doc, selection: const TextSelection.collapsed(offset: 0));
      });
    }
  }

  List<Widget> getActions() {
    if (widget.note != null) {
      return [
        IconButton(
          onPressed: () => writeNote(context),
          icon: const Icon(Icons.save),
        ),
        IconButton(
          onPressed: () => deleteNote(context),
          icon: const Icon(Icons.delete),
        ),
      ];
    } else {
      return [
        IconButton(
          onPressed: () => writeNote(context),
          icon: const Icon(Icons.save),
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const Scaffold(body: Center(child: Text('Loading...')));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor'),
        actions: getActions(),
      ),
      body: Column(children: [
        QuillToolbar.basic(controller: _controller!),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(8.0),
            child: QuillEditor.basic(
              controller: _controller!,
              readOnly: false,
            ),
          ),
        )
      ]),
    );
  }
}
