class UserItem {
  String id;
  String name;
  String username;
  String email;
  List<dynamic> permissions;
  String organization;
  String accountType;
  List<dynamic> hierarchy;
  List<dynamic> departments;
  String seenAt;
  bool active;
  UserItem(
    this.id,
    this.name,
    this.username,
    this.email,
    this.permissions,
    this.organization,
    this.accountType,
    this.departments,
    this.seenAt,
    this.active, [
    this.hierarchy,
  ]);
}
