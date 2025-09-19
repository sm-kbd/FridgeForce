import 'package:flutter/material.dart';

import '../services/database_service.dart';
import 'home_screen.dart';
import 'input_screen.dart';
import 'recipe_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  static List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    InputScreen(),
    RecipeScreen(ingredients: []),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: _widgetOptions.elementAt(_currentIndex)),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.density_small_sharp),
            label: 'リストアップ',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: '登録'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'レシピ提案'),
        ],
        currentIndex: _currentIndex,

        selectedItemColor: const Color.fromARGB(255, 81, 96, 92),
        onTap: (idx) => setState(() => _currentIndex = idx),
      ),
    );
  }
}
