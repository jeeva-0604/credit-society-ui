import 'package:flutter/material.dart';import 'package:credit_society/utils/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CalendarDialogs {
  static void showEventDialog({
    required BuildContext context,
    required DateTime initialDate,
    Map<String, dynamic>? event,
    required Function(Map<String, dynamic>) onSave,
  }) {
    final isEdit = event != null;
    final titleController = TextEditingController(text: isEdit ? event['title'] : "");
    final descController = TextEditingController(text: isEdit ? event['description'] : "");
    String selectedType = isEdit ? event['event_type'] : "exam";

    DateTime startDate = isEdit ? DateTime.parse(event['start_date']) : initialDate;
    DateTime endDate = isEdit && event['end_date'] != null
        ? DateTime.parse(event['end_date'])
        : startDate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEdit ? "Edit Event" : "New Event"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: "Event Title")),
                TextField(controller: descController, decoration: const InputDecoration(labelText: "Description")),
                const SizedBox(height: 15),

                DropdownButtonFormField<String>(
                  value: selectedType,
                  items: ["holiday", "exam", "event", "meeting"].map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase()))).toList(),
                  onChanged: (val) => setState(() => selectedType = val!),
                  decoration: const InputDecoration(labelText: "Event Type", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),

                // ✅ DATE RANGE PICKER ROW
                const Text("Event Duration:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Start Date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("From", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(DateFormat('MMM dd').format(startDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward, color: Colors.grey),

                    // End Date Picker
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: endDate,
                            firstDate: startDate, // Cannot end before start
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setState(() => endDate = picked);
                          }
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text("To (Tap to change)", style: TextStyle(fontSize: 12, color: Colors.blue)),
                            Text(
                                DateFormat('MMM dd, yyyy').format(endDate),
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16)
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                onSave({
                  "title": titleController.text,
                  "description": descController.text,
                  "start_date": DateFormat('yyyy-MM-dd').format(startDate),
                  "end_date": DateFormat('yyyy-MM-dd').format(endDate),
                  "event_type": selectedType,
                });
                Navigator.pop(ctx);
              },
              child: const Text("Save"),
            )
          ],
        ),
      ),
    );
  }
}


class TeacherWorkLogDialogs {
  static void showEventDialog({
    required BuildContext context,
    required DateTime initialDate,
    Map<String, dynamic>? event,
    required Function(Map<String, dynamic>) onSave,
  }) {
    final isEdit = event != null;
    final titleController = TextEditingController(text: isEdit ? event['title'] : "");
    final descController = TextEditingController(text: isEdit ? event['description'] : "");

    // ✅ Initialize Duration Controller
    final durationController = TextEditingController(
        text: isEdit ? event['duration_minutes']?.toString() : "40");

    String selectedType = isEdit ? event['event_type'] : "preparation";

    DateTime startDate = isEdit ? DateTime.parse(event['start_date']) : initialDate;
    DateTime endDate = isEdit && event['end_date'] != null
        ? DateTime.parse(event['end_date'])
        : startDate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isEdit ? "Edit Work Entry" : "Log Work Done"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: "Subject / Topic", hintText: "e.g. Maths - Algebra")
                ),
                TextField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: "Work Details", hintText: "What was covered?")
                ),
                const SizedBox(height: 15),

                DropdownButtonFormField<String>(
                  value: selectedType,
                  items: ["preparation", "teaching", "exam_duty", "meeting", "others"]
                      .map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase())))
                      .toList(),
                  onChanged: (val) => setState(() => selectedType = val!),
                  decoration: const InputDecoration(labelText: "Category", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),

                // ✅ DURATION (MINUTES) INPUT
                TextField(
                  controller: durationController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: "Duration of Period",
                    suffixText: "minutes",
                    prefixIcon: Icon(Icons.timer_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                const Text("Date of Work:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () async {
                    // Change this block:
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: startDate,
                      firstDate: DateTime(2024), // ✅ Changed from firstDay to firstDate
                      lastDate: DateTime(2030),  // ✅ Changed from lastDay to lastDate
                    );
                    if (picked != null) {
                      setState(() {
                        startDate = picked;
                        endDate = picked; // Usually daily work is 1 day
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8)
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(DateFormat('EEEE, MMM dd, yyyy').format(startDate)),
                        const Icon(Icons.calendar_today, size: 18, color: Colors.blue),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5E1783)),
              onPressed: () {
                if (titleController.text.isEmpty) return;

                onSave({
                  "title": titleController.text,
                  "description": descController.text,
                  "start_date": DateFormat('yyyy-MM-dd').format(startDate),
                  "end_date": DateFormat('yyyy-MM-dd').format(endDate),
                  "duration_minutes": int.tryParse(durationController.text) ?? 40,
                  "event_type": selectedType,
                });
                Navigator.pop(ctx);
              },
              child: const Text("Save Log", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}