import 'package:credit_society/service/collection_service.dart';
import 'package:flutter/material.dart';

import '../model/collection_model.dart';
import 'collection_preview_screen.dart';

class CollectionCreateScreen extends StatefulWidget {
  const CollectionCreateScreen({super.key});

  @override
  State<CollectionCreateScreen> createState() =>
      _CollectionCreateScreenState();
}

class _CollectionCreateScreenState extends State<CollectionCreateScreen> {
  List<CollectionItem> items = [];

  void loadPendingDemands() async {
    final response = await CollectionService().fetchPendingDemands(2);

    setState(() {
      items = response.map<CollectionItem>((e) {
        return CollectionItem(
          memberId: e["member_id"],
          demandDetailId: e["demand_detail_id"],
          loanId: e["loan_id"],
          scheduleId: e["schedule_id"],
          thriftAmount: (e["thrift_amount"] ?? 0).toDouble(),
          principalAmount: (e["principal"] ?? 0).toDouble(),
          interestAmount: (e["interest"] ?? 0).toDouble(),
          otherCharges: (e["penalty"] ?? 0).toDouble(),
        );
      }).toList();
    });
  }

  void goPreview() {
    final data = {
      "collection_date": DateTime.now().toIso8601String().split("T")[0],
      "unit_id": 1,
      "reference_no": "COL-${DateTime.now().millisecondsSinceEpoch}",
      "items": items.map((e) => e.toJson()).toList()
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CollectionPreviewScreen(data: data),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Collection")),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: loadPendingDemands,
            child: const Text("Load Members"),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, i) {
                final item = items[i];

                return Card(
                  child: ListTile(
                    title: Text("Member ${item.memberId}"),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Thrift: ${item.thriftAmount}"),
                        Text("Principal: ${item.principalAmount}"),
                        Text("Interest: ${item.interestAmount}"),
                      ],
                    ),
                    trailing: Text(
                      item.total().toStringAsFixed(2),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),
          ),

          ElevatedButton(
            onPressed: items.isEmpty ? null : goPreview,
            child: const Text("Preview"),
          )
        ],
      ),
    );
  }
}