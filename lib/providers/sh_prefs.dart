import 'package:shared_preferences/shared_preferences.dart';

class ShPrefs {
  ShPrefs._privateConstructor();

  static final ShPrefs instance = ShPrefs._privateConstructor();

  setStringValue(String key, String value) async {
    SharedPreferences myPrefs = await SharedPreferences.getInstance();
    myPrefs.setString(key, value);
  }

  Future<String> getStringValue(String key) async {
    SharedPreferences myPrefs = await SharedPreferences.getInstance();
    //print("before error" + key);
    // print(myPrefs.getString(key));
    return (myPrefs.getString(key).toString() == "null")
        ? ""
        : myPrefs.getString(key).toString();
  }

  Future<bool> containsKey(String key) async {
    SharedPreferences myPrefs = await SharedPreferences.getInstance();
    return myPrefs.containsKey(key);
  }

  removeValue(String key) async {
    SharedPreferences myPrefs = await SharedPreferences.getInstance();
    return myPrefs.remove(key);
  }

  removeAll() async {
    SharedPreferences myPrefs = await SharedPreferences.getInstance();
    return myPrefs.clear();
  }
}
