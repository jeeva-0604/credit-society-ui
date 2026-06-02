import 'package:credit_society/service/collection_service.dart';
import 'package:flutter/material.dart';

class CollectionDetailScreen extends StatelessWidget {
  final int id;
  final String status;

  const CollectionDetailScreen({required this.id, required this.status});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Collection $id")),
      body: Column(
        children: [
          Text("Status: $status"),

          if (status == "PENDING")
            ElevatedButton(
              onPressed: () async {
                await CollectionService().approve(id);
              },
              child: Text("Approve"),
            ),

          if (status == "APPROVED")
            ElevatedButton(
              onPressed: () async {
                await CollectionService().post(id);
              },
              child: Text("Post"),
            ),

          if (status == "POSTED")
            ElevatedButton(
              onPressed: () async {
                await CollectionService().reverse(id);
              },
              child: Text("Reverse"),
            ),
        ],
      ),
    );
  }
}