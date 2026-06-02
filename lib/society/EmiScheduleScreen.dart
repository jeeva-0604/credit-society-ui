import 'package:flutter/material.dart';

import '../service/loan_service.dart';

class EmiScheduleScreen extends StatefulWidget {
  final int loanId;

  const EmiScheduleScreen({super.key, required this.loanId});

  @override
  State<EmiScheduleScreen> createState() => _EmiScheduleScreenState();
}

class _EmiScheduleScreenState extends State<EmiScheduleScreen> {
  List emis = [];

  @override
  void initState() {
    super.initState();
    loadEmis();
  }

  Future<void> loadEmis() async {
    emis = await LoanService().getEmiSchedule(widget.loanId);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("EMI Schedule")),
      body: LayoutBuilder(
          builder: (context, constraints) {
            int columns = (constraints.maxWidth / 140)
                .floor(); // 140px per card

            return GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns.clamp(4, 12), // min 4, max 12
                childAspectRatio: 0.8,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: emis.length,
              itemBuilder: (context, index) {
                final emi = emis[index];

                Color statusColor() {
                  switch (emi["status"]) {
                    case "PAID":
                      return Colors.green;
                    case "OVERDUE":
                      return Colors.red;
                    default:
                      return Colors.orange;
                  }
                }

                return GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius
                            .circular(16)),
                      ),
                        builder: (_) => DraggableScrollableSheet(
                          expand: false,
                          builder: (_, controller) => SingleChildScrollView(
                            controller: controller,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    height: 4,
                                    width: 40,
                                    margin: const EdgeInsets.only(bottom: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.grey,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),

                                  Text("Installment #${emi["installment_no"]}",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),

                                  const SizedBox(height: 10),

                                  Text("Principal: ₹${emi["principal"]}"),
                                  Text("Interest: ₹${emi["interest"]}"),
                                  Text("Total: ₹${emi["total_amount"]}"),
                                  Text("Due: ${emi["due_date"]}"),
                                  Text("Status: ${emi["status"]}"),
                                ],
                              ),
                            ),
                          ),
                        )
                    );
                  },
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("${emi["installment_no"]}", style: TextStyle(fontSize: 10)),
                          Text("₹${emi["total_amount"]}", style: TextStyle(fontSize: 10)),
                          Text(
                            emi["due_date"].toString().substring(0, 10),
                            style: TextStyle(fontSize: 9),
                          ),
                          Text(
                            emi["status"],
                            style: TextStyle(
                              fontSize: 9,
                              color: statusColor(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
      )
    );
  }

}