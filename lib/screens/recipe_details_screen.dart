import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

const IP_ADDRESS = "http://nekopas.local:8000/";

String recipeNameToFileName(String recipeName) {
  final hash = sha1.convert(utf8.encode(recipeName)).toString();
  return hash.substring(0, 10); // short safe filename
}

class RecipeDetailsScreen extends StatefulWidget {
  final String recipeName;
  const RecipeDetailsScreen({required this.recipeName, Key? key})
    : super(key: key);

  @override
  _RecipeDetailsScreenState createState() => _RecipeDetailsScreenState();
}

class _RecipeDetailsScreenState extends State<RecipeDetailsScreen> {
  Map<String, dynamic>? _meal;
  bool _loading = true;
  String? _error;
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _fetchMealDetails();
  }

  Future<void> _checkIfBookmarked() async {
    if (_meal == null) return;

    final name = _meal!['recipeName'];
    final fileName = recipeNameToFileName(name);

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName.json');

    setState(() {
      _isBookmarked = file.existsSync();
    });
  }

  Future<void> _fetchMealDetails() async {
    final uri = Uri.parse("${IP_ADDRESS}details/${widget.recipeName}");
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        setState(() {
          _meal = data;
          _loading = false;
        });

        // ✅ Check bookmark now that _meal is loaded
        await _checkIfBookmarked();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_meal?['recipeName'] ?? widget.recipeName),
        actions: [
          IconButton(
            icon: Icon(_isBookmarked ? Icons.bookmark : Icons.add),
            tooltip: _isBookmarked ? 'すでにブックマーク済み' : 'ブックマークに追加',
            onPressed: _isBookmarked
                ? null // ✅ Disable button if already bookmarked
                : () async {
                    if (_meal == null) return;

                    final name = _meal?['recipeName'];
                    final fileName = recipeNameToFileName(name);

                    final dir = await getApplicationDocumentsDirectory();
                    final file = File('${dir.path}/$fileName.json');

                    await file.writeAsString(jsonEncode(_meal));

                    setState(() {
                      _isBookmarked = true; // ✅ Switch icon immediately
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ブックマークに追加しました')),
                    );
                  },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // タイトル
                    Text(
                      _meal?['recipeName'] ?? "",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 説明
                    if (_meal?['description'] != null)
                      Text(
                        _meal!['description'],
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                    const SizedBox(height: 20),

                    // 調理時間
                    if (_meal?['prepTime'] != null)
                      Text(
                        "準備時間: ${_meal!['prepTime']}",
                        style: const TextStyle(fontSize: 18),
                      ),
                    if (_meal?['coolTime'] != null)
                      Text(
                        "冷却時間: ${_meal!['coolTime']}",
                        style: const TextStyle(fontSize: 18),
                      ),
                    const SizedBox(height: 24),

                    // 材料
                    const Text(
                      "材料",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    ...(_meal?['ingredients'] as List<dynamic>).map(
                      (ing) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          "・${ing['item']}：${ing['quantity']}",
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
                      _meal?['instructions'] ?? "",
                      style: const TextStyle(fontSize: 16, height: 1.6),
                    ),
                    const SizedBox(height: 24),

                    // 足りない食材リンク（デモ）
                    const Text(
                      "足りない食材を購入",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      "デモリンク",
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                        fontSize: 20,
                      ),
                    ),
                    const Text(
                      "デモリンク",
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                        fontSize: 20,
                      ),
                    ),
                    const Text(
                      "デモリンク",
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                        fontSize: 20,
                      ),
                    ),
                    const Text(
                      "デモリンク",
                      style: TextStyle(
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
