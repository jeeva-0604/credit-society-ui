import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:credit_society/society/MemberEntryScreen.dart';
import 'package:flutter/material.dart';
import '../service/member_service.dart';
import '../utils/app_colors.dart';

class MemberListScreen extends StatefulWidget {
  final Function(Map)? onEdit;
  final VoidCallback? onNew;
  const MemberListScreen({super.key, required this.onEdit, this.onNew});

  @override
  State<MemberListScreen> createState() => _MemberListScreenState();
}

class _MemberListScreenState extends State<MemberListScreen> {
  List members = [];
  String search = "";
  List filteredMembers = [];
  TextEditingController searchController = TextEditingController();
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    members = await MemberService().getMembers(search);
    filteredMembers = members;
    setState(() {});
  }

  void _showErrorDialog(List errors) {
    print(errors);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Upload Errors"),
        content: SizedBox(
          width: 400,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: errors.length,
            itemBuilder: (_, i) {
              final e = errors[i];
              return Text(
                "Row ${e['row']} (${e['member_no']}) → ${e['error']}",
                style: const TextStyle(fontSize: 12),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          )
        ],
      ),
    );
  }

  Future<void> uploadMemberCSV() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result == null) return;

    final file = result.files.single;

    try {
      // 🔄 SHOW LOADING
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final response = await MemberService().uploadMemberCSV(file);

      Navigator.pop(context); // ❌ close loader

      final success = response["successful_records"];
      final failed = response["failed_records"];

      // ✅ SHOW RESULT
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Uploaded: $success | Failed: $failed"),
          backgroundColor: failed > 0 ? Colors.orange : Colors.green,
        ),
      );

      // ✅ SHOW ERROR DETAILS (IF ANY)
      if (failed > 0) {
        _showErrorDialog(response["errors"]);
      }

      // 🔄 RELOAD LIST
      await load();

    } catch (e) {
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Members"),
        backgroundColor: AppColors.primary),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (widget.onNew != null) {
            widget.onNew!();
          }
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        hintText: "Search Member",
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) {
                        setState(() {
                          search = val;
                          filteredMembers = members.where((m) {
                            final name = (m["member_name"] ?? "").toLowerCase();
                            final no = (m["member_no"] ?? "").toLowerCase();
                            return name.contains(val.toLowerCase()) ||
                                no.contains(val.toLowerCase());
                          }).toList();
                        });
                      }
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () async {
                    search = searchController.text;
                    members = await MemberService().getMembers(search);
                    filteredMembers = members;
                    setState(() {});
                  },
                  child: const Text("Search"),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () async {
                    searchController.text = "";
                    members = await MemberService().getMembers("");
                    filteredMembers = members;
                    setState(() {});
                  },
                  child: const Text("Reset"),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: uploadMemberCSV,
                  icon: const Icon(Icons.upload_file),
                  label: const Text("Upload CSV"),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredMembers.length,
              itemBuilder: (_, i) {
                final m = filteredMembers[i];
                return ListTile(
                  title: Text(m["member_name"]),
                  subtitle: Text(m["member_no"] ?? ""),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      if (widget.onEdit != null) {
                        widget.onEdit!(m);
                      }
                    },
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}