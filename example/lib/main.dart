import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:fb_drop_down/fb_drop_down.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Container(
            // height: 100,
            width: 300,
            // color: Colors.grey,
            child: FBDropDown(
              items: ['圈子频道1', '圈子频道2', '圈子频道3', '圈子频道4', '圈子频道5', '圈子频道6'],
            ),
          ),
        ),
      ),
    );
  }
}
