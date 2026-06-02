import 'package:credit_society/utils/app_colors.dart';
import 'package:flutter/material.dart';

import '../service/member_service.dart';

class MemberEntryScreen extends StatefulWidget {
  final Map? member;
  final VoidCallback? onSave; // ✅ ADD THIS

  const MemberEntryScreen({
    super.key,
    this.member,
    this.onSave,
  });

  @override
  State<MemberEntryScreen> createState() => _MemberEntryScreenState();
}

class _MemberEntryScreenState extends State<MemberEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _focusNodes = List.generate(40, (index) => FocusNode());

  // Controllers
  final memberNo = TextEditingController();
  final memberName = TextEditingController();
  final mobile = TextEditingController();
  final email = TextEditingController();
  final pan = TextEditingController();
  final aadhar = TextEditingController();

  final admissionDate = TextEditingController();
  final staffNo = TextEditingController();
  final fatherName = TextEditingController();
  final dob = TextEditingController();
  final sex = TextEditingController();
  final phoneNo = TextEditingController();

  final address1 = TextEditingController();
  final address2 = TextEditingController();
  final address3 = TextEditingController();
  final city = TextEditingController();
  final stateCtrl = TextEditingController();
  final pincode = TextEditingController();

  final nominee = TextEditingController();
  final relation = TextEditingController();
  final nomineeAddress = TextEditingController();
  final nomineeAge = TextEditingController();

  final bankName = TextEditingController();
  final branchName = TextEditingController();
  final accountNo = TextEditingController();
  final ifsc = TextEditingController();

  final salary = TextEditingController();
  final designation = TextEditingController();
  final appointmentDate = TextEditingController();
  final confirmationDate = TextEditingController();
  final department = TextEditingController();
  final location = TextEditingController();
  final unit = TextEditingController();
  final region = TextEditingController();
  final thriftAmount = TextEditingController();

  bool neftApprove = false;
  String selectedSex = "Male";

  @override
  void initState() {
    super.initState();

    if (widget.member != null) {
      final m = widget.member!;

      // ================= BASIC =================
      memberNo.text = m["member_no"] ?? "";
      memberName.text = m["member_name"] ?? "";
      mobile.text = m["mobile"] ?? "";
      email.text = m["email"] ?? "";
      pan.text = m["pan_no"] ?? "";
      aadhar.text = m["aadhar_no"] ?? "";

      // ================= ADDITIONAL =================
      staffNo.text = m["staff_no"] ?? "";
      fatherName.text = m["father_spouse_name"] ?? "";
      phoneNo.text = m["phone_no"] ?? "";
      selectedSex = m["sex"] ?? "Male";
      dob.text = m["dob"] ?? "";
      admissionDate.text = m["admission_date"] ?? "";

      // ================= ADDRESS =================
      final addr = m["address"];
      if (addr != null) {
        address1.text = addr["address1"] ?? "";
        address2.text = addr["address2"] ?? "";
        address3.text = addr["address3"] ?? "";
        city.text = addr["city"] ?? "";
        stateCtrl.text = addr["state"] ?? "";
        pincode.text = addr["pincode"] ?? "";
      }

      // ================= NOMINEE =================
      final nom = m["nominee"];
      if (nom != null) {
        nominee.text = nom["nominee"] ?? "";
        relation.text = nom["relation_ship"] ?? "";
        nomineeAddress.text = nom["nominee_address1"] ?? "";
        nomineeAge.text = nom["nominee_age"]?.toString() ?? "";
      }

      // ================= BANK =================
      final bank = m["bank"];
      if (bank != null) {
        bankName.text = bank["bank_name"] ?? "";
        branchName.text = bank["branch_name"] ?? "";
        accountNo.text = bank["account_no"] ?? "";
        ifsc.text = bank["ifsc_code"] ?? "";
        neftApprove = bank["neft_approve"] ?? false;
      }

      // ================= EMPLOYMENT =================
      final emp = m["employment"];
      if (emp != null) {
        salary.text = (emp["salary_amount"] ?? "").toString();
        designation.text = emp["designation"] ?? "";
        appointmentDate.text = emp["appointment_date"] ?? "";
        confirmationDate.text = emp["confirmation_date"] ?? "";
        department.text = emp["department"] ?? "";
        location.text = emp["location"] ?? "";
        //unit.text = emp["unit"] ?? "";
        region.text = emp["region"] ?? "";
      }
      // ================= THRIFT CONFIG =================
      final tConfig = m["thrift_config"];
      if (tConfig != null) {
        thriftAmount.text = (tConfig["thrift_amount"] ?? "").toString();
      }
    }
  }

  @override
  void dispose() {
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Member Entry"), backgroundColor: AppColors.primary),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isDesktop = constraints.maxWidth > 900;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: isDesktop
                  ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildLeftSection()),
                  const SizedBox(width: 6),
                  Expanded(child: _buildRightSection()),
                  const SizedBox(width: 5),
                  _buildButtonSection(),
                ],
              )
                  : Column(
                children: [
                  _buildLeftSection(),
                  const SizedBox(height: 10),
                  _buildRightSection(),
                  const SizedBox(width: 5),
                  _buildButtonSection(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildButtonSection() {
    return Column(
        children: [
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
            child: const Text("Submit"),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _approve,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
            child: const Text("Approve"),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _reject,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
            child: const Text("Reject"),
          )
        ]);
  }

  // ================= LEFT SECTION =================
  Widget _buildLeftSection() {
    return Column(
      children: [
        _sectionCard("Basic Details", [
          _gridFields([
            _text(memberNo, "Member No", 0),
            _text(memberName, "Member Name", 1),
            _text(mobile, "Mobile", 2),
            _text(email, "Email", 3),
            _text(pan, "PAN No", 4),
            _text(aadhar, "Aadhar No", 5),
          ])
        ]),
        _sectionCard("Additional Details", [
          _gridFields([
            _text(staffNo, "Staff No", 6),
            _text(fatherName, "Father/Spouse Name", 7),
            _text(phoneNo, "Phone No", 8),
            SizedBox(
              height: 40,
              child: DropdownButtonFormField<String>(
                value: selectedSex,
                isDense: true,
                items: ["Male", "Female"].map((e) {
                  return DropdownMenuItem(value: e, child: Text(e));
                }).toList(),
                onChanged: (val) => setState(() => selectedSex = val!),
                decoration: const InputDecoration(
                  labelText: "Sex",
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            TextFormField(
              controller: dob,
              readOnly: true,
              onTap: () => pickDate(dob),
              decoration: InputDecoration(
                labelText: "DOB",
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(),
              )
            ),
            TextFormField(
              controller: admissionDate,
              readOnly: true,
              onTap: () => pickDate(admissionDate),
                decoration: InputDecoration(
                  labelText: "Admission Date",
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: OutlineInputBorder(),
                )
            ),
          ])
        ]),

        _sectionCard("Address", [
          _gridFields([
            _text(address1, "Address Line 1", 12),
            _text(address2, "Address Line 2", 13),
            _text(address3, "Address Line 3", 14),
            _text(city, "City", 15),
            _text(stateCtrl, "State", 16),
            _text(pincode, "Pincode", 17),
          ])
        ]),
      ],
    );
  }

  // ================= RIGHT SECTION =================
  Widget _buildRightSection() {
    return Column(
      children: [
        _sectionCard("Nominee", [
          _gridFields([
            _text(nominee, "Nominee Name", 18),
            _text(relation, "Relationship", 19),
            _text(nomineeAge, "Age", 20),
            SizedBox(
              width: 200,
              child: TextFormField(
                controller: nomineeAddress,
                focusNode: _focusNodes[21],
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _handleEnter(21),
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  labelText: "Nominee Address",
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ])
        ]),
        _sectionCard("Bank Details", [
          _gridFields([
            _text(bankName, "Bank Name", 22),
            _text(branchName, "branch Name", 23),
            _text(accountNo, "Account No", 24),
            _text(ifsc, "IFSC Code", 25),

            SizedBox(
              height: 30,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "NEFT Approved",
                    style: TextStyle(fontSize: 14),
                  ),
                  Transform.scale(
                    scale: 0.8, // 🔥 makes switch smaller
                    child: Switch(
                      value: neftApprove,
                      onChanged: (val) => setState(() => neftApprove = val),
                    ),
                  ),
                ],
              ),
            ),
            _text(thriftAmount, "Monthly Thrift Amt", 32),
          ])
        ]),

        _sectionCard("Employment", [
          _gridFields([
            _text(salary, "Salary", 26),
            _text(designation, "Designation", 27),
            TextFormField(
                controller: appointmentDate,
                readOnly: true,
                onTap: () => pickDate(appointmentDate),
                decoration: InputDecoration(
                  labelText: "Appointment Date",
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 8, vertical: 8),
                  border: OutlineInputBorder(),
                )
            ),
            TextFormField(
                controller: confirmationDate,
                readOnly: true,
                onTap: () => pickDate(confirmationDate),
                decoration: InputDecoration(
                  labelText: "Confirmation Date",
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 8, vertical: 8),
                  border: OutlineInputBorder(),
                )
            ),

            _text(department, "Department", 28),
            _text(location, "Location", 29),
            _text(unit, "Unit", 30),
            _text(region, "Region", 31),
          ])
        ]),
      ],
    );
  }

  Widget _gridFields(List<Widget> fields) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 3; // FORCE 3 columns always

        double spacing = 6;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: fields.map((f) {
            return SizedBox(
              width: (constraints.maxWidth / columns) - spacing,
              height: 45, // 🔥 critical for no scroll
              child: f,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _sectionCard(String title, List<Widget> children) {
    return Card(
      elevation: 2, // 👈 reduce shadow
      margin: const EdgeInsets.only(bottom: 6), // 👈 less gap between cards
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8), // 👈 slightly tighter corners
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6), // 👈 reduced padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14, // 👈 smaller title
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6), // 👈 reduce gap
            ...children
          ],
        ),
      ),
    );
  }

  Widget _text(TextEditingController ctrl, String label, int index) {
    return TextFormField(
      controller: ctrl,
      focusNode: _focusNodes[index],
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) => _handleEnter(index),
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 9,
          vertical: 9,
        ),
        border: const OutlineInputBorder(),
      ),
    );
  }

  Future<void> pickDate(TextEditingController controller) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      controller.text = picked
          .toIso8601String()
          .split('T')
          .first;
    }
  }

  void _handleEnter(int index) {
    if (index < _focusNodes.length - 1) {
      FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
    } else {
      _submit(); // last field → submit
    }
  }

  // ================= SUBMIT =================
  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final data = {
      "member_no": memberNo.text,
      "member_name": memberName.text,
      "mobile": mobile.text,
      "email": email.text,
      "pan_no": pan.text,
      "aadhar_no": aadhar.text,
      "staff_no": staffNo.text,
      "father_spouse_name": fatherName.text,
      "phone_no": phoneNo.text,
      "sex": selectedSex,
      "dob": dob.text, // ✅ string date
      "admission_date": admissionDate.text, // ✅ string date

      "address": {
        "address1": address1.text,
        "address2": address2.text,
        "address3": address3.text,
        "city": city.text,
        "state": stateCtrl.text,
        "pincode": pincode.text,
      },

      "nominee": {
        "nominee": nominee.text,
        "relation_ship": relation.text,
        "nominee_address1": nomineeAddress.text,
        "nominee_age": int.tryParse(nomineeAge.text)
      },

      "bank": {
        "bank_name": bankName.text,
        "branch_name": branchName.text,
        "account_no": accountNo.text,
        "ifsc_code": ifsc.text, // ✅ FIXED
        "neft_approve": neftApprove // ✅ FIXED
      },

      "employment": {
        "salary_amount": double.tryParse(salary.text) ?? 0,
        "designation": designation.text,
        "appointment_date": appointmentDate.text,
        "confirmation_date": confirmationDate.text,
        "department": department.text,
        "location": location.text,
        "unit": unit.text,
        "region": region.text
      },

      "thrift_config": {
        "thrift_amount": double.tryParse(thriftAmount.text) ?? 0.0,
        "effective_from": admissionDate.text,
      },
    };

    if (widget.member == null) {
      // CREATE
      await MemberService().createMember(data);
    } else {
      // UPDATE
      await MemberService().updateMember(widget.member!["id"], data);
    }
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Member Saved Successfully")),
    );
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      // This handles the case where it's embedded in your NavigationRail/HomeScreen
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  void _approve() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.member != null) {
      final data = {
        "member_no": memberNo.text,
      };
      await MemberService().approveMember(widget.member!["id"]);
    }

    widget.onSave?.call();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Member Saved Successfully")),
    );
  }

  void _reject() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.member != null) {
      final data = {
        "member_no": memberNo.text,
      };
      await MemberService().rejectMember(widget.member!["id"], data);
    }

    widget.onSave?.call();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Member Saved Successfully")),
    );
  }
}