import 'package:flutter/material.dart';
import 'package:flutter_spinbox/material.dart';

void main() {
    runApp(MyApp());
}

class MyApp extends StatelessWidget {
    const MyApp({ Key? key }) : super(key: key);

    @override
        Widget build(BuildContext context) {
            return MaterialApp(
                    home: Scaffold(
                        appBar: AppBar(
                            title: const Text("FridgeForce"),
                            backgroundColor: Colors.green,
                            ),

                        body: ListView(
                            padding: const EdgeInsets.only(top: 100, bottom: 100, left: 20, right: 20),
                            shrinkWrap: true,
                            children: [
                            Container(
                            child: Row(
                                children: [
                                Container(
                                    height: 100,
                                    width: 100,
                                    decoration: BoxDecoration(border: Border.all(color: Colors.black)),
                                    child: IconButton(
                                        onPressed: () {},
                                        icon: Icon(Icons.photo_camera)
                                        ),
                                    ),
                                Expanded(
                                    child: Container(
                                        padding: EdgeInsets.only(left: 20),
                                        child: TextField(
                                            decoration: const InputDecoration(
                                                label: Text("食材名"),
                                                ),
                                            ),
                                        ),
                                    ),
                                ],
                                ),
                                ),
                            Container(
                            child: Row(
                                children: [
                                Expanded(
                                    child: Container(
                                        padding: EdgeInsets.only(left: 20),
                                        child: TextField(
                                            decoration: const InputDecoration(
                                                label: Text("年"),
                                                ),
                                            ),
                                        ),
                                    ),
                                Expanded(
                                    child: Container(
                                        padding: EdgeInsets.only(left: 20),
                                        child: TextField(
                                            decoration: const InputDecoration(
                                                label: Text("月"),
                                                ),
                                            ),
                                        ),
                                    ),
                                Expanded(
                                    child: Container(
                                        padding: EdgeInsets.only(left: 20),
                                        child: TextField(
                                            decoration: const InputDecoration(
                                                label: Text("日"),
                                                ),
                                            ),
                                        ),
                                    ),
                                ],
                                ),
                                ),
                            Container(
                            child: Row(
                                children: [
                                Expanded(
                                    child: Container(
                                        padding: EdgeInsets.only(left: 20),
                                        child: TextField(
                                            decoration: const InputDecoration(
                                                label: Text("カテゴリー"),
                                                ),
                                            ),
                                        ),
                                    ),
                                Container(
                                        width: 130,
                                        padding: EdgeInsets.only(left: 20, top: 20),
                                        child: SpinBox(
                                            min: 1,
                                            max: 100,
                                            value: 1,
                                            onChanged: (value) => print(value),
                                        ),
                                    ),
                                ],
                                ),
                                ),
                            Container(
                            child: Row(
                                children: [
                                Expanded(
                                    child: Container(
                                        padding: EdgeInsets.only(left: 20),
                                        child: TextField(
                                            decoration: const InputDecoration(
                                                label: Text("メモ"),
                                                ),
                                            ),
                                        ),
                                    ),
                                ],
                                ),
                                ),
                                ],
                                ),

                                bottomNavigationBar: BottomNavigationBar(
                                        type: BottomNavigationBarType.fixed,
                                        items: const [
                                        BottomNavigationBarItem(
                                            icon: Icon(Icons.density_small_sharp),
                                            label: "リストアップ",
                                            ),
                                        BottomNavigationBarItem(
                                            icon: Icon(Icons.photo_camera),
                                            label: "画像登録",
                                            ),
                                        BottomNavigationBarItem(
                                            icon: Icon(Icons.add),
                                            label: "登録",
                                            ),
                                        BottomNavigationBarItem(
                                            icon: Icon(Icons.pie_chart),
                                            label: "チャート表示",
                                            ),
                                        ],
                                        ),
                                        ),
                                        );
        }
}
