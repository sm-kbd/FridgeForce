import 'package:flutter/material.dart';
import 'package:flutter_spinbox/material.dart';

void main() {
    runApp(FridgeForce());
}


class FridgeForce extends StatefulWidget {
    @override
    _FridgeForceState createState() => _FridgeForceState();
}

class _FridgeForceState extends State<FridgeForce> {
    int _currentIndex = 0;
    final _pages = [
        const Text("list"),
        const Text("input"),
        const Text("output")
    ];

    @override
        Widget build(BuildContext context) {
            return MaterialApp(
                    home: Scaffold(
                        appBar: AppBar(
                            title: const Text("FridgeForce"),
                            backgroundColor: Colors.green,
                            ),

                        body: IndexedStack(
                            index: _currentIndex,
                            children: _pages,
                            ),

                        bottomNavigationBar: BottomNavigationBar(
                            currentIndex: _currentIndex,
                            type: BottomNavigationBarType.fixed,
                            onTap: (i) => setState(() => _currentIndex = i),
                            items: [
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
