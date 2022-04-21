import 'dart:io';

class DiscussionItem {
  String id;
  String name;
  String deadline;
  String description;
  bool deleted;
  List<dynamic> files;
  List<dynamic> departments;
  List<dynamic> users;
  String author;
  List<dynamic> tags;
  String createdAt;
  bool acked;
  List<File> savedFiles;
  DiscussionItem(
    this.id,
    this.name,
    this.deadline,
    this.description,
    this.deleted,
    this.files,
    this.departments,
    this.users,
    this.author,
    this.tags,
    this.createdAt,
    this.acked, {
    this.savedFiles,
  });
}
