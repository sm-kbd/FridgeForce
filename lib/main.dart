import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'tab/main_view.dart';
import 'tab/input_view.dart';
import 'tab/chart_view.dart';
import 'database.dart';

void main() {
    // Initialize FFI
    sqfliteFfiInit();

    // Set the global factory
    databaseFactory = databaseFactoryFfi;
    runApp(const FridgeForceApp());
}


class FridgeForceApp extends StatelessWidget {
    const FridgeForceApp({super.key});

    @override
        Widget build(BuildContext context) {
            return const MaterialApp(home: FridgeForce());
        }
}

class FridgeForce extends StatefulWidget {
    const FridgeForce({super.key});

    @override
        State<FridgeForce> createState() => _FridgeForceState();
}

class _FridgeForceState extends State<FridgeForce> {
    int _currentIndex = 0;
    static const List<Widget> _widgetOptions = <Widget>[
        MainView(),
        InputView(),
        ChartsView(),
    ];

    void _onItemTapped(int index) {
        setState(() {
                _currentIndex = index;
                });
    }

    @override
        Widget build(BuildContext context) {
            return Scaffold(
                    body: Center(child: _widgetOptions.elementAt(_currentIndex)),
                    bottomNavigationBar: BottomNavigationBar(
                        type: BottomNavigationBarType.fixed,  
                        items: const <BottomNavigationBarItem>[
                        BottomNavigationBarItem(icon: Icon(Icons.density_small_sharp), label: 'リストアップ'),
                        BottomNavigationBarItem(icon: Icon(Icons.add), label: '登録'),
                        BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'レシピ提案'),
                        ],
                        currentIndex: _currentIndex,

                        selectedItemColor: const Color.fromARGB(255, 81, 96, 92),
                        onTap: (itemId) => setState(() => _currentIndex = itemId),
                        ),
                    );
        }
}
