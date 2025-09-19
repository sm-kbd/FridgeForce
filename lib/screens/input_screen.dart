import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:intl/intl.dart';
import 'camera_screen.dart';
import '../services/database_service.dart';
import '../services/notification.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({Key? key}) : super(key: key);

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _beforeDaysController = TextEditingController(
    text: '5',
  );
  final TextEditingController _memoController = TextEditingController();
  final categoryDropdownFieldKey = GlobalKey<FormFieldState>();

  DateTime _registrationDate = DateTime.now();
  DateTime _afterDate = DateTime.now().add(const Duration(days: 1));

  int? _selectedCategoryId;
  Color _selectedCategoryColor = const Color.fromRGBO(112, 176, 228, 1);

  List<Category> _categories = [];

  final Color _primaryColor = const Color.fromRGBO(112, 176, 228, 1);

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories = await DatabaseService.instance.getCategories();
    setState(() => _categories = categories.toList());
  }

  Future<void> _pickDate(
    BuildContext context,
    DateTime current,
    Function(DateTime) onPicked,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) onPicked(picked);
  }

  void _pickColor(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('色を選択'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _selectedCategoryColor,
            onColorChanged: (color) {
              setState(() => _selectedCategoryColor = color);
            },
          ),
        ),
        actions: [
          TextButton(
            child: const Text('閉じる'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      border: const OutlineInputBorder(),
    );
  }

  Widget _buildDatePickerRow(
    String label,
    DateTime date,
    VoidCallback onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const SizedBox(width: 30),
          Text('$label ', style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 80),
          SizedBox(
            width: 120,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                DateFormat('yyyy/MM/dd').format(date),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 30,
            height: 30,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(4),
                minimumSize: const Size(24, 24),
                backgroundColor: _primaryColor,
              ),
              child: const Icon(
                Icons.calendar_today,
                size: 17,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Category> _getFilteredCategories(String query) {
    if (query.isEmpty) return _categories;
    return _categories.where((cat) => cat.name.contains(query)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('入力画面')),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                Center(
                  child: SizedBox(
                    height: 50, // 高さを固定
                    width: 300,
                    child: TextFormField(
                      controller: _itemController,
                      decoration: InputDecoration(
                        hintText: '品目名',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 18,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),
                const Divider(
                  height: 20,
                  thickness: 1,
                  color: Color.fromARGB(255, 164, 164, 164),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        key: categoryDropdownFieldKey,
                        value: _selectedCategoryId,
                        hint: const Text('カテゴリーを選択'),
                        items: [
                          // Existing categories
                          ..._categories.map(
                            (cat) => DropdownMenuItem<int>(
                              value: cat.id as int,
                              child: Text(cat.name),
                            ),
                          ),
                          // "+ create new" item
                          const DropdownMenuItem<int>(
                            value: -1,
                            child: Text('+ 新しいカテゴリーを作成'),
                          ),
                        ],
                        onChanged: (selectedId) async {
                          if (selectedId == -1) {
                            categoryDropdownFieldKey.currentState?.reset();
                            Color newCategoryColor = const Color.fromARGB(
                              255,
                              112,
                              176,
                              228,
                            );
                            final result = await showDialog(
                              context: context,
                              builder: (context) {
                                final TextEditingController
                                newCategoryController = TextEditingController();
                                return StatefulBuilder(
                                  builder: (context, setState) {
                                    return AlertDialog(
                                      title: const Text('新しいカテゴリーを作成'),
                                      content: Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: newCategoryController,
                                              decoration: const InputDecoration(
                                                hintText: 'カテゴリー名',
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          GestureDetector(
                                            onTap: () async {
                                              await showDialog(
                                                context: context,
                                                builder: (context) {
                                                  return AlertDialog(
                                                    title: const Text('色を選択'),
                                                    content: SingleChildScrollView(
                                                      child: ColorPicker(
                                                        pickerColor:
                                                            newCategoryColor,
                                                        onColorChanged:
                                                            (
                                                              color,
                                                            ) => (setState(
                                                              () =>
                                                                  newCategoryColor =
                                                                      color,
                                                            )),
                                                      ),
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.of(
                                                              context,
                                                            ).pop(),
                                                        child: const Text('OK'),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            },
                                            child: Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: newCategoryColor,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.grey.shade400,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop(null);
                                          },
                                          child: const Text('キャンセル'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () async {
                                            String name = newCategoryController
                                                .text
                                                .trim();
                                            if (name.isEmpty) return;
                                            Navigator.of(context).pop({
                                              "name": name,
                                              "color": newCategoryColor.value,
                                            });
                                          },
                                          child: const Text('作成'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            );
                            if (result != null) {
                              print(result);
                              final name = result["name"];
                              final color = result["color"];
                              final newId = await DatabaseService.instance
                                  .addCategory(name, color);

                              setState(() {
                                _categories.add(
                                  Category(id: newId, name: name, color: color),
                                );
                                _selectedCategoryId = newId;
                                _selectedCategoryColor = Color(
                                  _categories
                                      .firstWhere((c) => c.id == newId)
                                      .color,
                                );
                              });
                            }
                          } else {
                            // Selecting existing category
                            setState(() {
                              _selectedCategoryId = selectedId;
                              _selectedCategoryColor = Color(
                                _categories
                                    .firstWhere((c) => c.id == selectedId!)
                                    .color,
                              );
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () => _pickColor(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _selectedCategoryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(
                  height: 20,
                  thickness: 1,
                  color: Color.fromARGB(255, 164, 164, 164),
                ),
                const SizedBox(height: 12),
                _buildDatePickerRow(
                  '登録日　',
                  _registrationDate,
                  () => _pickDate(context, _registrationDate, (picked) {
                    setState(() => _registrationDate = picked);
                  }),
                ),
                const SizedBox(height: 12),
                _buildDatePickerRow(
                  '消費期限',
                  _afterDate,
                  () => _pickDate(context, _afterDate, (picked) {
                    setState(() => _afterDate = picked);
                  }),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const SizedBox(width: 30),
                    const Text('通知'),
                    const SizedBox(width: 190),
                    SizedBox(
                      width: 50,
                      height: 40,
                      child: TextFormField(
                        controller: _beforeDaysController,
                        decoration: _inputDecoration(''),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('日前'),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(
                  height: 25,
                  thickness: 1,
                  color: Color.fromARGB(255, 164, 164, 164),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _memoController,
                  decoration: _inputDecoration('メモ'),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                // 保存ボタン
                Center(
                  child: SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: () async {
                        int daysBefore =
                            int.tryParse(_beforeDaysController.text) ?? 1;

                        if (_selectedCategoryId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('カテゴリーを選択してください')),
                          );
                          return;
                        }

                        if (_afterDate.isBefore(_registrationDate) ||
                            (_afterDate.year == _registrationDate.year &&
                                _afterDate.month == _registrationDate.month &&
                                _afterDate.day == _registrationDate.day)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("消費期限は購入日より前に設定できません"),
                            ),
                          );
                          return;
                        }

                        await DatabaseService.instance.addFridgeItem(
                          productName: _itemController.text,
                          categoryId: _selectedCategoryId!,
                          creationDate: _registrationDate,
                          expiryDate: _afterDate,
                          daysBefore: daysBefore,
                          memo: _memoController.text,
                        );

                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(const SnackBar(content: Text('保存しました')));
                        NotificationService().scheduleNotification(
                          id: DateTime.now().millisecondsSinceEpoch.remainder(
                            2147483647,
                          ),
                          title: "食品の賞味期限が近づいています",
                          body: "${_itemController.text}の賞味期限が近づいています",
                          daysLater: _afterDate
                              .subtract(Duration(days: daysBefore))
                              .difference(DateTime.now())
                              .inDays,
                          payload: "idk",
                        );
                        NotificationService().showNotification(
                          id: DateTime.now().millisecondsSinceEpoch.remainder(
                            2147483647,
                          ),
                          title: "食品の賞味期限が近づいています",
                          body: "${_itemController.text}の賞味期限が近づいています",
                          payload: "idk",
                        );
                        setState(() {
                          _itemController.clear();
                          _selectedCategoryId = null;
                          _registrationDate = DateTime.now();
                          _afterDate = DateTime.now();
                          _beforeDaysController.clear();
                          _memoController.clear();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: _primaryColor,
                      ),
                      child: const Text(
                        '保存',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // カメラボタンを上真ん中に
          // Positioned(
          //   top: 16,
          //   left: 0,
          //   right: 0,
          //   child: Center(
          //     child: ElevatedButton(
          //       onPressed: () => Navigator.push(
          //         context,
          //         MaterialPageRoute(builder: (context) => const CameraScreen()),
          //       ),
          //       style: ElevatedButton.styleFrom(
          //         shape: const CircleBorder(),
          //         backgroundColor: _primaryColor,
          //         padding: const EdgeInsets.all(16),
          //       ),
          //       child: const Icon(Icons.camera_alt, color: Colors.white),
          //     ),
          //   ),
          // ),
        ],
      ),
      floatingActionButton: ElevatedButton(
        onPressed: () async {
          final dates = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CameraScreen()),
          );
          setState(() => _afterDate = dates[0]);
        },
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          backgroundColor: _primaryColor,
          padding: const EdgeInsets.all(25),
        ),
        child: const Icon(Icons.camera_alt, color: Colors.white, size: 25),
      ),
    );
  }
}
