import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

String hashString(String input) {
  final bytes = utf8.encode(input);
  final hash = sha256.convert(bytes);
  return hash.toString();
}

class SavedRecipeDetailsScreen extends StatefulWidget {
  final String recipeName;
  const SavedRecipeDetailsScreen({required this.recipeName, Key? key})
    : super(key: key);

  @override
  _SavedRecipeDetailsScreenState createState() =>
      _SavedRecipeDetailsScreenState();
}

class _SavedRecipeDetailsScreenState extends State<SavedRecipeDetailsScreen> {
  Map<String, dynamic>? _recipe;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _getRecipeDetails();
  }

  void _getRecipeDetails() async {
    // no checks because if a recipe exists in saved.json but not as a file,
    // the user did something stupid
    final hashedFilename = hashString(widget.recipeName);
    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/$hashedFilename.json");
    final raw = await file.readAsString();
    _recipe = json.decode(raw);
    _loading = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_recipe?['recipeName'] ?? widget.recipeName)),
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
                      _recipe?['recipeName'] ?? "",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 説明
                    if (_recipe?['description'] != null)
                      Text(
                        _recipe!['description'],
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                    const SizedBox(height: 20),

                    // 調理時間
                    if (_recipe?['prepTime'] != null)
                      Text(
                        "準備時間: ${_recipe!['prepTime']}",
                        style: const TextStyle(fontSize: 18),
                      ),
                    if (_recipe?['coolTime'] != null)
                      Text(
                        "冷却時間: ${_recipe!['coolTime']}",
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

                    ...(_recipe?['ingredients'] as List<dynamic>).map(
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
                      _recipe?['instructions'] ?? "",
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
