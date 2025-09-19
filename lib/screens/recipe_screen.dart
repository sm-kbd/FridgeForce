import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'recipe_details_screen.dart';

const IP_ADDRESS = "http://192.168.29.57:8000/";

class RecipeScreen extends StatefulWidget {
  final List<String> ingredients;
  const RecipeScreen({required List<String> this.ingredients, Key? key})
    : super(key: key);

  @override
  _RecipeScreenState createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  List<Map<String, dynamic>> _meals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchMeals();
  }

  Future<void> _fetchMeals() async {
    if (widget.ingredients.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    final uri = Uri.parse("${IP_ADDRESS}overview");
    final request = http.Request('POST', uri);
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode({"ingredients": widget.ingredients}); // ← 仮入力

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final body = await response.stream.bytesToString();
        final List<dynamic> data = jsonDecode(body);
        setState(() {
          _meals = data.cast<Map<String, dynamic>>();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
      debugPrint("レシピ取得エラー: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("レシピ一覧")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: widget.ingredients.isEmpty
                  ? Center(child: Text("保存されたレシピはありません"))
                  : _meals.isEmpty
                  ? Center(child: Text("該当する料理は見つかりませんでした"))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _meals.length,
                      itemBuilder: (context, index) {
                        final meal = _meals[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RecipeDetailsScreen(
                                    idMeal: meal['idMeal'].toString(),
                                  ),
                                ),
                              );
                            },
                            child: Row(
                              children: [
                                Hero(
                                  tag: meal['idMeal'],
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      bottomLeft: Radius.circular(16),
                                    ),
                                    child: Image.network(
                                      meal['strMealThumb'],
                                      width: 120,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 4,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          meal['strMeal'],
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: const [
                                            Icon(Icons.touch_app, size: 14),
                                            SizedBox(width: 4),
                                            Text(
                                              "タップして詳細を見る",
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
