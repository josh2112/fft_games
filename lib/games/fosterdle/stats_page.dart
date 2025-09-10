import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Fosterdle Stats'), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('you did it'),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () => GoRouter.of(context).go('/'), child: Text("Home")),
          ],
        ),
      ),
    );
  }
}
