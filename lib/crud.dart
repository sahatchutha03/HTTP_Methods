import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_lad04/api_config.dart';
import 'package:http/http.dart' as http;

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  static const routeName = '/Admin';

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  List<dynamic> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData(); // เปลี่ยนมาเรียกใช้ฟังก์ชันจัดการหน้าจอแทน
  }

  // 💡 สร้างฟังก์ชันใหม่สำหรับจัดการ UI โดยเฉพาะ
  Future<void> _loadData() async {
    try {
      final data = await getUsers();

      setState(() {
        _users = data; // เอาข้อมูลไปใส่ใน List
        _isLoading = false; // สั่งปิดหลอดโหลด
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('เกิดข้อผิดพลาด: $e');
    }
  }

  Future<List<dynamic>> getUsers() async {
    final res = await http
        .get(Uri.parse('$apiBase/users'))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as List<dynamic>;
    }
    throw Exception('โหลดผู้ใช้ไม่สำเร็จ(${res.statusCode})');
  }

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  Future<Map<String, dynamic>> addUser(String name, String email) async {
    final res = await http.post(
      Uri.parse('$apiBase/users'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email}),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('สร้างไม่สำเร็จ (${res.statusCode})');
  }

  void _showAddUserDialog() {
    // ล้างค่าเก่าทิ้งก่อนเปิดฟอร์ม
    _nameController.clear();
    _emailController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('เพิ่มผู้ใช้ใหม่'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'ชื่อ (name)'),
                    validator: (val) => val!.isEmpty ? 'กรุณากรอกชื่อ' : null,
                  ),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'อีเมล (Email)',
                    ),
                    validator: (val) => val!.isEmpty ? 'กรุณากรอกอีเมล' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // ปิดหน้าต่าง
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  try {
                    // 1. เรียกฟังก์ชัน
                    await addUser(_nameController.text, _emailController.text);

                    // 2. ถ้าข้างบนทำงานผ่าน (ไม่เจอ throw Exception) ค่อยปิดหน้าต่าง
                    if (context.mounted) Navigator.pop(context);

                    // 3. สั่งโหลดรายชื่อใหม่เพื่อรีเฟรชหน้าจอ (ถ้าคุณใช้ชื่อฟังก์ชัน _loadData ก็แก้ให้ตรงกันนะ)
                    final freshData = await getUsers();
                    setState(() {
                      _users = freshData;
                    });
                  } catch (e) {
                    print('Error: $e');
                  }
                }
              },
              child: const Text('บันทึก'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> updateUser(String id, String name, String email) async {
    try {
      final res = await http.put(
        Uri.parse('$apiBase/users/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email}),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        return true; // สำเร็จ
      } else {
        debugPrint('อัปเดตไม่สำเร็จ: ${res.statusCode} ${res.body}');
        return false; // ไม่สำเร็จ
      }
    } catch (e) {
      debugPrint('Exception Error: $e');
      return false; // ไม่สำเร็จ (และแอปจะไม่พังด้วย)
    }
  }

  void _showEditUserDialog(Map<String, dynamic> users) {
    // 1. ดึงข้อมูลเดิมมาใส่ในช่องกรอก
    final TextEditingController editNameController = TextEditingController(
      text: users['name'],
    );
    final TextEditingController editEmailController = TextEditingController(
      text: users['email'],
    );
    final String userId = users['id'].toString();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('แก้ไขข้อมูลผู้ใช้'),
          content: Form(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: editNameController,
                  decoration: const InputDecoration(labelText: 'ชื่อ-นามสกุล'),
                ),
                TextFormField(
                  controller: editEmailController,
                  decoration: const InputDecoration(labelText: 'อีเมล'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  Navigator.pop(context);

                  bool isSuccess = await updateUser(
                    userId,
                    editNameController.text,
                    editEmailController.text,
                  );

                  if (isSuccess) {
                    final freshData = await getUsers();
                    setState(() {
                      _users = freshData;
                    });
                  }
                } catch (e) {
                  print('Error ตอนอัปเดต: $e');
                }
              },
              child: const Text('บันทึกการแก้ไข'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> deleteUser(String id) async {
    try {
      final res = await http.delete(Uri.parse('$apiBase/users/$id'));

      if (res.statusCode == 200) {
        return true; // ลบสำเร็จ
      } else {
        debugPrint('ลบไม่สำเร็จ: ${res.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Exception Error: $e');
      return false;
    }
  }

  Future<void> _confirmDelete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ยืนยันการลบ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context); // ปิดหน้าต่างยืนยันก่อน

              bool isSuccess = await deleteUser(id);

              if (isSuccess) {
                setState(() {
                  // 💡 ใช้คำสั่ง removeWhere เพื่อเตะคนที่มี id ตรงกัน ออกจาก List ของหน้าจอทันที
                  _users.removeWhere((item) => item['id'].toString() == id);
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ลบข้อมูลเรียบร้อยแล้ว')),
                );
              }
            },
            child: const Text('ลบเลย', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final res = await http.delete(Uri.parse('$apiBase/users/$id'));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.statusCode == 200 ? 'ลบสำเร็จ' : 'ลบไม่สำเร็จ'),
        ),
      );
    }
  }

  Future<List<dynamic>> searchUsers(String q, {int limit = 5}) async {
    final uri = Uri.parse(
      '$apiBase/users/search',
    ).replace(queryParameters: {'q': q, '_limit': limit.toString()});

    final res = await http.get(uri);

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as List<dynamic>;
    }
    throw Exception('ค้นหาไม่สำเร็จ (${res.statusCode})');
  }

  final TextEditingController _searchController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดการผู้ใช้'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: getUsers),
        ],
      ),

      // 🚨 อย่าลืมเอาบรรทัดนี้ไปวางไว้ด้านบนสุดของ Class (ใกล้ๆ กับ List _users) นะครับ
      // final TextEditingController _searchController = TextEditingController();
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            ) // ถ้ากำลังโหลดให้หมุนๆ ตรงกลางหน้าจอ
          : Column(
              children: [
                // 💡 ส่วนที่ 1: ช่องค้นหา (อยู่ด้านบนเสมอ)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'ค้นหาชื่อ หรือ อีเมล...',
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () async {
                          _searchController.clear();
                          final allUsers = await getUsers();
                          setState(() {
                            _users = allUsers;
                          });
                        },
                      ),
                    ),
                    onChanged: (text) async {
                      if (text.isEmpty) {
                        final allUsers = await getUsers();
                        setState(() {
                          _users = allUsers;
                        });
                      } else {
                        final results = await searchUsers(text);
                        setState(() {
                          _users = results;
                        });
                      }
                    },
                  ),
                ),

                // 💡 ส่วนที่ 2: พื้นที่แสดงข้อมูล (ใช้ Expanded เพื่อให้ยืดเต็มพื้นที่ที่เหลือ)
                Expanded(
                  child: _users.isEmpty
                      // ถ้าไม่มีข้อมูลให้แสดงข้อความนี้
                      ? const Center(child: Text('ไม่มีข้อมูลผู้ใช้'))
                      // ถ้ามีข้อมูลก็ดึง ListView.builder มาแสดง
                      : ListView.builder(
                          itemCount: _users.length,
                          itemBuilder: (context, index) {
                            final user = _users[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Text(user['name']?[0] ?? 'U'),
                                ),
                                title: Text('Name: ${user['name']}'),
                                subtitle: Text('ID: ${user['id']}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                      ),
                                      onPressed: () {
                                        _showEditUserDialog(user);
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () {
                                        _confirmDelete(user['id'].toString());
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddUserDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}