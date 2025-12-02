import 'dart:core';
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
  bool _loading = true;
  List<Map<String, String>> _savedRecipes = [];
  Set<int> _selectedIndexes = {};

  @override
  void initState() {
    super.initState();
    _loadJson();
  }

  void _loadJson() async {
    await _loadSavedRecipes();
    setState(() {});
    _loading = false;
  }

  Future<void> _loadSavedRecipes() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final files = dir.listSync();

      final List<Map<String, String>> loaded = [];

      for (final file in files) {
        if (file is File && file.path.endsWith('.json')) {
          final content = await file.readAsString();
          final data = jsonDecode(content);

          loaded.add({
            'name': data['recipeName'] ?? 'Unknown',
            'description': data['description'] ?? '',
            'path': file.path,
          });
        }
      }

      setState(() {
        _savedRecipes = loaded;
        _loading = false;
        _selectedIndexes.clear();
      });
    } catch (e) {
      print("Error loading bookmarks: $e");
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteSelectedBookmarks() async {
    if (_selectedIndexes.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('削除確認'),
          content: const Text('選択したブックマークを削除してもよろしいですか？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('削除', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    // If user canceled, do nothing
    if (confirm != true) return;

    // Sort in reverse to avoid index shift when removing
    final indexes = _selectedIndexes.toList()..sort((a, b) => b.compareTo(a));

    for (final index in indexes) {
      final path = _savedRecipes[index]['path'];
      final file = File(path!);
      if (await file.exists()) {
        await file.delete();
      }
      _savedRecipes.removeAt(index);
    }

    setState(() {
      _selectedIndexes.clear();
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("選択したブックマークを削除しました")));
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ブックマーク一覧"),
        actions: _selectedIndexes.isEmpty
            ? []
            : [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _deleteSelectedBookmarks,
                ),
              ],
      ),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: _savedRecipes.isEmpty
                  ? const Center(child: Text("保存されたレシピはありません"))
                  : ListView.builder(
                      itemCount: _savedRecipes.length,
                      itemBuilder: (context, index) {
                        final item = _savedRecipes[index];
                        final name = item['name'] ?? 'Unknown';
                        final description = item['description'] ?? '';
                        final imageUrl = '';
                        final isSelected = _selectedIndexes.contains(index);

                        return Card(
                          color: isSelected
                              ? Colors.blue.withOpacity(0.15)
                              : null,
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

                            onLongPress: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedIndexes.remove(index);
                                } else {
                                  _selectedIndexes.add(index);
                                }
                              });
                            },

                            onTap: () async {
                              if (_selectedIndexes.isNotEmpty) {
                                setState(() {
                                  if (isSelected) {
                                    _selectedIndexes.remove(index);
                                  } else {
                                    _selectedIndexes.add(index);
                                  }
                                });
                                return;
                              }

                              final path = item['path'] as String?;
                              if (path == null) return; // skip if null

                              final filename = path
                                  .split('/')
                                  .last
                                  .replaceAll('.json', '');
                              final deleted = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      SavedRecipeDetailsScreen(
                                        filename: filename,
                                      ),
                                ),
                              );
                              if (deleted == true) {
                                setState(() {
                                  _savedRecipes.removeAt(index);
                                  _selectedIndexes.remove(index);
                                });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('ブックマークを削除しました')),
                              );
                              }
                            },

                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (isSelected)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 6),
                                      child: Icon(
                                        Icons.check_circle,
                                        color: Colors.blue,
                                      ),
                                    ),

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
