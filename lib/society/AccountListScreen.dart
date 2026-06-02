import 'package:flutter/material.dart';
import '../service/account_service.dart';
import '../utils/app_colors.dart';

class AccountListScreen extends StatefulWidget {
  const AccountListScreen({super.key});

  @override
  State<AccountListScreen> createState() => _AccountListScreenState();
}

class _AccountListScreenState extends State<AccountListScreen> {
  List accounts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadAccounts();
  }

  Future<void> loadAccounts() async {
    setState(() => isLoading = true);
    try {
      accounts = await AccountService().getAccounts() ?? [];
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Accounts"),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              // await Navigator.push(context, MaterialPageRoute(
              //   builder: (_) => const AccountScreen(),
              // ));
              loadAccounts();
            },
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text("Account No")),
            DataColumn(label: Text("Member")),
            DataColumn(label: Text("Type")),
            DataColumn(label: Text("Ledger")),
            DataColumn(label: Text("Balance")),
            DataColumn(label: Text("Status")),
          ],
          rows: accounts.map<DataRow>((a) {
            return DataRow(cells: [
              DataCell(Text(a["account_number"] ?? "")),
              DataCell(Text(a["member_name"] ?? "")),
              DataCell(Text(a["account_type"] ?? "")),
              DataCell(Text(a["ledger_name"] ?? "")),
              DataCell(Text(a["balance"].toString())),
              DataCell(Text(a["status"] ?? "")),
            ]);
          }).toList(),
        )
      ),
    );
  }
}