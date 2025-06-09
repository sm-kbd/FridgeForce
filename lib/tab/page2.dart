import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(home: Page2()));
}

class Page2 extends StatelessWidget {
  const Page2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('')),
      body: MyPage(), // MyPageをPage2に埋め込む
    );
  }
}

class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('い'),
      ),
    );
  }
}