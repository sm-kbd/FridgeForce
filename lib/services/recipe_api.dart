import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RecipeScreen extends StatefulWidget {
  @override
  _RecipeScreenState createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  final List<Map<String, dynamic>> _translatedItems = [];
  bool _isLoading = false;

  // Example ingredients
  final List<String> ingredients = ["たまねぎ", "にんじん", "じゃがいも"];

  Future<void> fetchTranslations() async {
    setState(() {
      _translatedItems.clear();
      _isLoading = true;
    });

    final uri = Uri.parse("http://127.0.0.1:8000/stream");
    final request = http.Request('POST', uri);
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode({"ingredients": ingredients});

    final response = await request.send();

    // Stream the response line by line
    response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          (line) {
            if (line.trim().isEmpty) return;

            final data = jsonDecode(line) as Map<String, dynamic>;
            setState(() {
              _translatedItems.add(data);
            });
          },
          onDone: () {
            setState(() {
              _isLoading = false;
            });
          },
          onError: (error) {
            print("Stream error: $error");
            setState(() {
              _isLoading = false;
            });
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Ingredient Translations")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : fetchTranslations,
              child: Text(_isLoading ? "Loading..." : "Translate Ingredients"),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _translatedItems.length,
                itemBuilder: (context, index) {
                  final item = _translatedItems[index];
                  final j = item.keys.first;
                  final e = item.values.first;
                  return ListTile(
                    leading: Text("${index + 1}"),
                    title: Text("$j → $e"),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
