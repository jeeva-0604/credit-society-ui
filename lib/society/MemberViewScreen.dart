import 'package:flutter/material.dart';
import '../service/member_service.dart';
import '../utils/app_colors.dart';

class MemberViewScreen extends StatelessWidget {
  final Map member;

  const MemberViewScreen({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("View Member: ${member['member_name']}"),
        backgroundColor: AppColors.primary,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isDesktop = constraints.maxWidth > 900;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: isDesktop
                ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildLeftSection()),
                const SizedBox(width: 12),
                Expanded(child: _buildRightSection()),
              ],
            )
                : Column(
              children: [
                _buildLeftSection(),
                const SizedBox(height: 12),
                _buildRightSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  // ================= LEFT SECTION (Basic & Address) =================
  Widget _buildLeftSection() {
    return Column(
      children: [
        _infoCard("Basic Details", {
          "Member No": member["member_no"],
          "Member Name": member["member_name"],
          "Mobile": member["mobile"],
          "Email": member["email"],
          "PAN No": member["pan_no"],
          "Aadhar No": member["aadhar_no"],
          "Status": member["status"],
        }),
        _infoCard("Additional Details", {
          "Staff No": member["staff_no"],
          "Father/Spouse": member["father_spouse_name"],
          "Sex": member["sex"],
          "DOB": member["dob"],
          "Admission Date": member["admission_date"],
        }),
        _infoCard("Address", {
          "Address": "${member['address']?['address1'] ?? ''}, "
              "${member['address']?['address2'] ?? ''}, "
              "${member['address']?['address3'] ?? ''}",
          "City": member['address']?['city'],
          "State": member['address']?['state'],
          "Pincode": member['address']?['pincode'],
        }),
      ],
    );
  }

  // ================= RIGHT SECTION (Nominee, Bank, Employment) =================
  Widget _buildRightSection() {
    return Column(
      children: [
        _infoCard("Employment Information", {
          "Unit": member['employment']?['unit'],
          "Designation": member['employment']?['designation'],
          "Salary": "₹${member['employment']?['salary_amount']}",
          "Appointment Date": member['employment']?['appointment_date'],
          "Department": member['employment']?['department'],
          "Location": member['employment']?['location'],
        }),
        _infoCard("Bank & Thrift Details", {
          "Bank Name": member['bank']?['bank_name'],
          "Account No": member['bank']?['account_no'],
          "IFSC": member['bank']?['ifsc_code'],
          "NEFT Approved": member['bank']?['neft_approve'] == true ? "YES" : "NO",
          "Monthly Thrift": "₹${member['thrift_config']?['thrift_amount']}",
        }),
        _infoCard("Nominee Details", {
          "Nominee": member['nominee']?['nominee'],
          "Relationship": member['nominee']?['relation_ship'],
          "Age": member['nominee']?['nominee_age'],
          "Nominee Address": member['nominee']?['nominee_address1'],
        }),
        // Add this to the children list in _buildRightSection()
        _infoCard("Surety Financial Standing", {
          "Share Balance": "₹${member['share_balance'] ?? '0.00'}",
          "Thrift/TD Balance": "₹${member['td_balance'] ?? '0.00'}",
          "Active Sureties Given": "${member['active_surety_count'] ?? '0'}",
        }),
      ],
    );
  }

  // UI Helper: Modern Info Card
  Widget _infoCard(String title, Map<String, dynamic> fields) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal)),
            const Divider(),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: fields.entries.map((e) => _buildDetailItem(e.key, e.value.toString())).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
          Text(value == "null" || value == "" ? "N/A" : value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}