import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'recipe_details_screen.dart';

const IP_ADDRESS = "http://nekopas.local:8000/";

class RecipeScreen extends StatefulWidget {
  final List<String> ingredients;
  const RecipeScreen({required List<String> this.ingredients, Key? key})
    : super(key: key);

  @override
  _RecipeScreenState createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  List<Map<String, String>> _meals = [];
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
        final data = jsonDecode(body);
        setState(() {
          _meals = (data as List)
              .map((item) => Map<String, String>.from(item))
              .toList();
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
                      itemCount: _meals.length,
                      itemBuilder: (context, index) {
                        final item = _meals[index];
                        final name = item['name'] ?? 'Unknown';
                        final description = item['description'] ?? '';
                        final imageUrl = IP_ADDRESS + "thumbs/" + name;

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 12.0,
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              // Optional: Navigate to details
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: imageUrl.isNotEmpty
                                        ? Image.network(
                                            imageUrl,
                                            width: 90,
                                            height: 90,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            width: 90,
                                            height: 90,
                                            color: Colors.grey[300],
                                            child: const Icon(
                                              Icons.fastfood,
                                              size: 40,
                                            ),
                                          ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          description,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.black54,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        const Text(
                                          "タップして詳細を見る",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.blueGrey,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
