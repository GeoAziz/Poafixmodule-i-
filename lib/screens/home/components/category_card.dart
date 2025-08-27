import 'package:flutter/material.dart';

class CategoryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? imagePath;

  const CategoryCard({
    Key? key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.imagePath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 2,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (imagePath != null)
              Image.asset(imagePath!, height: 40)
            else
              Icon(icon, size: 40),
            const SizedBox(height: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}
