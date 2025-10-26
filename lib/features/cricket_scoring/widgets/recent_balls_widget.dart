// lib\features\cricket_scoring\widgets\recent_balls_widget.dart

import 'package:flutter/material.dart';
import '../models/delivery_model.dart';

class RecentBallsWidget extends StatelessWidget {
  final List<DeliveryModel> deliveries;
  final int maxBalls;

  const RecentBallsWidget({
    super.key,
    required this.deliveries,
    this.maxBalls = 6,
  });

  @override
  Widget build(BuildContext context) {
    if (deliveries.isEmpty) {
      return const SizedBox.shrink();
    }

    final recentBalls = deliveries.take(maxBalls).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Balls',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: recentBalls.map((delivery) => _buildBallChip(delivery)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBallChip(DeliveryModel delivery) {

    final totalRuns = delivery.runsScored + (delivery.extraRuns ?? 0);

    Color ballColor;
    String displayText;

    if (delivery.isWicket) {
      ballColor = Colors.red;
      displayText = 'W';
    } else if (delivery.isSix) {
      ballColor = Colors.purple;
      displayText = '6';
    } else if (delivery.isBoundary && delivery.runsScored == 4) {
      ballColor = Colors.blue;
      displayText = '4';
    } else if (delivery.isWide) {
      ballColor = Colors.orange;
      displayText = 'WD';
    } else if (delivery.isNoBall) {
      ballColor = Colors.orange[700]!;
      displayText = 'NB';
    } else {
      ballColor = Colors.grey[400]!;
      displayText = totalRuns.toString();
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: ballColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: ballColor.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          displayText,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
