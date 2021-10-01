import 'package:ars_progress_dialog/dialog.dart';
import 'package:chat_koddev/api/rest_api.dart';
import 'package:chat_koddev/controllers/chat_controller.dart';
import 'package:chat_koddev/controllers/friend_controller.dart';
import 'package:chat_koddev/controllers/user_controller.dart';
import 'package:chat_koddev/helper/app_progress_dialog.dart';
import 'package:chat_koddev/helper/app_session.dart';
import 'package:chat_koddev/helper/colors.dart';
import 'package:chat_koddev/models/chat.dart';
import 'package:chat_koddev/models/friend.dart';
import 'package:chat_koddev/models/user.dart';
import 'package:chat_koddev/screens/login_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

class AppApi {

  AppApi();

  login(response) async {

    await AppSession().addSessions(
        uid: response['user']['id'],
        token: response['data']['access_token'],
        login: 'true',
        expiresAt: (response['data']['expires_in']).toString()
    );

    await _addCache(response);

  }

  logout(context) async {
    AppProgressDialog progressDialog = AppProgressDialog(context);
    progressDialog.show();

    RestApi().logout(
      onResponse: (response) {
        print(response['message']);
      },
      onError: (error) {
        print(error);
      }
    );

    await _clearCache();

    await AppSession().addSessions(login: 'false');
    progressDialog.hide();

    Navigator.of(context).popUntil((route) => route.isFirst);
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => LoginScreen()
    ));
  }

  refreshToken() async {
    RestApi restApi = RestApi();
    await restApi.refreshToken(
        onResponse: (response) async {
          var token = response['data']['access_token'];
          await AppSession().addSessions(
              token: token,
              expiresAt: (response['data']['expires_in']).toString()
          );
          print('Token refreshed: $token');
        },
        onError: (error) {
          print(error);
        }
    );
  }

  _addCache(response) async {
    UserController userController = Get.find();
    ChatController chatController = Get.find();
    FriendController friendController = Get.find();

    //user
    User u = User.fromJson(response['user']);
    await userController.updateUser(u);

    //chats
    var chats = List<Chat>();
    var list = response['chats'];
    for(var data in list){
      chats.add(Chat.fromJson(data));
    }
    await chatController.updateChats(chats);

    //friends
    var friends = List<Friend>();
    var listFriends = response['friends'];
    for(var data in listFriends){
      friends.add(Friend.fromJson(data));
    }
    await friendController.updateFriends(friends);
  }

  _clearCache() async {
    var user = await Hive.openBox('user');
    var chats = await Hive.openBox('chats');
    var friends = await Hive.openBox('friends');

    await user.clear();
    await chats.clear();
    await friends.clear();
  }

}