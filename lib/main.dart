import 'package:flutter/material.dart';
import 'tab/page1.dart';
import 'tab/page2.dart';
import 'tab/page3.dart';

void main() => runApp(const BottomNavigationBarExampleApp());

class BottomNavigationBarExampleApp extends StatelessWidget {
  const BottomNavigationBarExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: BottomNavigationBarExample());
  }
}

class BottomNavigationBarExample extends StatefulWidget {
  const BottomNavigationBarExample({super.key});

  @override
  State<BottomNavigationBarExample> createState() => _BottomNavigationBarExampleState();
}

class _BottomNavigationBarExampleState extends State<BottomNavigationBarExample> {
  int _selectedIndex = 0;
  static const List<Widget> _widgetOptions = <Widget>[
    Page1(),
    Page2(),
    Page3(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,  
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.density_small_sharp), label: 'リストアップ'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: '登録'),
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: 'チャート表示'),
        ],
        currentIndex: _selectedIndex,
        
        selectedItemColor: const Color.fromARGB(255, 81, 96, 92),
        onTap: _onItemTapped,
      ),
    );
  }
}