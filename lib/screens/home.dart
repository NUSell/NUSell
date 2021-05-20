import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:orbital2796_nusell/screens/post.dart';
import 'package:orbital2796_nusell/screens/profile.dart';

class HomeScreen extends StatelessWidget {
  final auth = FirebaseAuth.instance;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //a collection of three floating action buttons, on pressed will
      //turn to another page
      body: Center(
        child: Text('Home'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            FloatingActionButton(
              heroTag: "home",
              onPressed: () {},
              child: Icon(Icons.house),
            ),
            FloatingActionButton(
              heroTag: "post",
              onPressed: () {
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => PostScreen()));
              },
              child: Icon(Icons.add),
            ),
            FloatingActionButton(
              heroTag: "profile",
              onPressed: () {
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => ProfileScreen()));
              },
              child: Icon(Icons.person),
            )
          ],
        ),
      ),
    );
  }
}