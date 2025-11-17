import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const IP_ADDRESS = "http://nekopas.local:8000/";

class RecipeDetailsScreen extends StatefulWidget {
  final String idMeal;
  const RecipeDetailsScreen({required this.idMeal, Key? key}) : super(key: key);

  @override
  _RecipeDetailsScreenState createState() => _RecipeDetailsScreenState();
}

class _RecipeDetailsScreenState extends State<RecipeDetailsScreen> {
  Map<String, dynamic>? _meal;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchMealDetails();
  }

  Future<void> _fetchMealDetails() async {
    final uri = Uri.parse("${IP_ADDRESS}details/${widget.idMeal}");
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        setState(() {
          _meal = data;
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
          _error = "レシピの取得に失敗しました (コード: ${response.statusCode})";
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = "エラーが発生しました: $e";
      });
    }
  }

  List<String> _getIngredients(Map<String, dynamic> meal) {
    final List<String> ingredients = [];
    for (int i = 1; i <= 20; i++) {
      final ingredient = meal['strIngredient$i'];
      final measure = meal['strMeasure$i'];
      if (ingredient != null &&
          ingredient is String &&
          ingredient.isNotEmpty &&
          measure != null &&
          measure is String &&
          measure.isNotEmpty) {
        ingredients.add("$ingredient - $measure");
      }
    }
    return ingredients;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_meal?['strMeal'] ?? "レシピ詳細")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : SafeArea(
              // ✅ prevents overlap with phone bottom buttons
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 料理画像
                    if (_meal?['strMealThumb'] != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _meal!['strMealThumb'],
                          width: double.infinity,
                          height: 220,
                          fit: BoxFit.cover,
                        ),
                      ),
                    const SizedBox(height: 20),

                    // タイトル
                    Text(
                      _meal?['strMeal'] ?? "",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 材料
                    const Text(
                      "材料",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._getIngredients(_meal!).map(
                      (ing) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          "・$ing",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 作り方
                    const Text(
                      "作り方",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _meal?['strInstructions'] ?? "",
                      style: const TextStyle(fontSize: 16, height: 1.6),
                    ),
                    const SizedBox(height: 24),

                    // 作り方
                    const Text(
                      "足りない食材を購入",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      "デモリンク",
                      style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                        fontSize: 20,
                      ),
                    ),
                    const Text(
                      "デモリンク",
                      style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                        fontSize: 20,
                      ),
                    ),
                    const Text(
                      "デモリンク",
                      style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                        fontSize: 20,
                      ),
                    ),
                    const Text(
                      "デモリンク",
                      style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
