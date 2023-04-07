
class UserData {
  static UserData? _instance;

  late String uid;
  late String email;
  late String password;

  void setInstance({required String uid, required String email, required password}) {
    _instance ??= UserData();
    _instance?.uid = uid;
    _instance?.email = email;
    _instance?.password = password;
  }

  static UserData getInstance() {
    if (_instance == null) {
      _instance = UserData();
      _instance?.uid = "";
      _instance?.email = "";
      _instance?.password = "";
    }
    return _instance!;
  }
}