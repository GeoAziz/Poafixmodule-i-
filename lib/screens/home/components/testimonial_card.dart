import 'package:flutter/material.dart';

class TestimonialCard extends StatelessWidget {
  final String name;
  final String review;
  final VoidCallback? onTap;

  const TestimonialCard({
    Key? key,
    required this.name,
    required this.review,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: onTap,
        child: ListTile(title: Text(name), subtitle: Text(review)),
      ),
    );
  }
}
