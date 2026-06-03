import 'package:flutter/material.dart';
import '../service/member_service.dart';
import '../service/receipt_service.dart';
import '../utils/app_colors.dart';

class ReceiptScreen extends StatefulWidget {
  final Map? receipt;

  /// Called after a successful create or update.
  /// When embedded in HomeScreen, HomeScreen passes this to trigger list refresh.
  /// When navigated to standalone, onSaved is null and Navigator.pop is used instead.
  final VoidCallback? onSaved;

  const ReceiptScreen({super.key, this.receipt, this.onSaved});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  final _formKey = GlobalKey<FormState>();

  final _amountCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  final _narrationCtrl = TextEditingController();

  List _members = [];
  List _accounts = [];

  int? _selectedMember;
  int? _selectedAccount;
  String _paymentMode = "CASH";
  DateTime _receiptDate = DateTime.now();

  bool _isInitialising = true;
  bool _isLoadingAccounts = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _memberLoadError;

  bool get _isEdit => widget.receipt != null;

  static const List<String> _paymentModes = ["CASH", "BANK", "UPI", "ONLINE"];

  @override
  void initState() {
    super.initState();
    _initialise();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _refCtrl.dispose();
    _narrationCtrl.dispose();
    super.dispose();
  }

  Future<void> _reloadMembers() async {
    if (!mounted) return;
    setState(() { _memberLoadError = null; _members = []; });
    try {
      final raw = await MemberService().getMembers("");
      if (!mounted) return;
      if (raw is List) {
        setState(() => _members = raw);
      } else {
        setState(() => _memberLoadError =
            "Server returned an unexpected response. Make sure you are logged in.");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _memberLoadError = "Failed to load members — ${e.toString().replaceFirst(RegExp(r'^Exception: '), '')}");
    }
  }

  Future<void> _initialise() async {
    setState(() { _isInitialising = true; _memberLoadError = null; });
    try {
      final raw = await MemberService().getMembers("");
      if (raw is List) {
        _members = raw;
      } else {
        _members = [];
        _memberLoadError = "Could not load members. Server returned an unexpected response — you may need to log in again.";
      }
    } catch (e) {
      _members = [];
      _memberLoadError = "Failed to load members: ${e.toString().replaceFirst(RegExp(r'^Exception: '), '')}";
    }

    if (widget.receipt != null) {
      final r = widget.receipt!;
      _selectedMember = r["member_id"] as int?;

      if (_selectedMember != null) {
        await _loadAccounts(_selectedMember!);
      }

      try {
        _receiptDate = DateTime.parse(r["receipt_date"] ?? "");
      } catch (_) {
        _receiptDate = DateTime.now();
      }

      _selectedAccount = r["account_id"] as int?;
      _paymentMode = r["payment_mode"] ?? "CASH";
      _amountCtrl.text = r["amount"]?.toString() ?? "";
      _refCtrl.text = r["reference_no"] ?? "";
      _narrationCtrl.text = r["narration"] ?? "";
    }

    if (mounted) setState(() => _isInitialising = false);
  }

  Future<void> _loadAccounts(int memberId) async {
    if (!mounted) return;
    setState(() {
      _isLoadingAccounts = true;
      _accounts = [];
    });
    try {
      final result = await MemberService().getAccounts(memberId);
      if (!mounted) return;
      _accounts = result ?? [];
    } catch (_) {
      if (!mounted) return;
      _accounts = [];
    } finally {
      if (mounted) setState(() => _isLoadingAccounts = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _receiptDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _receiptDate = picked);
    }
  }

  String _displayDate(DateTime dt) =>
      "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";

  String _apiDate(DateTime dt) =>
      "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";

