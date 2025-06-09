import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(home: InputView()));
}

class InputView extends StatelessWidget {
  const InputView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('')),
      body: MyPage(), // MyPageをInputViewに埋め込む
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
