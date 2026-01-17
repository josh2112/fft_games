import 'package:flutter/material.dart';

class StatsWidget extends StatelessWidget {
  final String label, value;
  const StatsWidget(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 85,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(value, style: TextTheme.of(context).displayMedium),
        Text(label, textAlign: TextAlign.center),
      ],
    ),
  );
}
