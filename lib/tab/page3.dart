import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(home: Page3()));
}

class Page3 extends StatelessWidget {
  const Page3({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('')),
      body: MyPage(), // MyPageをPage3に埋め込む
    );
  }
}

class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('う'),
      ),
    );
  }
}