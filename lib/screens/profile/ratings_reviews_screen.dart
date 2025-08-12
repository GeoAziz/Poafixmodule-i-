import 'package:flutter/material.dart';

class RatingsReviewsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> reviews = [
    {"review": "Great service!", "rating": 5.0},
    {"review": "Could be better.", "rating": 3.0},
  ];

  RatingsReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Ratings & Reviews")),
      body: ListView.builder(
        itemCount: reviews.length,
        itemBuilder: (context, index) {
          var review = reviews[index];
          return ListTile(
            title: Text(review["review"]!),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, color: Colors.amber),
                Text(review["rating"].toString()),
              ],
            ),
          );
        },
      ),
    );
  }
}
