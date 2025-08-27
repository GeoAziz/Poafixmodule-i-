import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AnimatedStatusCard extends StatelessWidget {
  final bool isAvailable;
  final Function() onToggle;
  final AnimationController animationController;

  const AnimatedStatusCard({
    super.key,
    required this.isAvailable,
    required this.onToggle,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: AnimatedBuilder(
        animation: animationController,
        builder: (context, child) {
          return Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  isAvailable ? Colors.green : Colors.grey,
                  isAvailable ? Colors.green.shade700 : Colors.grey.shade700,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Status',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      isAvailable ? 'Available' : 'Unavailable',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: isAvailable,
                  onChanged: (_) => onToggle(),
                  activeColor: Colors.white,
                  activeTrackColor: Colors.green.shade300,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
