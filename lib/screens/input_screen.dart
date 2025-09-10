import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:intl/intl.dart';
import 'camera_screen.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({Key? key}) : super(key: key);

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _beforeDaysController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();

  DateTime _registrationDate = DateTime.now();
  DateTime _afterDate = DateTime.now();

  String? _selectedCategory;

  final Map<String, Color> _categoryColors = {
    'カテゴリー1': const Color.fromRGBO(112, 176, 228, 1),
    'カテゴリー2': const Color.fromRGBO(180, 112, 228, 1),
    'カテゴリー3': const Color.fromRGBO(228, 176, 112, 1),
  };

  final Color _primaryColor = const Color.fromRGBO(112, 176, 228, 1);

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
    if (picked != null) {
      onPicked(picked);
    }
  }

  void _pickColor(BuildContext context) {
    if (_selectedCategory == null) return;
    Color currentColor = _categoryColors[_selectedCategory!] ?? _primaryColor;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('色を選択'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: currentColor,
            onColorChanged: (color) {
              setState(() => _categoryColors[_selectedCategory!] = color);
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
    return Row(
      children: [
        Expanded(
          child: InputDecorator(
            decoration: _inputDecoration(label),
            child: Text(DateFormat('yyyy/MM/dd').format(date)),
          ),
        ),
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(12),
            backgroundColor: _primaryColor,
          ),
          child: const Icon(Icons.calendar_today, color: Colors.white),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('入力画面'), backgroundColor: _primaryColor),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _itemController,
              decoration: _inputDecoration('品目名'),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Autocomplete<String>(
                    fieldViewBuilder:
                        (context, controller, focusNode, onEditingComplete) {
                          _categoryController.text = controller.text;
                          return TextFormField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: _inputDecoration('カテゴリー'),
                            onEditingComplete: onEditingComplete,
                            onChanged: (val) {
                              setState(() => _selectedCategory = val);
                            },
                          );
                        },
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text == '') {
                        return const Iterable<String>.empty();
                      }
                      return _categoryColors.keys.where((String option) {
                        return option.contains(textEditingValue.text);
                      });
                    },
                    onSelected: (String selection) {
                      setState(() => _selectedCategory = selection);
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
                      color: _selectedCategory != null
                          ? _categoryColors[_selectedCategory!] ?? _primaryColor
                          : Colors.grey.shade300,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            _buildDatePickerRow(
              '登録日',
              _registrationDate,
              () => _pickDate(context, _registrationDate, (picked) {
                setState(() => _registrationDate = picked);
              }),
            ),
            const SizedBox(height: 16),

            _buildDatePickerRow(
              'X日後',
              _afterDate,
              () => _pickDate(context, _afterDate, (picked) {
                setState(() => _afterDate = picked);
              }),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
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
            const SizedBox(height: 24),

            TextFormField(
              controller: _memoController,
              decoration: _inputDecoration('メモ'),
              maxLines: 4,
            ),
            const SizedBox(height: 24),

            Center(
              child: SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('保存しました')));
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CameraScreen()),
        ),
        backgroundColor: _primaryColor,
        child: const Icon(Icons.camera_alt, color: Colors.white),
      ),
    );
  }
}
