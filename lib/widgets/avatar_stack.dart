import 'package:flutter/material.dart';
import '../models/models.dart';

class AvatarStack extends StatelessWidget {
  final List<Member> members;
  final double size;
  final int maxDisplay;

  const AvatarStack({
    super.key,
    required this.members,
    this.size = 28.0,
    this.maxDisplay = 4,
  });

  @override
  Widget build(BuildContext context) {
    final displayMembers = members.take(maxDisplay).toList();
    final remainingCount = members.length - maxDisplay;

    return SizedBox(
      height: size,
      width: (displayMembers.length * (size * 0.65)) + (remainingCount > 0 ? (size * 0.75) : (size * 0.35)),
      child: Stack(
        children: [
          for (int i = 0; i < displayMembers.length; i++)
            Positioned(
              left: i * (size * 0.65),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: displayMembers[i].avatarColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    displayMembers[i].avatarEmoji,
                    style: TextStyle(fontSize: size * 0.5),
                  ),
                ),
              ),
            ),
          if (remainingCount > 0)
            Positioned(
              left: displayMembers.length * (size * 0.65),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: const Color(0xFF9AA3B2).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    '+$remainingCount',
                    style: TextStyle(
                      fontSize: size * 0.4,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4B5563),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
