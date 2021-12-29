import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class Settings extends StatefulWidget {
  @override
  SettingsState createState() => SettingsState();
}

class SettingsState extends State<Settings> {
  bool isSwitched = false;

  @override
  Widget build(BuildContext context) {
    return Text("Settings");
  }
}
