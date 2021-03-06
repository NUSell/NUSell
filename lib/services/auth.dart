import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:orbital2796_nusell/models/loading.dart';
import 'package:orbital2796_nusell/models/popUp.dart';
import 'package:orbital2796_nusell/models/user.dart';
import 'package:orbital2796_nusell/screens/home.dart';
import 'package:orbital2796_nusell/screens/interests.dart';
import 'package:orbital2796_nusell/screens/login.dart';
import 'package:orbital2796_nusell/screens/signup.dart';
import 'package:orbital2796_nusell/screens/verify.dart';
import 'package:orbital2796_nusell/services/db.dart';

class AuthService with ChangeNotifier {
  NUSellUser _currentUser;
  NUSellUser get currentUser => _currentUser;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseFirestore db = FirebaseFirestore.instance;
  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));
  final _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  Random _rnd = Random();

  signup(String email, String password, BuildContext context) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return loading(
                hasImage: true,
                imagePath: 'assets/images/wavingLion.png',
                hasMessage: true,
                message: "Processing...");
          });
      User firebaseUser = cred.user;
      NUSellUser user = NUSellUser(
          uid: firebaseUser.uid,
          username: getRandomString(12),
          avatarUrl: await FirebaseStorage.instance
              .ref()
              .child('profilepics/default-user-image.png')
              .getDownloadURL());
      print(user.uid);
      await UserDatabaseService(uid: user.uid).setUpFollow(user);
      await UserDatabaseService(uid: user.uid).updateUserData(user);
      await UserDatabaseService(uid: user.uid).setUpSearch(user);
      print(user.uid);
      //Success
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => VerifyScreen(),
          ),
          (_) => false);
    } on FirebaseAuthException catch (error) {
      print(error.message);
      Fluttertoast.showToast(msg: error.message, gravity: ToastGravity.TOP);
    }
  }

  signin(String email, String password, BuildContext context) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      await _auth.currentUser.reload();
      print(_auth.currentUser.emailVerified);
      if (_auth.currentUser.emailVerified) {
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return loading(
                  hasImage: true,
                  imagePath: 'assets/images/wavingLion.png',
                  hasMessage: true,
                  message: "Processing...");
            });

        //Success
        db
            .collection("personalPreference")
            .doc(_auth.currentUser.uid)
            .get()
            .then((doc) {
          if (doc.exists) {
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
                (_) => false);
          } else {
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => InterestsScreen()),
                (_) => false);
          }
        });
      } else {
        await Fluttertoast.showToast(
            msg: "Please verify your email before you log in!");
        showDialog(
            context: context,
            builder: (context) {
              return popUp(
                title: "Please check if you have verified your email!",
                // subtitle: "You will need to sign in again to view your account!",
                //confirmText: "Retry",
                cancelButton: false,
                confirmColor: Color.fromRGBO(100, 170, 255, 1),
                confirmAction: () {
                  Navigator.pop(context);
                },
              );
            });
        print('not verified');
      }
    } on FirebaseAuthException catch (error) {
      print(error.message);
      Fluttertoast.showToast(msg: error.message, gravity: ToastGravity.TOP);
    }
  }

  signout() async {
    await _auth.signOut();
  }

  Future _populateCurrentUser(User user) async {
    if (user != null) {
      _currentUser = await UserDatabaseService(uid: user.uid).getUser();
    }
  }

  Future getCurrentUser() async {
    return _auth.currentUser;
  }

  // GET UID
  String getCurrentUID() {
    return _auth.currentUser.uid;
  }

  getProfileImage() {
    if (_auth.currentUser.photoURL != null) {
      return Image.network(
        _auth.currentUser.photoURL,
        height: 100,
        width: 100,
      );
    } else {
      return Icon(Icons.account_circle, size: 100);
    }
  }

  Future<bool> isUserLogged() async {
    var user = _auth.currentUser;
    await _populateCurrentUser(user);
    return user != null;
  }

  Future deleteUser(String email, String password) async {
    try {
      User user = _auth.currentUser;
      AuthCredential credentials =
          EmailAuthProvider.credential(email: email, password: password);
      print(user);
      UserCredential result =
          await user.reauthenticateWithCredential(credentials);
      await UserDatabaseService(uid: result.user.uid)
          .deleteUser(); // called from database class
      await result.user.delete();
      return true;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<bool> validatePassword(String password) async {
    var firebaseUser = await _auth.currentUser;

    var authCredentials = EmailAuthProvider.credential(
        email: firebaseUser.email, password: password);
    try {
      var authResult =
          await firebaseUser.reauthenticateWithCredential(authCredentials);
      return authResult.user != null;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<void> updatePassword(String password) async {
    var firebaseUser = await _auth.currentUser;
    firebaseUser.updatePassword(password);
  }
}
