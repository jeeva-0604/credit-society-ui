import 'package:flutter/material.dart';

import '../service/loan_service.dart';
import '../service/member_service.dart';
import '../utils/app_colors.dart';
import 'MemberEntryScreen.dart';
import 'MemberViewScreen.dart';

class LoanApplyScreen extends StatefulWidget {
  const LoanApplyScreen({super.key});

  @override
  State<LoanApplyScreen> createState() => _LoanApplyScreenState();
}

class _LoanApplyScreenState extends State<LoanApplyScreen> {
  final memberId = TextEditingController();
  final loanTypeId = TextEditingController();
  final amount = TextEditingController();
  final tenure = TextEditingController();
  final interest = TextEditingController();
  final preLoanDate = TextEditingController();
  final preInterest = TextEditingController();
  int? selectedMember;
  int? selectedLoanType;
  List members = [];
  List loanTypes = [];
  final salary = TextEditingController();
  final shareBalance = TextEditingController(); // Available Share
  final tdBalance = TextEditingController();    // Available TD
  final drsBalance = TextEditingController();   // Available DRS

  final surety1MemNo = TextEditingController();
  final surety2MemNo = TextEditingController();
  final surety1MemName = TextEditingController();
  final surety2MemName = TextEditingController();

  final totalAdjustment = TextEditingController(); // For Top-up / Share deduction
  final netAmountToPay = TextEditingController();  // Final Net Amount
  bool isSurety1Valid = false;
  bool isSurety2Valid = false;
  String paymentMode = "NEFT"; // Default based on legacy screen
  bool isCalculatingEligibility = false;

  // Logic to calculate Net Pay (Requirement 3 & Share Rule)
  void calculateNetPay() {
    double sanctioned = double.tryParse(amount.text) ?? 0.0;
    double currentShare = double.tryParse(shareBalance.text) ?? 0.0;
    double prevLoanBalance = 0.0; // Fetch this via API for top-ups

    // Rule: 4% Share Capital Check
    double requiredShare = sanctioned * 0.04;
    double shareDeduction = (currentShare < requiredShare) ? (requiredShare - currentShare) : 0.0;

    // Rule: Prev Loan mandatory adjustment
    double adjustment = shareDeduction + prevLoanBalance;
    double net = sanctioned - adjustment;

    setState(() {
      totalAdjustment.text = adjustment.toStringAsFixed(2);
      netAmountToPay.text = net.toStringAsFixed(2);
    });
  }

  @override
  void initState() {
    loadMembers();
    loadLoanTypes();
    super.initState();
  }

  Future<void> applyLoan() async {
    if (selectedMember == null || selectedLoanType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select member & loan type")),
      );
      return;
    }

    // Business Logic: Check if amount > 1 Lakh and sureties are valid
    double loanAmount = double.tryParse(amount.text) ?? 0.0;
    if (loanAmount > 100000 && (!isSurety1Valid || !isSurety2Valid)) {
      _showError("Loans above ₹1 Lakh require two valid sureties.");
      return;
    }

    final data = {
      "member_id": selectedMember,
      "loan_type_id": 1,
      "principal_amount": loanAmount,
      "interest_rate": double.parse(interest.text),
      "tenure_months": int.parse(tenure.text),
    };

    await LoanService().applyLoan(data);

    // Check if the user hasn't closed the screen manually while the API was loading
    if (!mounted) return;

