import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<StatefulWidget> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final contentController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('お問い合わせ'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context); // 前の画面に戻る
            },
          ),
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Column(
              children: <Widget>[
                Container(
                  margin: const EdgeInsets.only(
                    top: 20,
                    left: 20,
                    right: 20,
                    bottom: 10,
                  ),
                ),
                _buildLabel('お名前'),
                _buildTextField(
                  controller: nameController,
                  hintText: 'お名前',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "お名前は必須です。";
                    }
                    return null;
                  },
                ),
                _buildLabel('Email'),
                _buildTextField(
                  controller: emailController,
                  hintText: 'Email',
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty ||
                        !RegExp(
                          r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
                        ).hasMatch(value)) {
                      return "emailは必須かつemailの形式で入力してください。";
                    }
                    return null;
                  },
                ),
                _buildLabel('お問合せ内容'),
                _buildTextField(
                  controller: contentController,
                  hintText: 'お問い合わせ内容',
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.isEmpty || value.length > 10) {
                      return "お問合せ内容は必須かつ1文字以上10文字以下で入力してください。";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 40,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 204, 204, 204),
                    ),
                    onPressed: () async {
                      FocusScope.of(context).unfocus();

                      if (_formKey.currentState!.validate()) {
                        String url =
                            "https://script.google.com/macros/s/AKfycbzplbVm9kZgSakiD6UsSU6SU2HUFCHLbhdM8vtQveppyAxSgpznZFSHraunAeph6UR7cQ/exec";
                        final client = http.Client();

                        http.Response response = await client.post(
                          Uri.parse(url),
                          headers: <String, String>{
                            'Content-Type': 'application/x-www-form-urlencoded',
                          },
                          body: {
                            "name": nameController.text,
                            "email": emailController.text,
                            "body": contentController.text,
                          },
                        );

                        if (response.statusCode == 302) {
                          String redirecturl = response.headers['location']!;
                          var res = await client.get(Uri.parse(redirecturl));
                          var data = jsonDecode(res.body);
                          showAlertDialog(context, "", data["message"]);
                          client.close();
                        }
                      }
                    },
                    child: const Text(
                      "送信",
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ラベルを作る共通メソッド
  Widget _buildLabel(String text) {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 5),
      alignment: Alignment.centerLeft,
      child: Text(text, style: const TextStyle(fontSize: 16)),
    );
  }

  // TextField を作る共通メソッド
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          hintText: hintText,
          filled: true,
          fillColor: const Color.fromARGB(255, 240, 240, 240),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

// アラートダイアログ
void showAlertDialog(BuildContext context, String title, String message) {
  Widget okButton = TextButton(
    child: const Text("OK"),
    onPressed: () {
      Navigator.of(context).pop();
    },
  );

  AlertDialog alert = AlertDialog(
    title: Text(title),
    content: Text(message),
    actions: [okButton],
  );

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}
