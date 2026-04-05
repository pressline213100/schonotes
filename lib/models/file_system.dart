import 'note.dart';

abstract class FileSystemNode {
  final String id;
  String title;
  DateTime lastModified;
  DateTime? lastOpened; // Added for Recent
  bool isDeleted; // Added for Trash

  FileSystemNode({
    required this.id,
    required this.title,
    required this.lastModified,
    this.lastOpened,
    this.isDeleted = false,
  });
}

class FolderNode extends FileSystemNode {
  final List<FileSystemNode> children;

  FolderNode({
    required super.id,
    required super.title,
    required super.lastModified,
    List<FileSystemNode>? children,
  }) : children = children ?? [];
}

class NoteNode extends FileSystemNode {
  final Note note;

  NoteNode({
    required super.id,
    required super.title,
    required super.lastModified,
    required this.note,
  });
}
