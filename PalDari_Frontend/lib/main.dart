import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key}); // const 생성자 추가

  // Spring Boot 서버 테스트 함수
  Future<void> testBackend() async {
    final url = Uri.parse('http://10.0.2.2:8080/hello'); // Android 에뮬레이터에서 로컬 서버 접근
    final response = await http.get(url);

    if (response.statusCode == 200) {
      print(response.body); // 콘솔에 Hello World 출력
    } else {
      print('Error: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Spring Boot Test')),
        body: Center(
          child: ElevatedButton(
            onPressed: testBackend,       // 버튼 누르면 서버 호출
            child: const Text('Test Backend'),
          ),
        ),
      ),
    );
  }
}

