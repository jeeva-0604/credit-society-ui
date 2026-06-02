import 'package:credit_society/service/collection_service.dart';
import 'package:flutter/material.dart';

class CollectionPreviewScreen extends StatefulWidget {
  final Map data;
  const CollectionPreviewScreen({required this.data});

  @override
  State<CollectionPreviewScreen> createState() =>
      _CollectionPreviewScreenState();
}

class _CollectionPreviewScreenState extends State<CollectionPreviewScreen> {
  Map? preview;

  @override
  void initState() {
    super.initState();
    loadPreview();
  }

  void loadPreview() async {
    final res = await CollectionService().previewCollection(widget.data);
    setState(() => preview = res);
  }

  void create() async {
    final res = await CollectionService().createCollection(widget.data);
    Navigator.pop(context);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Created ID ${res['collection_id']}")));
  }

  @override
  Widget build(BuildContext context) {
    if (preview == null) return Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(title: Text("Preview")),
      body: Column(
        children: [
          Text("Total: ${preview!['total_amount']}"),
          Text("Valid: ${preview!['valid_members']}"),
          Text("Invalid: ${preview!['invalid_members']}"),

          Expanded(
            child: ListView(
              children: (preview!['errors'] as List)
                  .map((e) => ListTile(
                title: Text("Member ${e['member_id']}"),
                subtitle: Text(e['error']),
              ))
                  .toList(),
            ),
          ),

          ElevatedButton(
            onPressed: preview!['can_post'] ? create : null,
            child: Text("Create Collection"),
          )
        ],
      ),
    );
  }
}