import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'saved_recipe_details_screen.dart';

class SavedRecipeScreen extends StatefulWidget {
  const SavedRecipeScreen({Key? key}) : super(key: key);

  @override
  _SavedRecipeScreenState createState() => _SavedRecipeScreenState();
}

class _SavedRecipeScreenState extends State<SavedRecipeScreen> {
  List<Map<String, String>> _savedRecipes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadJson();
  }

  void _loadJson() async {
    _savedRecipes = await _loadSavedRecipes();
    setState(() {});
    _loading = false;
  }

  Future<List<Map<String, String>>> _loadSavedRecipes() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/saved.json');

    if (!await file.exists()) {
      return [];
    }

    final raw = await file.readAsString();

    if (raw.trim().isEmpty) {
      return [];
    }

    try {
      final decoded = json.decode(raw);

      if (decoded is List) {
        return decoded.whereType<Map<String, String>>().toList();
      } else {
        return [];
      }
    } catch (e) {
      print("JSON parse error: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ブックマーク一覧")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: _savedRecipes.isEmpty
                  ? Center(child: Text("保存されたレシピはありません"))
                  : ListView.builder(
                      itemCount: _savedRecipes.length,
                      itemBuilder: (context, index) {
                        final item = _savedRecipes[index];
                        final name = item['name'] ?? 'Unknown';
                        final description = item['description'] ?? '';
                        final imageUrl = '';

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
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      SavedRecipeDetailsScreen(
                                        recipeName: name,
                                      ),
                                ),
                              );
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
