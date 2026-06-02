import 'package:flutter/material.dart';
import '../service/member_service.dart';
import '../utils/app_colors.dart';
import '../service/demand_service.dart'; // You'll need to create this service

class DemandGenScreen extends StatefulWidget {
  const DemandGenScreen({super.key});

  @override
  State<DemandGenScreen> createState() => _DemandGenScreenState();
}

class _DemandGenScreenState extends State<DemandGenScreen> {
  DateTime selectedDate = DateTime.now();
  bool isProcessing = false;

  List<Map<String, dynamic>> units = [
    {"id": 0, "name": "All"}
  ];

  int? selectedUnit = 0;

  List demandDetails = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadUnits();
  }

  Future<void> loadUnits() async {
    try {
      final fetchedData = await MemberService().getUniqueUnits();

      setState(() {
        units = [
          {"id": 0, "name": "All"},
          ...fetchedData.map((item) => {
            "id": item["id"],
            "name": item["name"]
          })
        ];

        selectedUnit = 0;
      });
    } catch (e) {
      print("Error loading units: $e");
    }
  }

  void _runGeneration() async {
    if (selectedUnit == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select unit")),
      );
      return;
    }

    final confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm"),
        content: Text(
          "Generate demand for ${selectedDate.month}/${selectedDate.year}?\nThis cannot be undone.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Proceed")),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isProcessing = true);

    try {
      DateTime normalizedDate =
      DateTime(selectedDate.year, selectedDate.month, 1);

      await DemandService().generateDemand(
        normalizedDate,
        selectedUnit!,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Demand Generated Successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Monthly Demand Generation",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                DropdownButtonFormField<int>(
                  value: selectedUnit,
                  decoration: const InputDecoration(labelText: "Select Unit"),
                  items: units.map<DropdownMenuItem<int>>((u) {
                    return DropdownMenuItem(
                      value: u["id"],
                      child: Text(u["name"]),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => selectedUnit = val);
                  },
                ),
                const SizedBox(height: 20),
                Text("Selected Month: ${selectedDate.month} / ${selectedDate.year}"),
                ElevatedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => selectedDate = picked);
                  },
                  child: const Text("Select Month"),
                ),
                const SizedBox(height: 30),
                isProcessing
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: _runGeneration,
                  child: const Text("Run Generation Process", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}