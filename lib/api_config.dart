import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

// Base URL ของ API ที่รันอยู่บนเครื่อง (backend server)
// - Android Emulator: 'localhost' หมายถึงตัวอีมูเลเตอร์เอง ไม่ใช่เครื่อง PC
//   จึงต้องใช้ 10.0.2.2 ซึ่งอีมูเลเตอร์แม็ปไว้ให้ชี้กลับไปที่ host
// - iOS Simulator / Web / Desktop: ใช้ localhost ได้ตามปกติ
// - อุปกรณ์จริง (มือถือจริง): ต้องเปลี่ยนเป็น IP ของเครื่อง PC ในวง LAN เช่น 192.168.x.x
String get apiBase {
  if (!kIsWeb && Platform.isAndroid) {
    return 'http://localhost:3000/api';
  }
  return 'http://localhost:3000/api';
}

// เก็บ token ไว้ใช้งานหลัง login สำเร็จ (ตัวอย่างแบบง่ายเพื่อการสอน
// ในโปรเจกต์จริงควรเก็บลง secure storage แทนตัวแปร in-memory)
class AuthSession {
  AuthSession._();

  static String? token;

  static Map<String, String> get authHeaders => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };
}