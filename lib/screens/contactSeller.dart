import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:orbital2796_nusell/main.dart';
import 'package:orbital2796_nusell/models/loading.dart';
import 'package:orbital2796_nusell/models/productLinkWidget.dart';
import 'package:orbital2796_nusell/screens/productinfo.dart';
import 'package:orbital2796_nusell/screens/sellerProfile.dart';
import 'package:path/path.dart' as Path;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:bubble/bubble.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:orbital2796_nusell/models/message.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ContactSellerScreen extends StatefulWidget {
  final String chatID;
  final String theOtherUserId;
  final String theOtherUserName;
  ContactSellerScreen(
      {Key key, this.chatID, this.theOtherUserId, this.theOtherUserName})
      : super(key: key);

  @override
  State<ContactSellerScreen> createState() => _ContactSellerScreenState();
}

class _ContactSellerScreenState extends State<ContactSellerScreen> {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseStorage storage = FirebaseStorage.instance;
  // information of this chat.
  Map<String, dynamic> chat;
  // content of a message.
  String content;
  // the current user's id.
  String userId;
  // the current user's index.
  int userIndex;
  AppMessage message;
  TextEditingController _controller = TextEditingController();

  // Display all previous messages as a list of widgets.
  displayMessages(List<dynamic> history) {
    // bool isReceiver = (userIndex != history.first['user']);
    // print(isReceiver);
    // if ((history.first['time'].seconds - Timestamp.now().seconds) > -50 &&
    //     isReceiver) {
    //   _showNotification(history.first['message']);
    // }
    // print(history.first['time'].seconds);
    // print(Timestamp.now().seconds);
    return history
        .map((message) => Row(
              mainAxisAlignment: userIndex == message["user"]
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Bubble(
                      alignment: userIndex == message["user"]
                          ? Alignment.topRight
                          : Alignment.topLeft,
                      nip: userIndex == message["user"]
                          ? BubbleNip.rightTop
                          : BubbleNip.leftTop,
                      color: userIndex == message["user"]
                          ? Color.fromRGBO(242, 195, 71, 0.7)
                          : Colors.white,
                      margin: userIndex == message["user"]
                          ? BubbleEdges.only(bottom: 15, left: 70)
                          : BubbleEdges.only(bottom: 15, right: 70),
                      child: message["message"] != null
                          ? Text(message["message"],
                              style: TextStyle(fontSize: 16))
                          : message["imgURL"] != null
                            ? ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: 200,
                                maxWidth: 150,
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  showDialog(
                                      barrierColor: Colors.black,
                                      context: context,
                                      builder: (BuildContext context) {
                                        return Dialog(
                                          insetPadding: EdgeInsets.all(0),
                                          child: Container(
                                            color: Colors.black,
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  margin: EdgeInsets.only(
                                                      bottom: 50),
                                                  child: ElevatedButton(
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                    child: Icon(
                                                      Icons.arrow_back,
                                                      color: Colors.white,
                                                      size: 30,
                                                    ),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      primary:
                                                          Colors.transparent,
                                                    ),
                                                  ),
                                                ),
                                                CachedNetworkImage(
                                                  imageUrl: message["imgURL"],
                                                  fadeInDuration:
                                                      const Duration(
                                                          milliseconds: 10),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      });
                                },
                                child: CachedNetworkImage(
                                  imageUrl: message["imgURL"],
                                  fadeInDuration:
                                      const Duration(milliseconds: 10),
                                  progressIndicatorBuilder: (context, url, downloadProgress) =>
                                      CircularProgressIndicator(value: downloadProgress.progress),
                                  errorWidget: (context, url, error) => Icon(Icons.error),
                                ),
                              ),
                            )
                            : productLinkWidget(
                                productId: message["productId"],
                                smallPreview: true,
                                action: () {
                                  Navigator.of(context).push(
                                      MaterialPageRoute(builder:
                                          (context) => ProductInfoScreen(product: message["productId"])
                                      )
                                  );
                                },
                              ),
                  ),
                ),
              ],
            ))
        .toList();
  }

  // In a chat, return the index of the user,
  // return -1 if the user is not in the chat.
  int getUserIndex(String userID, List<dynamic> users) {
    int len = users.length;
    var i;
    for (i = 0; i < len; i++) {
      if (users[i].toString() == userID) {
        return i;
      }
    }
    return -1;
  }

  // upload image or take a photo from device.
  Future<String> uploadImage(bool gallery) async {
    ImagePicker picker = ImagePicker();
    PickedFile pickedFile;
    if (gallery) {
      await Permission.mediaLibrary.request();
      pickedFile = await picker.getImage(
        source: ImageSource.gallery,
        imageQuality: 30,
      );
    } else {
      await Permission.camera.request();
      pickedFile = await picker.getImage(
        source: ImageSource.camera,
        imageQuality: 30,
      );
    }
    File img = File(pickedFile.path);
    Reference ref = storage.ref().child('chatpics/${Path.basename(img.path)}');
    await ref.putFile(File(img.path));
    String url = await ref.getDownloadURL();
    return url;
  }

  @override
  Widget build(BuildContext context) {
    this.userId = auth.currentUser.uid;
    // set cursor position to be end of the text.
    _controller.text = this.content;
    _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length));

    print(this.userId);
    print(widget.theOtherUserId);
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: InkWell(
          onTap: () {
            Navigator.of(context).push(
                MaterialPageRoute(builder: (context) =>
                    SellerProfileScreen(sellerId: widget.theOtherUserId,)));
          },
          child: Text(widget.theOtherUserName == null
              ? widget.chatID
              : widget.theOtherUserName),
        ),
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(new FocusNode());
        },
        child: Container(
          color: Color.fromRGBO(0, 0, 0, 0.1),
          child: ListView(
            children: [
              StreamBuilder(
                  stream: db.collection("chats").doc(widget.chatID).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return LinearProgressIndicator();
                    return Container(
                      height: MediaQuery.of(context).size.height * 0.8,
                      child: FutureBuilder<DocumentSnapshot>(
                        // get information of the current chat.
                        future: db.collection("chats").doc(widget.chatID).get(),
                        builder: (BuildContext context,
                            AsyncSnapshot<DocumentSnapshot> snapshot) {
                          if (!snapshot.hasData) {
                            return Center(child: CircularProgressIndicator());
                          }
                          this.chat = snapshot.data.data();
                          // list of previous messages.
                          List<dynamic> history = [];
                          if (chat != null) {
                            history = List.from(chat["history"].reversed);
                            this.userIndex =
                                getUserIndex(this.userId, chat["users"]);
                            if (chat["unread"][this.userId] != 0) {
                              Map updatedVals = {};
                              updatedVals[this.userId] = 0;
                              updatedVals[widget.theOtherUserId] = 0;
                              db
                                  .collection("chats")
                                  .doc(widget.chatID)
                                  .update({"unread": updatedVals});
                            }
                          }
                          return Container(
                            margin: EdgeInsets.only(left: 30, right: 30),
                            child: ListView(
                              reverse: true,
                              children: displayMessages(history),
                            ),
                          );
                        },
                      ),
                    );
                  }),

              // send messages
              Container(
                color: Color.fromRGBO(0, 0, 0, 0.05),
                padding: EdgeInsets.only(top: 5, bottom: 20),
                child: Row(
                  children: [
                    // Input text, return to send message.
                    Container(
                      margin: EdgeInsets.only(left: 20, right: 10),
                      width: MediaQuery.of(context).size.width * 0.65,
                      child: TextField(
                        textInputAction: TextInputAction.send,
                        keyboardType: TextInputType.multiline,
                        minLines: 1,
                        maxLines: null,
                        cursorRadius: Radius.circular(1),
                        toolbarOptions: ToolbarOptions(
                            copy: true,
                            cut: true,
                            paste: true,
                            selectAll: true),
                        decoration: InputDecoration(
                          isDense: true,
                          focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.transparent)),
                          enabledBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.transparent)),
                          fillColor: Colors.white,
                          filled: true,
                          contentPadding: EdgeInsets.all(10),
                        ),
                        controller: _controller,
                        onChanged: (value) {
                          this.content = value;
                        },
                        onSubmitted: (value) async {
                          this.content = value;
                          if (this.content != null && this.content != "") {
                            this.message = AppMessage(
                                this.userIndex, Timestamp.now(), this.content);
                            final Map<String, int> updatedVals = {
                              widget.theOtherUserId: chat["unread"][widget.theOtherUserId] == null
                                  ? 1
                                  : chat["unread"][widget.theOtherUserId] + 1,
                              this.userId: 0};
                            db.collection("chats").doc(widget.chatID).update({
                              "history":
                              FieldValue.arrayUnion([this.message.toMap()]),
                              "unread": updatedVals
                            });
                            //_showNotification(value);
                            _controller.text = "";
                            this.content = "";
                            this.message = null;
                          }
                        },
                      ),
                    ),
                    // more functions button
                    InkWell(
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.1,
                        height: MediaQuery.of(context).size.width * 0.1,
                        margin: EdgeInsets.only(right: 5),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.black,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(
                              MediaQuery.of(context).size.width * 0.1),
                          ),
                        child: Icon(Icons.add, size: 20),
                      ),
                      onTap: () {
                        showModalBottomSheet(
                            context: context,
                            builder: (context) {
                              var heightOfSheet = MediaQuery.of(context).size.width / 4 + 15;
                              var sizeOfIcon = MediaQuery.of(context).size.width / 12;
                              return Container(
                                height: heightOfSheet,
                                padding: EdgeInsets.all(5),
                                color: Color.fromRGBO(249, 248, 253, 1),
                                child: GridView.count(
                                    crossAxisCount: 4,
                                  crossAxisSpacing: 0,
                                  mainAxisSpacing: 0,
                                  children: [
                                    // send image from gallery
                                    Container(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                        children: [
                                          Card(
                                            color: Color.fromRGBO(242, 195, 71, 0.1),
                                            elevation: 0,
                                            child: IconButton(
                                              icon: Icon(Icons.photo),
                                              iconSize: sizeOfIcon,
                                              padding: EdgeInsets.zero,
                                              color: Color.fromRGBO(242, 195, 71, 0.9),
                                              onPressed: () async {
                                                showDialog(
                                                    context: context,
                                                    barrierDismissible: false,
                                                    builder: (context) {
                                                      return loading(
                                                          hasImage: false,
                                                          hasMessage: false);
                                                    });
                                                String url = await uploadImage(true);
                                                this.message =
                                                    ImageMessage(userIndex, Timestamp.now(), url);
                                                final Map<String, int> updatedVals = {
                                                  widget.theOtherUserId: chat["unread"][widget.theOtherUserId] == null
                                                      ? 1
                                                      : chat["unread"][widget.theOtherUserId] + 1,
                                                  this.userId: 0};
                                                db.collection("chats").doc(widget.chatID).update({
                                                  "history":
                                                  FieldValue.arrayUnion([this.message.toMap()]),
                                                  "unread": updatedVals
                                                });
                                                this.message = null;
                                                Navigator.of(context).pop();
                                                Navigator.of(context).pop();
                                              },
                                            ),
                                          ),
                                          Text(
                                            "Gallery",
                                            style: TextStyle(
                                              color: Color.fromRGBO(242, 195, 71, 1),
                                              fontWeight: FontWeight.w300,
                                                fontSize: 12
                                            ),
                                          )
                                        ],
                                      ),
                                    ),

                                    // take photo from camera
                                    Container(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                        children: [
                                          Card(
                                            color: Color.fromRGBO(242, 195, 71, 0.1),
                                            elevation: 0,
                                            child: IconButton(
                                              icon: Icon(Icons.camera_alt),
                                              iconSize: sizeOfIcon,
                                              padding: EdgeInsets.zero,
                                              color: Color.fromRGBO(242, 195, 71, 0.9),
                                              onPressed: () async {
                                                showDialog(
                                                    context: context,
                                                    barrierDismissible: false,
                                                    builder: (context) {
                                                      return loading(
                                                          hasImage: false,
                                                          hasMessage: false);
                                                    });
                                                String url = await uploadImage(false);
                                                this.message =
                                                    ImageMessage(userIndex, Timestamp.now(), url);
                                                final Map<String, int> updatedVals = {
                                                  widget.theOtherUserId: chat["unread"][widget.theOtherUserId] == null
                                                      ? 1
                                                      : chat["unread"][widget.theOtherUserId] + 1,
                                                  this.userId: 0};
                                                db.collection("chats").doc(widget.chatID).update({
                                                  "history":
                                                  FieldValue.arrayUnion([this.message.toMap()]),
                                                  "unread": updatedVals
                                                });
                                                this.message = null;
                                                Navigator.of(context).pop();
                                                Navigator.of(context).pop();
                                              },
                                            ),
                                          ),
                                          Text(
                                            "Camera",
                                            style: TextStyle(
                                                color: Color.fromRGBO(242, 195, 71, 1),
                                                fontWeight: FontWeight.w300,
                                                fontSize: 12
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // send their products
                                    Container(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                        children: [
                                          Card(
                                            color: Color.fromRGBO(242, 195, 71, 0.1),
                                            elevation: 0,
                                            child: IconButton(
                                              icon: Icon(Icons.link),
                                              iconSize: sizeOfIcon,
                                              padding: EdgeInsets.zero,
                                              color: Color.fromRGBO(242, 195, 71, 0.9),
                                              onPressed: () {
                                                showModalBottomSheet(
                                                    context: context,
                                                    builder: (context) {
                                                      return StreamBuilder(
                                                        stream: db.collection("myPosts").doc(widget.theOtherUserId).snapshots(),
                                                          builder: (context, snapshot) {
                                                            if (!snapshot.hasData) {
                                                              return CircularProgressIndicator();
                                                            }
                                                            var postsOfTheSeller = snapshot.data.data();
                                                            return ListView(
                                                              children: postsOfTheSeller["myPosts"]
                                                                  .map<Widget>((productId) {
                                                                    return productLinkWidget(
                                                                        productId: productId,
                                                                      smallPreview: false,
                                                                      action: () {
                                                                          this.message =
                                                                              LinkMessage(userIndex, Timestamp.now(), productId);
                                                                          final Map<String, int> updatedVals = {
                                                                            widget.theOtherUserId: chat["unread"][widget.theOtherUserId] == null
                                                                                ? 1
                                                                                : chat["unread"][widget.theOtherUserId] + 1,
                                                                            this.userId: 0};
                                                                          db.collection("chats").doc(widget.chatID).update({
                                                                            "history":
                                                                            FieldValue.arrayUnion([this.message.toMap()]),
                                                                            "unread": updatedVals
                                                                          });
                                                                          this.message = null;
                                                                          Navigator.of(context).pop();
                                                                          Navigator.of(context).pop();
                                                                      },
                                                                    );
                                                              }).toList(),
                                                            );
                                                          }
                                                      );
                                                    }
                                                );
                                              },
                                            ),
                                          ),
                                          Text(
                                            "Their Products",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                color: Color.fromRGBO(242, 195, 71, 1),
                                                fontWeight: FontWeight.w300,
                                                fontSize: 12
                                            ),
                                          )
                                        ],
                                      ),
                                    ),

                                    // send my products
                                    Container(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                        children: [
                                          Card(
                                            color: Color.fromRGBO(242, 195, 71, 0.1),
                                            elevation: 0,
                                            child: IconButton(
                                              icon: Icon(Icons.storage),
                                              iconSize: sizeOfIcon,
                                              padding: EdgeInsets.zero,
                                              color: Color.fromRGBO(242, 195, 71, 0.9),
                                              onPressed: () {
                                                showModalBottomSheet(
                                                    context: context,
                                                    builder: (context) {
                                                      return StreamBuilder(
                                                          stream: db.collection("myPosts").doc(this.userId).snapshots(),
                                                          builder: (context, snapshot) {
                                                            if (!snapshot.hasData) {
                                                              return CircularProgressIndicator();
                                                            }
                                                            var postsOfTheSeller = snapshot.data.data();
                                                            return ListView(
                                                              children: postsOfTheSeller["myPosts"]
                                                                  .map<Widget>((productId) {
                                                                return productLinkWidget(
                                                                  productId: productId,
                                                                  smallPreview: false,
                                                                  action: () {
                                                                    this.message =
                                                                        LinkMessage(userIndex, Timestamp.now(), productId);
                                                                    final Map<String, int> updatedVals = {
                                                                      widget.theOtherUserId: chat["unread"][widget.theOtherUserId] == null
                                                                          ? 1
                                                                          : chat["unread"][widget.theOtherUserId] + 1,
                                                                      this.userId: 0};
                                                                    db.collection("chats").doc(widget.chatID).update({
                                                                      "history":
                                                                      FieldValue.arrayUnion([this.message.toMap()]),
                                                                      "unread": updatedVals
                                                                    });
                                                                    this.message = null;
                                                                    Navigator.of(context).pop();
                                                                    Navigator.of(context).pop();
                                                                  },
                                                                );
                                                              }).toList(),
                                                            );
                                                          }
                                                      );
                                                    }
                                                );
                                              },
                                            ),
                                          ),
                                          Text(
                                            "My Products",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                color: Color.fromRGBO(242, 195, 71, 1),
                                                fontWeight: FontWeight.w300,
                                                fontSize: 12
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            });
                      },
                    ),
                    // send message button
                    InkWell(
                      onTap: () async {
                        if (this.content != null && this.content != "") {
                          this.message = AppMessage(
                              this.userIndex, Timestamp.now(), this.content);
                          final Map<String, int> updatedVals = {
                            widget.theOtherUserId: chat["unread"][widget.theOtherUserId] == null
                                ? 1
                                : chat["unread"][widget.theOtherUserId] + 1,
                            this.userId: 0};
                          db.collection("chats").doc(widget.chatID).update({
                            "history":
                            FieldValue.arrayUnion([this.message.toMap()]),
                            "unread": updatedVals
                          });
                          //_showNotification(value);
                          _controller.text = "";
                          this.content = "";
                          this.message = null;
                        }
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.1,
                        height: MediaQuery.of(context).size.width * 0.1,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.black,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(
                              MediaQuery.of(context).size.width * 0.1),
                        ),
                        child: Icon(Icons.keyboard_return, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future _showNotification(String message) async {
    var androidDetails = AndroidNotificationDetails(
        "channelId", "NUSell", "This is channel for chat notifications");
    var generalNotificationDetails =
        new NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
        0, "New Message", message, generalNotificationDetails);
  }
}