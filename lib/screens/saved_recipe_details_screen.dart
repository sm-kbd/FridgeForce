import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class SavedRecipeDetailsScreen extends StatefulWidget {
  final String filename; // ✅ now we pass filename directly

  const SavedRecipeDetailsScreen({required this.filename, Key? key})
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

  Future<void> _getRecipeDetails() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File("${dir.path}/${widget.filename}.json");

      if (!await file.exists()) {
        throw Exception("ファイルが存在しません");
      }

      final raw = await file.readAsString();
      final data = json.decode(raw);

      setState(() {
        _recipe = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "レシピの読み込みに失敗しました";
        _loading = false;
      });
    }
  }

  Future<void> _confirmAndDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('削除確認'),
          content: const Text('このブックマークを削除してもよろしいですか？'),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(false), // closes dialog
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // closes dialog
              child: const Text('削除', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm != true) return; // user canceled

    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File("${dir.path}/${widget.filename}.json");
      if (await file.exists()) {
        await file.delete();
      }

      // ✅ Now pop the **screen** with true to notify previous screen
      Navigator.of(context).pop(true);

      // optional snackbar
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ブックマークを削除しました')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('削除に失敗しました')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_recipe?['recipeName'] ?? "レシピ詳細"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'ブックマークを削除',
            onPressed: _recipe == null ? null : _confirmAndDelete,
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
                    // ✅ タイトル
                    Text(
                      _recipe?['recipeName'] ?? "",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ✅ 説明
                    if (_recipe?['description'] != null)
                      Text(
                        _recipe!['description'],
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                    const SizedBox(height: 20),

                    // ✅ 調理時間
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

                    // ✅ 材料
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

                    // ✅ 作り方
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

                    // ✅ デモリンク
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
