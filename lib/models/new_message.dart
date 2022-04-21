class CreateMessageItem {
  String text;
  List<dynamic> users;
  String deadline;
  List<dynamic> departments;
  bool visibleComments;

  CreateMessageItem(
    this.text,
    this.users,
    this.deadline,
    this.departments,
    this.visibleComments,
  );
}
