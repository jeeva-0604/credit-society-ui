import 'package:credit_society/service/demand_service.dart';
import 'package:flutter/material.dart';

import '../service/member_service.dart';

class DemandListScreen extends StatefulWidget {
  const DemandListScreen({super.key});

  @override
  State<DemandListScreen> createState() => _DemandListScreenState();
}

class _DemandListScreenState extends State<DemandListScreen> {
  String selectedUnit = "All";
  List<String> units = ["All"];

  List demandDetails = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadUnits();
  }

  Future<void> loadDemandData({String? unit}) async {
    setState(() => isLoading = true);
    try {
      final data = await DemandService().getDemandReport(unit);
      setState(() {
        demandDetails = data;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading demand: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> loadUnits() async {
    try {
      final fetchedData = await MemberService().getUniqueUnits();
      setState(() {
        units = ["All"] + fetchedData.map((item) {
          return item is Map ? item['name'].toString() : item.toString();
        }).toList().cast<String>();
      });
    } catch (e) {
      print("Error loading units: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Demand Extract Report")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text("Filter by Unit: "),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: selectedUnit,
                  items: units.map((u) => DropdownMenuItem(
                      value: u,
                      child: Text(u)
                  )).toList(),
                  onChanged: (val) {
                    setState(() => selectedUnit = val!);
                    // Trigger API to reload Demand Table filtered by this unit
                    loadDemandData(unit: val);
                  },
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text("Member No")),
                  DataColumn(label: Text("Name")),
                  DataColumn(label: Text("Loan EMI")),
                  DataColumn(label: Text("Thrift")),
                  DataColumn(label: Text("Total Due")),
                  DataColumn(label: Text("Action")),
                ],
                rows: demandDetails.map((d) => DataRow(cells: [
                  DataCell(Text(d["member_no"] ?? "")),
                  DataCell(Text(d["member_name"] ?? "")),
                  DataCell(Text(d["loan_emi"].toString())),
                  DataCell(Text(d["thrift_amount"].toString())),
                  DataCell(Text(d["total_demand"].toString())),
                  DataCell(IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _editDemand(d), // Requirement 5: Demand Edit Option
                  )),
                ])).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Add this inside _DemandListScreenState
  void _editDemand(Map data) {
    TextEditingController amountController =
    TextEditingController(text: data["total_demand"].toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit Demand: ${data['member_name']}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Member No: ${data['member_no']}"),
            const SizedBox(height: 10),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Adjusted Total Demand",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              // Update logic here (Requirement 5)
              // await DemandService().updateDemandAmount(data['id'], amountController.text);
              Navigator.pop(context);
              loadDemandData(unit: selectedUnit);
            },
            child: const Text("Update"),
          )
        ],
      ),
    );
  }
}