import 'package:flutter/material.dart';

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:chameleon_icons/chameleon_icons.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  String? _currentIcon = "";
  final _chameleonIconsPlugin = ChameleonIcons();

  @override
  void initState() {
    super.initState();
    initPlatformState();
    getCurrentIcon();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion =
          await _chameleonIconsPlugin.getPlatformVersion() ??
          'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  Future<void> getCurrentIcon() async {
    final icon = await _chameleonIconsPlugin.getCurrentIcon();

    setState(() {
      _currentIcon = icon;
    });
  }

  Future<void> changeIconToDark() async {
    await _chameleonIconsPlugin.changeIcon("MainActivityDark");
  }

  // Future<void> changeIconToOriginal() async {
  //   await _chameleonIconsPlugin.changeIcon("MainActivityDefault");
  // }

  Future<void> changeIconToGold() async {
    await _chameleonIconsPlugin.changeIcon("MainActivityGold");
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Plugin example app')),
        body: Center(
          child: Column(
            children: [
              Text('Running on: $_platformVersion\n'),
              Text("Current Icon: $_currentIcon"),
              ElevatedButton(
                onPressed: () {
                  changeIconToDark();
                },
                child: Text("Change to Dark Icon"),
              ),
              // ElevatedButton(
              //   onPressed: () {
              //     changeIconToOriginal();
              //   },
              //   child: Text("Change to Original Icon"),
              // ),
              ElevatedButton(
                onPressed: () {
                  changeIconToGold();
                },
                child: Text("Change to Gold Icon"),
              ),

              ElevatedButton(
                onPressed: () {
                  _chameleonIconsPlugin.resetIcon();
                },
                child: Text("Reset Icon"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
