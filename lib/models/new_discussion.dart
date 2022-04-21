class CreateDiscussionItem {
  String name;
  String deadline;
  String description;
  List<dynamic> files;
  List<dynamic> departments;
  List<dynamic> users;
  List<dynamic> tags;

  CreateDiscussionItem(
    this.name,
    this.deadline,
    this.description,
    this.files,
    this.departments,
    this.users,
    this.tags,
  );
}
