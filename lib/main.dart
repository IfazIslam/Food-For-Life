import 'package:flutter/material.dart';

void main() => runApp(MaterialApp(
  home: Scaffold(
    appBar: AppBar(
      title: Text('Food For Life'),
      centerTitle: true,
    ),
    body: Center(
      child: Text('Welcome to Food For Life'),
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: () {
        print('Button clicked!');
      },
      child: Center(child: Text('Click', style: TextStyle(fontSize: 12))),
    ),
  ),
));