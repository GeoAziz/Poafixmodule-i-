import 'package:flutter/material.dart';

class ProfessionalCard extends StatelessWidget {
  final String name;
  final String designation;
  final double rating;
  final String? imagePath;
  final VoidCallback? onTap;

  const ProfessionalCard({
    Key? key,
    required this.name,
    required this.designation,
    required this.rating,
    this.imagePath,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: onTap,
        child: ListTile(
          leading: imagePath != null
              ? CircleAvatar(backgroundImage: AssetImage(imagePath!))
              : CircleAvatar(child: Icon(Icons.person)),
          title: Text(name),
          subtitle: Text(designation),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star, color: Colors.orange),
              Text("$rating"),
            ],
          ),
        ),
      ),
    );
  }
}