    // Show success message first
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Loan Applied Successfully")),
    );

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      // This handles the case where it's embedded in your NavigationRail/HomeScreen
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  Future<void> loadMembers() async {
      members = await MemberService().getMembers("");
    setState(() {});
  }

  Future<void> loadLoanTypes() async {
    loanTypes = await LoanService().getLoanTypes();
    setState(() {
      selectedLoanType = 1;
      final selected = loanTypes.firstWhere((e) => e["id"] == 1);
      interest.text = selected["interest_rate"].toString();
      tenure.text = selected["tenure_months"].toString();
    });
  }

  void _showMemberEligibilityDetails() {
    if (selectedMember == null) return;

    final member = members.firstWhere((m) => m["id"] == selectedMember);

    // Calculate durations
    String membershipDuration = _calculateDuration(member['admission_date']);
    String serviceDuration = _calculateDuration(member['employment']['appointment_date']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Eligibility Check: ${member['member_name']}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.group_add, color: Colors.blue),
              title: const Text("Membership Duration"),
              subtitle: Text("Joined: ${member['admission_date']} \nDuration: $membershipDuration"),
              isThreeLine: true,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.work, color: Colors.orange),
              title: const Text("Service Duration"),
              subtitle: Text("Appointed: ${member['employment']['appointment_date']} \nTotal Service: $serviceDuration"),
              isThreeLine: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CLOSE")),
        ],
      ),
    );
  }

  String _calculateDuration(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "0y 0m";

    try {
      DateTime startDate = DateTime.parse(dateStr);
      DateTime now = DateTime.now();

      int years = now.year - startDate.year;
      int months = now.month - startDate.month;

      if (months < 0) {
        years--;
        months += 12;
      }

      // Adjust for days (if current day is before start day, subtract a month)
      if (now.day < startDate.day) {
        months--;
        if (months < 0) {
          years--;
          months += 11; // Use 11 because we already subtracted a month
        }
      }

      return "${years}y ${months}m";
    } catch (e) {
      return "Invalid Date";
    }
  }

  void _showMemberSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        List searchResults = [];
        return StatefulBuilder( // To update list inside dialog
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text("Search Member"),
                content: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        decoration: const InputDecoration(
                          hintText: "Enter Name, No, or Mobile...",
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (val) async {
                          if (val.length > 2) { // Search after 3 characters
                            final results = await MemberService().getMembers(val);
                            setDialogState(() => searchResults = results);
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: searchResults.length,
                          itemBuilder: (context, index) {
                            final m = searchResults[index];
                            return ListTile(
                              title: Text(m["member_name"]),
                              subtitle: Text("No: ${m['member_no']} | Mob: ${m['mobile']}"),
                              onTap: () {
                                Navigator.pop(context);
                                _onMemberSelected(m["id"]); // Trigger your logic
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
        );
      },
    );
  }

  void _clearLoanFields() {
    setState(() {
      salary.clear();
      amount.clear();
      tenure.clear();
      interest.clear();
      shareBalance.clear();
      tdBalance.clear();
      drsBalance.clear();
      totalAdjustment.clear();
      netAmountToPay.clear();
      surety1MemNo.clear();
      surety1MemName.clear();
      surety2MemNo.clear();
      surety2MemName.clear();
      isSurety1Valid = false;
      isSurety2Valid = false;
    });
  }

  void _onMemberSelected(int val) async {
    // 1. Clear everything before starting new fetch
    _clearLoanFields();

    setState(() {
      selectedMember = val;
      isCalculatingEligibility = true;
    });

    try {
      // Fetch basic details
      final results = await MemberService().getMembers(val.toString());
      if (results.isEmpty) throw Exception("Member details not found");
      final member = results.first;

      setState(() {
        salary.text = member["employment"]["salary_amount"].toString();
      });

      // Fetch Balances & Policy (The Sanction Amount)
      final balances = await MemberService().getBalances(val);
      final policy = await LoanService().getMemberPolicy(val);

      setState(() {
        amount.text = policy["eligible_sanction_amount"].toString();
        tenure.text = policy["eligible_max_tenure"].toString();
        interest.text = policy["interest_rate"].toString();
        shareBalance.text = balances["share_balance"].toString();
        tdBalance.text = balances["td_balance"].toString();
      });

      calculateNetPay();
    } catch (e) {
      // If it fails (e.g., Ineligible), fields stay empty and button stays disabled
      _showError(e.toString());
      _clearLoanFields();
    } finally {
      setState(() => isCalculatingEligibility = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F2F1), // Matching legacy background color
      appBar: AppBar(
        title: const Text("Ordinary Loan Processing"),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[100], // Background matching legacy screen
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Section 1: Member Header ---
                // Row(
                //   children: [
                //     Expanded(
                //       flex: 2,
                //       child: DropdownButtonFormField<int>(
                //         value: selectedMember,
                //         decoration: const InputDecoration(labelText: "Member Select", filled: true, fillColor: Colors.white),
                //         items: members.map<DropdownMenuItem<int>>((m) => DropdownMenuItem(value: m["id"], child: Text("${m['member_no']} - ${m['member_name']}"))).toList(),
                //         onChanged: (val) async {
                //           if (val != null) {
                //             final member = members.firstWhere((m) =>
                //             m["id"] == val);
                //             setState(() {
                //               selectedMember = val;
                //               salary.text = member["employment"]["salary_amount"]
                //                   .toString();
                //             });
                //             try {
                //               final policy = await LoanService().getMemberPolicy(
                //                   val);
                //               setState(() {
                //                 amount.text =
                //                     policy["eligible_sanction_amount"].toString();
                //                 tenure.text =
                //                     policy["eligible_max_tenure"].toString();
                //                 interest.text =
                //                     policy["interest_rate"].toString();
                //               });
                //               calculateNetPay();
                //             } catch (e) {
                //               _showError("Eligibility Check Failed: $e");
                //             }
                //             final balances = await MemberService().getBalances(
                //                 val);
                //             setState(() {
                //               shareBalance.text =
                //                   balances["share_balance"].toString();
                //               tdBalance.text = balances["td_balance"].toString();
                //             });
                //           }
                //         },
                //       ),
                //     ),
                //     IconButton(
                //       icon: const Icon(Icons.info_outline, color: Colors.blue),
                //       onPressed: _showMemberEligibilityDetails,
                //     ),
                //   ],
                // ),
                // --- Section 1: Member Selection (Searchable) ---
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: InkWell(
                        onTap: _showMemberSearchDialog, // Opens the searcher
                        child: IgnorePointer(
                          child: TextFormField(
                            controller: TextEditingController(
                                text: selectedMember != null
                                    ? "${members.firstWhere((m) => m['id'] == selectedMember)['member_no']} - ${members.firstWhere((m) => m['id'] == selectedMember)['member_name']}"
                                    : "Search Member (No, Name, Mobile...)"
                            ),
                            decoration: const InputDecoration(
                              labelText: "Select Member",
                              filled: true,
                              fillColor: Colors.white,
                              prefixIcon: Icon(Icons.search),
                            ),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.info_outline, color: Colors.blue),
                      onPressed: _showMemberEligibilityDetails,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // --- Section 2: Financial Information ---
                Row(
                  children: [
                    Expanded(child: _buildAlignedField("Monthly Salary", salary)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildAlignedField("Available Share", shareBalance)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildAlignedField("Available TD", tdBalance)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildAlignedField("Available DRS", drsBalance)),
                  ],
                ),

                const Divider(height: 32, thickness: 1.2, color: Colors.blueGrey),

                // --- Section 3: Loan Sanction Details ---
                const Text("Loan Sanction Details", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: amount,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: "Sanctioned Amt", filled: true, fillColor: Colors.white),
                        onChanged: (_) => calculateNetPay(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: _buildAlignedField("Period (Months)", tenure)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildAlignedField("Interest Rate %", interest)),
                  ],
                ),

                const SizedBox(height: 16),

                // --- Section 4: Surety & Adjustments ---
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: surety1MemNo,
                        decoration: InputDecoration(
                          labelText: "Surety 1 No",
                          filled: true, fillColor: Colors.white,
                          suffixIcon: isSurety1Valid ? const Icon(Icons.check_circle, color: Colors.green) : null,
                        ),
                        onChanged: (val) => _validateSurety(val, 1),
                      ),
                    ),
                    const SizedBox(width: 12), // Horizontal spacing
                    Expanded(
                      child: Stack( // ✅ Using Stack to put an info button inside/next to the name
                        alignment: Alignment.centerRight,
                        children: [
                          _buildResultField("Surety 1 Name", surety1MemName, Colors.green[800]!),
                          if (isSurety1Valid)
                            IconButton(
                              icon: const Icon(Icons.visibility, color: Colors.blue),
                              onPressed: () => _viewMemberDetails(surety1MemNo.text),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: surety2MemNo,
                        decoration: InputDecoration(
                          labelText: "Surety 2 No",
                          filled: true, fillColor: Colors.white,
                          suffixIcon: isSurety2Valid ? const Icon(Icons.check_circle, color: Colors.green) : null,
                        ),
                        onChanged: (val) => _validateSurety(val, 2),
                      ),
                    ),
                    const SizedBox(width: 12), // Horizontal spacing
                    Expanded(
                      child: Stack( // ✅ Using Stack to put an info button inside/next to the name
                        alignment: Alignment.centerRight,
                        children: [
                          _buildResultField("Surety 2 Name", surety2MemName, Colors.green[800]!),
                          if (isSurety2Valid)
                            IconButton(
                              icon: const Icon(Icons.visibility, color: Colors.blue),
                              onPressed: () => _viewMemberDetails(surety2MemNo.text),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                // PREVIOUS LOAN DETAILS ROW
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.blueGrey[50],
                  child: Column(
                    children: [
                      Row( // ✅ Wrapping these in a Row to put them side-by-side
                        children: [
                          Expanded(
                            child: _buildResultField("Pre. Loan Date", preLoanDate, Colors.red[700]!),
                          ),
                          const SizedBox(width: 12), // Horizontal spacing
                          Expanded(
                            child: _buildResultField("Pre. Interest %", preInterest, Colors.green[800]!),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),
                // --- Section 5: Final Net Pay Calculation ---
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.blueGrey[50],
                  child: Column(
                    children: [
                  Row( // ✅ Wrapping these in a Row to put them side-by-side
                  children: [
                  Expanded(
                  child:_buildResultField("Total Adjustment (-)", totalAdjustment, Colors.red[700]!)),
                    const SizedBox(width: 12), // Horizontal spacing
                Expanded(
                  child:_buildResultField("NET AMOUNT TO PAY", netAmountToPay, Colors.green[800]!)),
                    ],
                )]
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    // ✅ Button is disabled if loading OR if amount is not set
                    onPressed: (isCalculatingEligibility || amount.text.isEmpty)
                        ? null
                        : () => applyLoan(),
                    child: isCalculatingEligibility
                        ? const CircularProgressIndicator(color: Colors.white) // Show loader inside button
                        : const Text("SAVE LOAN RECORD",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _viewMemberDetails(String memberNo) async {
    try {
      final List<dynamic> results = await MemberService().getMembers(memberNo);
      if (results.isNotEmpty) {
        final member = results.first;

        // 2. IMPORTANT: Fetch the latest balances for the Surety
        final balances = await MemberService().getBalances(member["id"]);

        // 3. Merge balances into the member map so the View Screen can see them
        member["share_balance"] = balances["share_balance"];
        member["td_balance"] = balances["td_balance"];

        // Show as a Popup (Dialog)
        showDialog(
          context: context,
          builder: (context) => Dialog(
            insetPadding: const EdgeInsets.all(20),
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.8,
              child: MemberViewScreen(member: member),
            ),
          ),
        );
      }
    } catch (e) {
      _showError("Could not load details: $e");
    }
  }

// Reusable Aligned Field Helper
  Widget _buildAlignedField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Future<void> _validateSurety(String memberNo, int suretyNumber) async {
    if (memberNo.isEmpty) {
      setState(() {
        if (suretyNumber == 1) isSurety1Valid = false;
        if (suretyNumber == 2) isSurety2Valid = false;
      });
      return;
    }

    try {
      final List<dynamic> memberResults = await MemberService().getMembers(
          memberNo);

      if (memberResults.isEmpty ||
          memberResults.first["status"].toString() != "APPROVED") {
        setState(() {
          if (suretyNumber == 1) isSurety1Valid = false;
          if (suretyNumber == 2) isSurety2Valid = false;
        });
        _showError("Surety not found or not approved.");
        return;
      }

      final Map<String, dynamic> member = memberResults.first;
      int activeSuretyCount = int.tryParse(
          member["active_surety_count"].toString()) ?? 0;

      if (activeSuretyCount >= 2) {
        setState(() {
          if (suretyNumber == 1) isSurety1Valid = false;
          if (suretyNumber == 2) isSurety2Valid = false;
        });
        _showError("Member has already provided 2 sureties.");
        return;
      }

      setState(() {
        if (suretyNumber == 1) {
          isSurety1Valid = true;
          surety1MemName.text = member["member_name"];
        }
        if (suretyNumber == 2) {
          isSurety2Valid = true;
          surety2MemName.text = member["member_name"];
        }
      });
    } catch (e) {
      setState(() {
        if (suretyNumber == 1) isSurety1Valid = false;
        if (suretyNumber == 2) isSurety2Valid = false;
      });
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _buildResultField(String label, TextEditingController ctrl, Color color) {
    return TextField(
      controller: ctrl,
      readOnly: true,
      style: TextStyle(fontWeight: FontWeight.bold, color: color),
      decoration: InputDecoration(labelText: label, filled: true),
    );
  }
}