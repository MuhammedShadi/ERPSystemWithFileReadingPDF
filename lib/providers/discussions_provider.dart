import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfviewer/models/discussion_comment_item.dart';
import 'package:pdfviewer/models/discussion_item.dart';
import 'package:pdfviewer/models/new_discussion.dart';
import 'package:pdfviewer/providers/login_provider.dart';
import 'package:pdfviewer/providers/sh_prefs.dart';

var apiUrl = "https://share.i.wdex.email/api/v1";

LoginProvider userAuth = new LoginProvider();
Dio dio;

class DiscussionsProvider {
  Future<List<DiscussionItem>> getDiscussionsP({int pageNum = 1}) async {
    String filterParam = "";
    String title = await ShPrefs.instance.getStringValue('titles');
    String discussionNames =
        await ShPrefs.instance.getStringValue('discussionNames');
    String discDepartment =
        await ShPrefs.instance.getStringValue('discDepartment');
    String discUsers = await ShPrefs.instance.getStringValue('accountUsers');
    String discTags = await ShPrefs.instance.getStringValue('discTags');
    String discAckn = await ShPrefs.instance.getStringValue('ackn');
    String discDeletedBool =
        await ShPrefs.instance.getStringValue('deletedBool');
    print(discDeletedBool);
    if (discDeletedBool == null || discDeletedBool.isEmpty) {
      discDeletedBool = "&deleted=false";
    }
    if (discDeletedBool == 'null') {
      discDeletedBool = "";
    }
    if (discDeletedBool == 'true') {
      discDeletedBool = "&deleted=true";
    }
    if (discDeletedBool == 'false') {
      discDeletedBool = "&deleted=false";
    }
    if (discDepartment != null) {
      filterParam += '$discDepartment';
    }
    if (discUsers != null) {
      filterParam += '$discUsers';
    }
    if (title != null && title.isNotEmpty) {
      filterParam += '&title=${Uri.encodeFull(title)}';
    }
    if (discussionNames != null && discussionNames.isNotEmpty) {
      filterParam += '&name=${Uri.encodeFull(discussionNames)}';
    }
    if (discTags != null && discTags.isNotEmpty) {
      filterParam += '&tags=${Uri.encodeFull(discTags)}';
    }
    if (discAckn != null && discAckn.isNotEmpty) {
      filterParam += '&acked=$discAckn';
    }
    if (discDeletedBool != null && discDeletedBool.isNotEmpty) {
      filterParam += '$discDeletedBool';
    }
    print(filterParam);
    try {
      int maxPages = pageNum;
      String maxPageS =
          await ShPrefs.instance.getStringValue('discussionPages');

      if (maxPageS != "") {
        maxPages = int.parse(maxPageS);
      }
      print("maxP " + maxPages.toString());
      print("pageNum " + pageNum.toString());
      print(apiUrl + '/discussions/?page=$pageNum&per_page=5$filterParam');
      if (pageNum <= maxPages) {
        // print('hello here');
        Response response = await dio.get(
          apiUrl + '/discussions/?page=$pageNum&per_page=5$filterParam',
          options: Options(headers: {
            "accept": "application/json",
          }),
        );

        ShPrefs.instance.setStringValue(
            'discussionPages', response.data['pages'].toString());
        print(apiUrl + '/discussions/?page=$pageNum&per_page=5$filterParam');
        // print(response.data);
        List<DiscussionItem> discussionItems = [];
        if (response.statusCode == 200) {
          JsonEncoder encoder = new JsonEncoder.withIndent('  ');
          String prettyPrint = encoder.convert(response.data);
          // print(prettyPrint);
          List dataJson = jsonDecode(prettyPrint)["items"];
          // print(dataJson);
          for (var i in dataJson) {
            // print(i["_id"]);
            DiscussionItem discussionItem = new DiscussionItem(
              i["_id"],
              i["name"],
              i["deadline"],
              i["description"],
              i["deleted"],
              i["files"],
              i["departments"],
              i["users"],
              i["author"],
              i["tags"],
              i["created_at"],
              i["acked"],
            );
            // print(discussionItem.files);
            discussionItems.add(discussionItem);
          }
          return discussionItems;
        }
      }
    } on DioError catch (e) {
      print('error');
      print(e.response.data);
      print(e.requestOptions.data);
    }
    return null;
  }

