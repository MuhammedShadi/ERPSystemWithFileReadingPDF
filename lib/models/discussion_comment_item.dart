class DiscussionCommentItem {
  String discussionId;
  String commentId;
  String author;
  List<dynamic> departments;
  String text;
  bool deleted;
  String createdAt;
  DiscussionCommentItem(
    this.discussionId,
    this.commentId,
    this.author,
    this.departments,
    this.text,
    this.deleted,
    this.createdAt,
  );
}
