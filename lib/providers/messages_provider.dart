import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pdfviewer/models/message_comment_item.dart';
import 'package:pdfviewer/models/message_item.dart';
import 'package:pdfviewer/models/new_message.dart';
import 'package:pdfviewer/providers/login_provider.dart';
import 'package:pdfviewer/providers/sh_prefs.dart';

var apiUrl = "https://share.i.wdex.email/api/v1";

LoginProvider userAuth = new LoginProvider();
Dio dio;

class MessagesProvider {
  addNewMessage(CreateMessageItem _createMessageItem) async {
    String token = await ShPrefs.instance.getStringValue("access_token");
    try {
      Response response = await dio.post(
        apiUrl + '/messages/',
        data: jsonEncode({
          "text": _createMessageItem.text,
          "users": _createMessageItem.users,
          "deadline": _createMessageItem.deadline,
          "departments": _createMessageItem.departments,
          "visible_comments": _createMessageItem.visibleComments
        }),
        options: Options(headers: {
          "accept": "application/json",
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        Fluttertoast.showToast(
          msg: "تم إضافة الرسالة بنجاح",
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

  Future<List<MessageItem>> getAllMessagesP({int pageNum = 1}) async {
    try {
      int maxPages = pageNum;
      String maxPageS = await ShPrefs.instance.getStringValue('messagesPages');

      if (maxPageS != "") {
        maxPages = int.parse(maxPageS);
      }
      print("maxP " + maxPages.toString());
      print("pageNum " + pageNum.toString());
      print(apiUrl + '/messages/?page=$pageNum&per_page=5');
      if (pageNum <= maxPages) {
        // print('hello here');
        Response response = await dio.get(
          apiUrl + '/messages/?page=$pageNum&per_page=5',
          options: Options(headers: {
            "accept": "application/json",
          }),
        );

        ShPrefs.instance
            .setStringValue('messagesPages', response.data['pages'].toString());
        print(apiUrl + '/messages/?page=$pageNum&per_page=5');
        // print(response.data);
        List<MessageItem> messagesItems = [];
        if (response.statusCode == 200) {
          JsonEncoder encoder = new JsonEncoder.withIndent('  ');
          String prettyPrint = encoder.convert(response.data);
          // print(prettyPrint);
          List dataJson = jsonDecode(prettyPrint)["items"];
          // print(dataJson);
          for (var i in dataJson) {
            // print(i["_id"]);
            MessageItem messageItem = new MessageItem(
              i["_id"],
              i["author"],
              i["text"],
              i["users"],
              i["departments"],
              i["created_at"],
              i["visible_comments"],
            );
            // print(discussionItem.files);
            messagesItems.add(messageItem);
          }
          return messagesItems;
        }
      }
    } on DioError catch (e) {
      print('error');
      print(e.response.data);
      print(e.error);
    }
    return null;
  }

  Future<Map> getMessage(String discussionId) async {
    String token = await ShPrefs.instance.getStringValue("access_token");
    try {
      Response response = await dio.get(
        apiUrl + '/messages/$discussionId',
        options: Options(headers: {
          "accept": "application/json",
          "Authorization": "Bearer $token",
        }),
      );
      print(response.data);
      if (response.statusCode == 200) {
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

  deleteMessage(String discussionId) async {
    String token = await ShPrefs.instance.getStringValue("access_token");
    try {
      Response response = await dio.delete(
        apiUrl + '/messages/$discussionId',
        options: Options(headers: {
          "accept": "application/json",
          "Authorization": "Bearer $token",
        }),
      );
      // print(apiUrl + '/discussions/$discussionId');
      if (response.statusCode == 200 || response.statusCode == 204) {
        Fluttertoast.showToast(
          msg: "تم مسح الرسالة بنجاح",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    } on DioError catch (e) {
      print(apiUrl + '/messages/$discussionId');
      print(e.response.data);
      print(e.response.statusCode);
    }
  }

  updateMessage(String messageId, String text, List<dynamic> departments,
      List<dynamic> users, String createdAt, bool visibleComments) async {
    String token = await ShPrefs.instance.getStringValue("access_token");
    try {
      Response response = await dio.put(
        apiUrl + '/messages/$messageId',
        data: jsonEncode({
          "text": text,
          "departments": departments,
          "users": users,
          "created_at": createdAt,
          "visible_comments": visibleComments
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

  Future<List<MessageCommentItem>> addMessageComment(
      String messageId, String text) async {
    String token = await ShPrefs.instance.getStringValue("access_token");

    Response response = await dio.post(
      apiUrl + '/messages/$messageId/comments',
      data: {
        "text": "$text",
      },
      options: Options(headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      }),
    );
    if (response.statusCode == 200) {
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

  Future<List<MessageCommentItem>> getAllMessageComment(
      String messageId) async {
    String token = await ShPrefs.instance.getStringValue("access_token");
    try {
      Response response = await dio.get(
        apiUrl + '/messages/$messageId/comments?page=1&per_page=50',
        options: Options(headers: {
          "accept": "application/json",
          "Authorization": "Bearer $token",
        }),
      );
      // print(response.data);
      List<MessageCommentItem> _messageCommentItems = [];
      if (response.statusCode == 200) {
        JsonEncoder encoder = new JsonEncoder.withIndent('  ');
        String prettyPrint = encoder.convert(response.data);
        List dataJson = jsonDecode(prettyPrint)["items"];
        for (var i in dataJson) {
          MessageCommentItem _messageCommentItem = new MessageCommentItem(
            i["message_id"],
            i["comment_id"],
            i["author"],
            i["text"],
            i["created_at"],
          );
          _messageCommentItems.add(_messageCommentItem);
        }
        return _messageCommentItems;
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

  Future<List<MessageCommentItem>> deleteMessageComment(
      String messageId, String commentId) async {
    String token = await ShPrefs.instance.getStringValue("access_token");
    try {
      Response response = await dio.delete(
        apiUrl + '/messages/$messageId/comments/$commentId',
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
}