  Future<List<DiscussionItem>> getDiscussionsPFilteredByTitle(String name,
      {int pageNum = 1}) async {
    try {
      Response response = await dio.get(
        apiUrl +
            '/discussions/?page=$pageNum&per_page=50&tags=${Uri.encodeFull(name)}',
        options: Options(headers: {
          "accept": "application/json",
        }),
      );
      print(apiUrl +
          '/discussions/?page=$pageNum&per_page=20&tags=${Uri.encodeFull(name)}');
      List<DiscussionItem> discussionItems = [];
      if (response.statusCode == 200) {
        JsonEncoder encoder = new JsonEncoder.withIndent('  ');
        String prettyPrint = encoder.convert(response.data);
        // print(prettyPrint);
        List dataJson = jsonDecode(prettyPrint)["items"];
        // print(dataJson);
        for (var i in dataJson) {
          // print(i["_id"]);
          DiscussionItem discussionItem = new DiscussionItem(
            i["_id"],
            i["name"],
            i["deadline"],
            i["description"],
            i["deleted"],
            i["files"],
            i["departments"],
            i["users"],
            i["author"],
            i["tags"],
            i["created_at"],
            i["acked"],
          );
          // print(discussionItem.files);
          discussionItems.add(discussionItem);
        }
        return discussionItems;
      }
    } on DioError catch (e) {
      print('error');
      print(e.response.data);
      print(e.requestOptions.data);
    }
    return null;
  }

