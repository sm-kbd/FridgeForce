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

                        bottomNavigationBar: BottomNavigationBar(
                            type: BottomNavigationBarType.fixed,
                            items: const [
                            BottomNavigationBarItem(
                                icon: Icon(Icons.density_small_sharp),
                                label: "リストアップ",
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
