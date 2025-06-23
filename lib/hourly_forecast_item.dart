import 'package:flutter/material.dart';

//since we need multiple cards in a row, it's better to create a seperate widget class for card for it so that
//changes are reflected in every card if any changes are made.
class HourlyForecastItem extends StatelessWidget {
  final String time;
  final String icon;
  final String temperature;
  const HourlyForecastItem({
    super.key,
    required this.time,
    required this.icon,
    required this.temperature,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              time,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow
                  .ellipsis, //indicates if the text is overflowing from the widget
            ),
            const SizedBox(height: 8),
            Image.network(
              icon,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.error),
            ),
            const SizedBox(height: 8),
            Text(
              '$temperature °K',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
