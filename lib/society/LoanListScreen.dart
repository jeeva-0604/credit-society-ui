import 'package:flutter/material.dart';
import '../service/loan_service.dart';
import 'EmiScheduleScreen.dart';

class LoanListScreen extends StatefulWidget {
  const LoanListScreen({super.key});

  @override
  State<LoanListScreen> createState() => _LoanListScreenState();
}

class _LoanListScreenState extends State<LoanListScreen> {
  List loans = [];

  @override
  void initState() {
    super.initState();
    loadLoans();
  }

  Future<void> loadLoans() async {
    loans = await LoanService().getLoans();
    setState(() {});
  }

  Color getStatusColor(String status) {
    switch (status) {
      case "PENDING":
        return Colors.orange;
      case "APPROVED":
        return Colors.blue;
      case "DISBURSED":
        return Colors.green;
      case "CLOSED":
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  final data = {
    "user_id": 1,
    "remarks": ""
  };

  String todayDate() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Loans")),
      body: ListView.builder(
        itemCount: loans.length,
        itemBuilder: (context, index) {
          final loan = loans[index];

          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              title: Text(loan["member_name"]),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Loan Type: ${loan["loan_type"]}"),
                  Text("Amount: ₹${loan["principal_amount"]}"),
                  Text("EMI: ₹${loan["emi_amount"]}"),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ✅ STATUS CHIP
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: getStatusColor(loan["status"]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      loan["status"],
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // ✅ ACTION MENU
                  PopupMenuButton(
                    onSelected: (value) async {
                      if (value == "approve") {
                        await LoanService().approveLoan(loan["id"], data);
                        loadLoans(); // refresh
                      } else if (value == "disburse") {
                        final data = {
                          "loan_id": loan["id"],
                          "amount": loan["principal_amount"],
                          "date": todayDate(), // ✅ FIXED
                          "has_share": false,
                          "old_loan_adjustment": 0
                        };
                        await LoanService().disburseLoan(data);
                        loadLoans(); // refresh
                      } else if (value == "payment" || value == "emi") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EmiScheduleScreen(loanId: loan["id"]),
                          ),
                        );
                      }
                    },
                    itemBuilder: (_) {
                      List<PopupMenuEntry<String>> items = [];

                      if (loan["status"] == "PENDING") {
                        items.add(const PopupMenuItem(value: "approve", child: Text("Approve")));
                      }

                      if (loan["status"] == "APPROVED") {
                        items.add(const PopupMenuItem(value: "disburse", child: Text("Disburse")));
                      }

                      if (loan["status"] == "DISBURSED") {
                        items.add(const PopupMenuItem(value: "payment", child: Text("Payment")));
                      }

                      return items;
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}