import 'package:flutter/material.dart';

class StatsWidget extends StatelessWidget {
  final String label, value;
  const StatsWidget(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.start,
    crossAxisAlignment: .center,
    children: [
      Text(value, style: TextTheme.of(context).displayMedium),
      Text(label, textAlign: TextAlign.center),
    ],
  );
}
