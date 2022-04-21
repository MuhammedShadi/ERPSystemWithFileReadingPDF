class MessageItem {
  String id;
  String author;
  String text;
  List<dynamic> users;
  List<dynamic> departments;
  String createdAt;
  bool visibleComments;
  MessageItem(
    this.id,
    this.text,
    this.author,
    this.users,
    this.departments,
    this.createdAt,
    this.visibleComments,
  );
}
