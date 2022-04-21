class NewUser {
  String name;
  String accountType;
  String username;
  String email;
  String password;
  List<dynamic> departments;
  List<List<dynamic>> hierarchy;
  NewUser(
    this.name,
    this.accountType,
    this.username,
    this.email,
    this.password,
    this.departments, {
    this.hierarchy,
  });
}
