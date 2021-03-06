import 'dart:ffi';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:orbital2796_nusell/models/review.dart';
import 'package:orbital2796_nusell/screens/profile.dart';
import 'package:orbital2796_nusell/screens/profile/avatar.dart';
import 'package:orbital2796_nusell/services/auth.dart';

class ReviewsForUser extends StatefulWidget {
  final String userId;
  final bool isForOwn;
  const ReviewsForUser({Key key, this.userId, this.isForOwn = true})
      : super(key: key);
  @override
  _ReviewsForUserState createState() => _ReviewsForUserState();
}

class _ReviewsForUserState extends State<ReviewsForUser> {
  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    var padding = MediaQuery.of(context).padding;
    double newheight = height - padding.top - padding.bottom;
    return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reviews')
            .doc(widget.userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot == null || snapshot.data == null)
            return Center(child: CircularProgressIndicator());
          Map<String, dynamic> doc = snapshot.data.data();
          if (doc == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 56, 16, 36),
                child: Text('No reviews yet'),
              ),
            );
          }
          if (snapshot.hasError) {
            return Text('Something went wrong');
          }

          List reviews = List.from(doc['reviews']);
          double score;
          score = doc['averageRating'].toDouble();
          return Container(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    //crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${score.toStringAsFixed(2)}',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 25),
                      ),
                      RatingBarIndicator(
                        rating: score,
                        itemBuilder: (context, index) => Icon(
                          Icons.star,
                          color: Colors.amber,
                        ),
                        itemCount: 5,
                        itemSize: 20.0,
                        direction: Axis.horizontal,
                      ),
                      Text('${reviews.length} reviews'),
                    ],
                  ),
                ),
                Container(
                  height:
                      widget.isForOwn ? newheight * 3 / 5 : newheight * 5 / 11,
                  child: ListView(
                    children: reviews.map((review) {
                      return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .doc(review['reviewFromUser'])
                              .get(),
                          builder: (context2, snapshot2) {
                            if (!snapshot2.hasData || snapshot2.data == null)
                              return Center(child: CircularProgressIndicator());
                            Map<String, dynamic> userDoc =
                                snapshot2.data.data();
                            if (snapshot2.connectionState ==
                                ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }
                            if (userDoc == null) {
                              return Container();
                            }
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Avatar(
                                            avatarUrl: userDoc['avatarUrl'],
                                            size: 25,
                                          ),
                                          SizedBox(
                                            height: 10,
                                          ),
                                          Text(
                                            '${userDoc['username']}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        width: 20,
                                      ),
                                      Container(
                                          child: Text(review['description'])),
                                    ],
                                  ),
                                  Text("${review['rating']}")
                                ],
                              ),
                            );
                          });
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        });
  }
}
