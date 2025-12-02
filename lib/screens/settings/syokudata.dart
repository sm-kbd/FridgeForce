import 'package:flutter/material.dart';
import '../../services/database_service.dart'; // DatabaseService をインポート

class SyokudataPage extends StatelessWidget {
  const SyokudataPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MyHomePage();
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final DatabaseService _databaseService = DatabaseService.instance;
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _dayController = TextEditingController();

  List<Map<String, dynamic>> _savedItems = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final items = await _databaseService.getAllDefaultExpDates();
    setState(() {
      _savedItems = List<Map<String, dynamic>>.from(items);
    });
  }

  Future<void> _addItem() async {
    final name = _textController.text.trim();
    final dayText = _dayController.text.trim();
    if (name.isEmpty || dayText.isEmpty) return;

    final days = int.tryParse(dayText) ?? 0;
    await _databaseService.addDefaultExpDates(name, days);

    setState(() {
      _savedItems = List<Map<String, dynamic>>.from(_savedItems)
        ..add({
          'name': name,
          'days': days,
          'id': DateTime.now().millisecondsSinceEpoch,
        });
      _textController.clear();
      _dayController.clear();
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('保存しました')));
  }

  Future<void> _deleteItem(String name) async {
    await _databaseService.deleteDefaultExpDate(name);
    setState(() {
      _savedItems = List<Map<String, dynamic>>.from(_savedItems)
        ..removeWhere((item) => item['name'] == name);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("消費期限デフォルト設定"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: "商品名",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _dayController,
              decoration: const InputDecoration(
                labelText: "日数",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            Container(
              margin: const EdgeInsets.only(left: 250),
              width: 100,
              child: ElevatedButton.icon(
                onPressed: _addItem,
                label: const Text("保存"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 90, 148, 83),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Divider(),
            Expanded(
              child: _savedItems.isEmpty
                  ? const Center(child: Text("保存したアイテムはありません"))
                  : ListView.builder(
                      itemCount: _savedItems.length,
                      itemBuilder: (context, index) {
                        final item = _savedItems[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            title: Text(item['name']),
                            subtitle: Text("${item['days']}日"),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Color.fromARGB(255, 54, 54, 54),
                              ),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text("削除の確認"),
                                    content: Text(
                                      "「${item['name']}」を削除しますか？",
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text("キャンセル"),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text(
                                          "削除",
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  _deleteItem(item['name']);
                                }
                              },
                            ),
                          ),
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
