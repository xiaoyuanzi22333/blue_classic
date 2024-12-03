import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter to ESP32',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SendMessageScreen(),
    );
  }
}

class SendMessageScreen extends StatefulWidget {
  @override
  _SendMessageScreenState createState() => _SendMessageScreenState();
}

class _SendMessageScreenState extends State<SendMessageScreen> {
  final TextEditingController _messageController = TextEditingController();
  String _response = "";

  // ESP32 服务器的 IP 地址
  final String serverIP = "192.168.4.1"; // 替换为你的 ESP32 的 IP 地址
  final int serverPort = 80; // 服务器端口号（默认是 80）

  // 发送消息到 ESP32 的服务器
  Future<void> sendMessage(String message) async {
    try {
      final url = Uri.parse("http://$serverIP:$serverPort/message?message=$message");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          _response = response.body; // 显示服务器的响应
        });
      } else {
        setState(() {
          _response = "错误：服务器返回状态码 ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _response = "错误：无法连接到服务器\n$e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('向 ESP32 发送消息'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _messageController,
              decoration: InputDecoration(
                labelText: '输入消息',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final message = _messageController.text;
                if (message.isNotEmpty) {
                  sendMessage(message); // 发送请求
                }
              },
              child: Text('发送消息'),
            ),
            SizedBox(height: 16),
            Text(
              '服务器响应:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              _response,
              style: TextStyle(color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}