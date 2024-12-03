import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart'; // 引入 Provider
import 'package:blue_classic/models/wifi_model.dart'; // 导入封装的 WifiModel
import 'package:http/http.dart' as http;
import 'package:app_settings/app_settings.dart';

class WifiInfoScreen extends StatefulWidget {
  const WifiInfoScreen({super.key});

  @override
  State<StatefulWidget> createState() => _WifiInfoScreenState();
}

class _WifiInfoScreenState extends State<WifiInfoScreen> {
  String _response = "";
  final TextEditingController _messageControllerID = TextEditingController();
  final TextEditingController _messageControllerPWD = TextEditingController();
  final String serverIP = "192.168.4.1";
  bool _isObscured = true;
  // bool _correct_wifi = false;

  Future<void> sendId(String message) async {
    try {
      final url = Uri.parse("http://$serverIP/id?msg=$message");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          _response = "$_response\n${response.body}\n"; // 显示服务器的响应
        });
      } else {
        setState(() {
          _response += "错误：服务器返回状态码 ${response.statusCode} \n";
        });
      }
    } catch (e) {
      setState(() {
        _response += "错误：无法连接到服务器\n$e";
      });
    }
  }

  Future<void> sendPwd(String message) async {
    try {
      final url = Uri.parse("http://$serverIP/pwd?msg=$message");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          _response = "$_response\n${response.body}\n"; // 显示服务器的响应
        });
      } else {
        setState(() {
          _response += "错误：服务器返回状态码 ${response.statusCode} \n";
        });
      }
    } catch (e) {
      setState(() {
        _response += "错误：无法连接到服务器\n$e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => WifiModel()..startListening(),
      child: Consumer<WifiModel>(
        builder: (context, wifiModel, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('网络信息与测试'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            // 使用 GestureDetector 包裹整个页面
            body: GestureDetector(
              behavior: HitTestBehavior.translucent, // 允许在空白区域点击
              onTap: () {
                // 点击页面其他地方隐藏键盘
                FocusScope.of(context).unfocus();
              },
              child: SingleChildScrollView(
                // 加入 SingleChildScrollView 防止键盘弹出时页面溢出
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '当前网络信息:',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text('网络类型: ${wifiModel.networkType}'),
                      Text('Wi-Fi 名称: ${wifiModel.wifiName}'),
                      Text('IP 地址: ${wifiModel.wifiIP}'),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => AppSettings.openAppSettingsPanel(AppSettingsPanelType.wifi),
                        child: const Text('打开wifi设置'),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _messageControllerID,
                        decoration: const InputDecoration(
                          labelText: '输入WIFI_ID',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        obscureText: _isObscured,
                        controller: _messageControllerPWD,
                        decoration: InputDecoration(
                          labelText: '输入WIFI_PWD',
                          border: const OutlineInputBorder(),
                          suffixIcon: GestureDetector(
                            onTap: () {
                              // 长按显示密码
                              setState(() {
                                _isObscured = !_isObscured;
                              });
                            },
                            child: Icon(
                              _isObscured ? Icons.visibility : Icons.visibility_off,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          final messageId = _messageControllerID.text;
                          final messagePwd = _messageControllerPWD.text;
                          if (messageId.isNotEmpty && messagePwd.isNotEmpty) {
                            sendId(messageId); // 发送请求
                            sendPwd(messagePwd);
                          }
                        },
                        child: const Text('发送消息'),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '服务器响应:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _response,
                        style: const TextStyle(color: Colors.black),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}