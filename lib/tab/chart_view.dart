import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(home: ChartsView()));
}

class ChartsView extends StatelessWidget {
  const ChartsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('')),
      body: MyPage(), // MyPageをChartsViewに埋め込む
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