  deleteDiscussion(String discussionId) async {
    String token = await ShPrefs.instance.getStringValue("access_token");
    try {
      Response response = await dio.delete(
        apiUrl + '/discussions/$discussionId',
        options: Options(headers: {
          "accept": "application/json",
          "Authorization": "Bearer $token",
        }),
      );
      // print(apiUrl + '/discussions/$discussionId');
      if (response.statusCode == 200 || response.statusCode == 204) {
        Fluttertoast.showToast(
          msg: "تم مسح المناقشة بنجاح",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    } on DioError catch (e) {
      print(apiUrl + '/discussions/$discussionId');
      print(e.response.data);
      print(e.response.statusCode);
    }
  }

  updateDiscussion(
      String discussionId,
      String name,
      String deadline,
      String description,
      List<dynamic> files,
      List<dynamic> departments,
      List<dynamic> users,
      List<dynamic> tags,
      bool deleted) async {
    String token = await ShPrefs.instance.getStringValue("access_token");
    try {
      List preparedFiles = [];
      for (var i in files) {
        if (i["content"] != null) {
          preparedFiles.add(i);
          // print(i);
          // print("added old content");
        } else {
          if (i["path"] != null) {
            Map<String, dynamic> newFileItem =
                prepareSingleAttachment(i["path"]);

            preparedFiles.add(newFileItem);
            // print(i);
            print("added new content from path");
          }
        }
      }
      //  print(preparedFiles);
      Response response = await dio.put(
        apiUrl + '/discussions/$discussionId',
        data: jsonEncode({
          "name": name,
          "deadline": deadline,
          "description": description,
          "files": preparedFiles,
          "departments": departments,
          "users": users,
          "tags": tags,
          "deleted": deleted
        }),
        options: Options(headers: {
          "accept": "application/json",
          "Authorization": "Bearer $token",
        }),
      );
      if (response.statusCode == 200) {
        Fluttertoast.showToast(
          msg: "تم تعديل المناقشة بنجاح",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        print(jsonEncode({
          "name": name,
          "deadline": deadline,
          "description": description,
          "files": preparedFiles,
          "departments": departments,
          "users": users,
          "tags": tags,
          "deleted": deleted
        }));
      }
      return true;
    } on DioError catch (e) {
      print(e.response.data);
      print(e.response.statusCode);
      Fluttertoast.showToast(
        msg: "${e.response.statusMessage}",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      // print(e.response.statusCode);
    }
  }

  addNewDiscussion(CreateDiscussionItem _newDiscussionItem) async {
    String token = await ShPrefs.instance.getStringValue("access_token");
    try {
      List preparedFiles = [];

      for (var i in _newDiscussionItem.files) {
        Map<String, dynamic> newFileItem = prepareSingleAttachment(i["path"]);

        preparedFiles.add(newFileItem);
      }
      Response response = await dio.post(
        apiUrl + '/discussions/',
        data: jsonEncode({
          "name": _newDiscussionItem.name,
          "deadline": _newDiscussionItem.deadline,
          "description": _newDiscussionItem.description,
          "files": preparedFiles,
          "departments": _newDiscussionItem.departments,
          "users": _newDiscussionItem.users,
          "tags": _newDiscussionItem.tags
        }),
        options: Options(headers: {
          "accept": "application/json",
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        Fluttertoast.showToast(
          msg: "تم إضافة المناقشة بنجاح",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        return true;
      }
    } on DioError catch (e) {
      print(e.response.data);
      print(e.response.statusCode);
      if (e.response.statusCode == 400) {
        Fluttertoast.showToast(
          msg: "من فضلك تأكد من اضافة جميع البيانات",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        return false;
      } else {
        Fluttertoast.showToast(
          msg: "${e.response.statusMessage}",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        return false;
      }
    }
  }

  Future<List<DiscussionCommentItem>> getAllDiscussionComment(
      String discussionId) async {
    String token = await ShPrefs.instance.getStringValue("access_token");
    try {
      Response response = await dio.get(
        apiUrl + '/discussions/$discussionId/comments?page=1&per_page=50',
        options: Options(headers: {
          "accept": "application/json",
          "Authorization": "Bearer $token",
        }),
      );
      // print(response.data);
      List<DiscussionCommentItem> _discussionCommentItems = [];
      if (response.statusCode == 200) {
        JsonEncoder encoder = new JsonEncoder.withIndent('  ');
        String prettyPrint = encoder.convert(response.data);
        List dataJson = jsonDecode(prettyPrint)["items"];
        for (var i in dataJson) {
          DiscussionCommentItem _discussionCommentItem =
              new DiscussionCommentItem(
            i["discussion_id"],
            i["comment_id"],
            i["author"],
            i["departments"],
            i["text"],
            i["deleted"],
            i["created_at"],
          );
          _discussionCommentItems.add(_discussionCommentItem);
        }
        return _discussionCommentItems;
      }
    } on DioError catch (e) {
      print(e.response.data);
      Fluttertoast.showToast(
        msg: "${e.response.statusMessage}",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      // print(e.response.statusCode);
    }
    return null;
  }

  Future<List<DiscussionCommentItem>> addDiscussionComment(
      String discussionId, String text) async {
    String token = await ShPrefs.instance.getStringValue("access_token");

    Response response = await dio.post(
      apiUrl + '/discussions/$discussionId/comments',
      data: {
        "text": "$text",
      },
      options: Options(headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      }),
    );
    // print(response.statusCode);
    // List<DiscussionCommentItem> _discussionCommentItems = [];
    if (response.statusCode == 200) {
      //JsonEncoder encoder = new JsonEncoder.withIndent('  ');
      //String prettyPrint = encoder.convert(response.data);
      // print(prettyPrint);
      // List dataJson = jsonDecode(prettyPrint)["items"];
      // print(dataJson);
      Fluttertoast.showToast(
        msg: "تم إضافة تعليق جديد بنجاح",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } else {
      Fluttertoast.showToast(
        msg: "${response.statusMessage}",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
    return null;
  }

  Future<List<DiscussionCommentItem>> deleteDiscussionComment(
      String discussionId, String commentId) async {
    String token = await ShPrefs.instance.getStringValue("access_token");
    try {
      Response response = await dio.delete(
        apiUrl + '/discussions/$discussionId/comments/$commentId',
        options: Options(headers: {
          "accept": "application/json",
          "Authorization": "Bearer $token",
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        Fluttertoast.showToast(
          msg: "تم مسح التعليق بنجاح",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    } on DioError catch (e) {
      Fluttertoast.showToast(
        msg: "${e.response.statusMessage}",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      if (e.response.statusCode == 401) {
        userAuth.refrshToken();
      }
      // print(e.response.data);
      // print(e.response.statusCode);
    }
    return null;
  }

  Future<List<DiscussionCommentItem>> postDiscussionAcknowledge(
      String discussionId) async {
    String token = await ShPrefs.instance.getStringValue("access_token");

    Response response = await dio.post(
      apiUrl + '/discussions/$discussionId',
      options: Options(headers: {
        "accept": "application/json",
        "Authorization": "Bearer $token",
      }),
    );
    // print(response.statusCode);
    if (response.statusCode == 200 || response.statusCode == 204) {
      Fluttertoast.showToast(
        msg: "تم الإطلاع بنجاح",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } else {
      Fluttertoast.showToast(
        msg: "${response.statusMessage}",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
    return null;
  }

  Future<Map> getDiscussion(String discussionId) async {
    String token = await ShPrefs.instance.getStringValue("access_token");
    try {
      Response response = await dio.get(
        apiUrl + '/discussions/$discussionId',
        options: Options(headers: {
          "accept": "application/json",
          "Authorization": "Bearer $token",
        }),
      );
      // print(response.data);
      if (response.statusCode == 200) {
        // JsonEncoder encoder = new JsonEncoder.withIndent('  ');
        // String prettyPrint = encoder.convert(response.data);
        // // print(prettyPrint);
        // var i = jsonDecode(prettyPrint);
        // // print(dataJson);
        // // print(i["_id"]);
        // DiscussionItem discussionItem = new DiscussionItem(
        //   i["_id"],
        //   i["name"],
        //   i["deadline"],
        //   i["description"],
        //   i["files"],
        //   i["departments"],
        //   i["users"],
        //   i["author"],
        //   i["tags"],
        //   i["created_at"],
        //   i["acked"],
        // );
        // print(discussionItem.files);
        // print(discussionItem);
        // if (discussionItem.files.length > 0) {
        //   discussionItem.savedFiles =
        //       getAttachments(discussionItem.id, discussionItem.files);
        // }
        return response.data;
      }
      // print(response.data);
    } on DioError catch (e) {
      print(e.response.data);
      print(e.response.statusCode);
      Fluttertoast.showToast(
        msg: "${e.response.statusMessage}",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
    return null;
  }

  Future<List<File>> getAttachments(String _id, List<dynamic> files) async {
    List<File> savedFiles = [];
    for (int i = 0; i < files.length; i++) {
      if (files[i]['content'] != 'string' && files[i]['content'] != '') {
        print(files[i]['content']);
        Uint8List bytes = base64.decode(files[i]['content']);
        String dir = (await getTemporaryDirectory()).path;
        File temp = new File('$dir/$_id.${files[i]['name']}');
        await temp.writeAsBytes(bytes);
        savedFiles.add(temp);
      }
    }
    return savedFiles;
  }

  Future<File> getSingleAttachments(
      String _id, Map<String, dynamic> file) async {
    if (file['content'] != 'string' && file['content'] != '') {
      // print(file['content']);
      Uint8List bytes = base64.decode(file['content']);
      String dir = (await getTemporaryDirectory()).path;
      File temp = new File('$dir/$_id.${fixFileName(file['name'])}.pdf');
      await temp.writeAsBytes(bytes);
      return temp;
    }
    return null;
  }

  String fixFileName(String input) {
    return input.replaceAll(' ', '_');
  }

  Map<String, dynamic> prepareSingleAttachment(String path) {
    File temp = new File(path);
    Uint8List fileBytes = temp.readAsBytesSync();
    String encodedFile = base64.encode(fileBytes);

    Map<String, dynamic> selectedFile = {
      'name': path.split('/').last.split('.')[0],
      'content': encodedFile
    };
    // print("from prepare single: $selectedFile");
    return selectedFile;
  }

  Future<List> getDiscussionAckUsers(String discussionId) async {
    String token = await ShPrefs.instance.getStringValue("access_token");
    try {
      print(apiUrl + '/discussions/$discussionId/acks?page=1&per_page=10');
      Response response = await dio.get(
        apiUrl + '/discussions/$discussionId/acks?page=1&per_page=10',
        options: Options(headers: {
          "accept": "application/json",
          "Authorization": "Bearer $token",
        }),
      );
      print(response.data['items'][0]['author']);
      if (response.statusCode == 200) {
        return response.data['items'];
      }
      // print(response.data);
    } on DioError catch (e) {
      print(e.response.data);
      print(e.response.statusCode);
      Fluttertoast.showToast(
        msg: "${e.response.statusMessage}",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
    return null;
  }
}
