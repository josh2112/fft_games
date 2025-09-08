import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

class PlayPage extends StatefulWidget {
  const PlayPage({super.key});

  @override
  State<PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends State<PlayPage> {
  static final _log = Logger('PlaySessionScreen');

  @override
  Widget build(BuildContext context) {
    return Text("Here we are in Fosterdle");
  }
}