  Future<void> _save() async {
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = "Amount must be greater than zero.");
      return;
    }

    setState(() => _isSaving = true);

    final payload = {
      "receipt_date": _apiDate(_receiptDate),
      "member_id": _selectedMember,
      "account_id": _selectedAccount,
      "amount": amount.toStringAsFixed(2),
      "payment_mode": _paymentMode,
      "reference_no": _refCtrl.text.trim().isEmpty ? null : _refCtrl.text.trim(),
      "narration": _narrationCtrl.text.trim().isEmpty ? null : _narrationCtrl.text.trim(),
    };

    try {
      if (!_isEdit) {
        await ReceiptService().createReceipt(payload);
      } else {
        await ReceiptService().updateReceipt(widget.receipt!["id"] as int, payload);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isEdit ? "Receipt updated successfully." : "Receipt created successfully."),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ));

      if (widget.onSaved != null) {
        setState(() => _isSaving = false);
        widget.onSaved!();
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst(RegExp(r'^Exception: '), '');
      setState(() {
        _isSaving = false;
        _errorMessage = msg;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialising) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? "Edit Receipt" : "New Receipt"),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // ── INFO BANNER (edit mode) ──────────────────────────────
              if (_isEdit) _buildInfoBanner(),

              // ── RECEIPT DATE ─────────────────────────────────────────
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(4),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: "Receipt Date *",
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today, size: 20),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  child: Text(_displayDate(_receiptDate)),
                ),
              ),
              const SizedBox(height: 14),

              // ── MEMBER ───────────────────────────────────────────────
              _buildMemberField(),
              const SizedBox(height: 14),

              // ── ACCOUNT ──────────────────────────────────────────────
              _buildAccountField(),
              const SizedBox(height: 14),

              // ── AMOUNT ───────────────────────────────────────────────
              TextFormField(
                controller: _amountCtrl,
                decoration: const InputDecoration(
                  labelText: "Amount *",
                  prefixText: "₹ ",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return "Amount is required";
                  final d = double.tryParse(v.trim());
                  if (d == null) return "Enter a valid number";
                  if (d <= 0) return "Amount must be greater than zero";
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // ── PAYMENT MODE ─────────────────────────────────────────
              DropdownButtonFormField<String>(
                value: _paymentMode,
                decoration: const InputDecoration(
                  labelText: "Payment Mode *",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                items: _paymentModes.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _paymentMode = val);
                },
                validator: (v) => v == null ? "Select a payment mode" : null,
              ),
              const SizedBox(height: 14),

              // ── REFERENCE NO ─────────────────────────────────────────
              TextFormField(
                controller: _refCtrl,
                decoration: const InputDecoration(
                  labelText: "Reference No (Cheque / UTR)",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
              ),
              const SizedBox(height: 14),

              // ── NARRATION ────────────────────────────────────────────
              TextFormField(
                controller: _narrationCtrl,
                decoration: const InputDecoration(
                  labelText: "Narration",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 20),

              // ── ERROR ────────────────────────────────────────────────
              if (_errorMessage != null) _buildErrorBox(_errorMessage!),

              // ── SAVE BUTTON ──────────────────────────────────────────
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
                  ),
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : Text(
                          _isEdit ? "UPDATE RECEIPT" : "SAVE RECEIPT",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── HELPERS ────────────────────────────────────────────────────────────────

  Widget _buildInfoBanner() {
    final r = widget.receipt!;
    final receiptNo = r["receipt_no"]?.toString() ?? "";
    final status = r["status"]?.toString() ?? "POSTED";
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long, color: AppColors.primary, size: 22),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(receiptNo,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)),
              const SizedBox(height: 2),
              Text("Status: $status",
                  style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMemberField() {
    // Member is read-only on edit — backend forbids changing it
    if (_isEdit) {
      final name = widget.receipt?["member_name"]?.toString() ??
          "Member #${widget.receipt?["member_id"]}";
      return InputDecorator(
        decoration: InputDecoration(
          labelText: "Member",
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          filled: true,
          fillColor: AppColors.grey_200,
          suffixIcon: Tooltip(
            message: "Member cannot be changed on an existing receipt.",
            child: const Icon(Icons.lock_outline, size: 18, color: AppColors.textLight),
          ),
        ),
        child: Text(name, style: const TextStyle(fontSize: 14)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Error banner shown when member load failed
        if (_memberLoadError != null)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_memberLoadError!,
                      style: TextStyle(color: AppColors.error, fontSize: 12)),
                ),
                TextButton.icon(
                  onPressed: _reloadMembers,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text("Retry", style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),

        DropdownButtonFormField<int>(
          value: _selectedMember,
          decoration: InputDecoration(
            labelText: "Member *",
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            suffixIcon: _members.isEmpty && _memberLoadError == null
                ? const SizedBox(
                    width: 20, height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(14),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
          isExpanded: true,
          hint: _members.isEmpty
              ? Text(_memberLoadError != null ? "No members loaded" : "Loading...",
                  style: const TextStyle(color: AppColors.textLight))
              : null,
          items: _members.map<DropdownMenuItem<int>>((m) {
            return DropdownMenuItem<int>(
              value: m["id"] as int,
              child: Text(m["member_name"]?.toString() ?? "", overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: _members.isEmpty ? null : (val) {
            setState(() {
              _selectedMember = val;
              _selectedAccount = null;
              _accounts = [];
            });
            if (val != null) _loadAccounts(val);
          },
          validator: (v) => v == null ? "Please select a member" : null,
        ),
      ],
    );
  }

  Widget _buildAccountField() {
    if (_isLoadingAccounts) {
      return const SizedBox(
        height: 56,
        child: Center(child: LinearProgressIndicator()),
      );
    }
    return DropdownButtonFormField<int?>(
      value: _selectedAccount,
      decoration: const InputDecoration(
        labelText: "Account (optional)",
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      isExpanded: true,
      items: [
        const DropdownMenuItem<int?>(value: null, child: Text("— None —")),
        ..._accounts.map<DropdownMenuItem<int?>>((a) {
          return DropdownMenuItem<int?>(
            value: a["id"] as int,
            child: Text(a["account_number"]?.toString() ?? "", overflow: TextOverflow.ellipsis),
          );
        }),
      ],
      onChanged: (val) => setState(() => _selectedAccount = val),
    );
  }

  Widget _buildErrorBox(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: TextStyle(color: AppColors.error, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
