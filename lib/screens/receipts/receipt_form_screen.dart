import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../service/receipt_service.dart';
import '../../utils/receipt_format_utils.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  GRID LINE ITEM  (one account entry per row, legacy supports multiple rows)
// ═══════════════════════════════════════════════════════════════════════════════

class _GridLine {
  int? accountId;
  String accountDesc;
  final TextEditingController refCtrl;
  final TextEditingController amtCtrl;

  _GridLine({this.accountId, this.accountDesc = ''})
    : refCtrl = TextEditingController(),
      amtCtrl = TextEditingController();

  void dispose() {
    refCtrl.dispose();
    amtCtrl.dispose();
  }

  double get parsedAmount {
    final s = amtCtrl.text
        .trim()
        .replaceAll(',', '')
        .replaceAll('₹', '')
        .replaceAll('Rs.', '');
    return double.tryParse(s) ?? 0.0;
  }

  bool get hasData => amtCtrl.text.trim().isNotEmpty || accountId != null;
}

// ═══════════════════════════════════════════════════════════════════════════════
//  RECEIPT MANAGEMENT SCREEN
//  Classic desktop-style combined form + navigation, matching the legacy UI.
// ═══════════════════════════════════════════════════════════════════════════════

class ReceiptFormScreen extends StatefulWidget {
  final Map? receipt;
  final VoidCallback? onSaved;

  const ReceiptFormScreen({super.key, this.receipt, this.onSaved});

  @override
  State<ReceiptFormScreen> createState() => _ReceiptFormScreenState();
}

enum _Mode { view, add, change }

class _ReceiptFormScreenState extends State<ReceiptFormScreen> {
  // ── Controllers ──────────────────────────────────────────────────────────────
  final _receiptNoCtrl = TextEditingController();
  final _maxAmountCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _drawnOnCtrl = TextEditingController();
  final _chequeNoCtrl = TextEditingController();
  final _chequeDtCtrl = TextEditingController();
  final _depositedInCtrl = TextEditingController();
  final _memberSearchCtrl = TextEditingController();
  final _pdoNoCtrl = TextEditingController(); // PDO code (01001, 07001…)
  final _utrCtrl = TextEditingController(); // UPI/NEFT transaction ref / UTR no
  // Grid lines managed via _GridLine list below
  Timer? _memberDebounce;
  // E02: date label controller
  final _dateLabelCtrl = TextEditingController();

  // ── Data ─────────────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _receipts = [];
  int _currentIdx = -1;

  // ── Mode ─────────────────────────────────────────────────────────────────────
  _Mode _mode = _Mode.view;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMsg;

  // ── Form state ────────────────────────────────────────────────────────────────
  String _receivedFrom = 'Member';
  // E01: replaced _isChequeDD bool with _paymentMode string
  String _paymentMode = 'CASH';
  DateTime _receiptDate = DateTime.now();
  // E04: cheque date state
  DateTime? _chequeDate;

  // ── Member ────────────────────────────────────────────────────────────────────
  int? _memberId;
  String? _memberNo; // member number shown alongside name (from legacy)
  // E08: editing receipt id
  int? _editingId;
  String? _memberName;
  List<Map<String, dynamic>> _memberResults = [];
  List<Map<String, dynamic>> _ledgers = []; // from ledgers table
  bool _isMemberSearching = false;

  // ── Grid (multi-line, matches legacy behaviour) ───────────────────────────────
  final List<_GridLine> _lines = [_GridLine()]; // start with one empty line
  int _activeRow = 0;

  // ── Extra state ───────────────────────────────────────────────────────────────
  // E09: print lock
  bool _isPrinting = false;
  // E15: ledger load error
  String? _ledgerLoadError;
  // E25: cached ledger dropdown items
  List<DropdownMenuItem<int?>>? _ledgerItems;
  // E29: generation counter — discards stale search responses when user types fast
  int _searchGen = 0;

  // ── Computed ─────────────────────────────────────────────────────────────────
  // E01: computed getter for backward compat
  bool get _isChequeDD => _paymentMode == 'BANK';
  bool get _isUpiNeft => _paymentMode == 'UPI' || _paymentMode == 'NEFT';

  // User-selectable payment modes (ADJ is system-only, not in this list)
  static const _kPayModes = ['CASH', 'BANK', 'UPI', 'NEFT', 'OTHERS'];

  String get _pmDisplayLabel => const {
    'CASH': 'Cash',
    'BANK': 'Bank (Cheque/DD)',
    'UPI': 'UPI',
    'NEFT': 'NEFT',
    'OTHERS': 'Others',
    'ADJ': 'Adjustment',
  }[_paymentMode] ?? _paymentMode;
  // Convenience access to first line (used in single-line fallback paths)
  int? get _selectedAccountId => _lines.isNotEmpty ? _lines[0].accountId : null;
  String get _gridAcctDesc => _lines.isNotEmpty ? _lines[0].accountDesc : '';
  double get _totalAmount => _lines.fold(0.0, (s, l) => s + l.parsedAmount);
  bool get _isEditMode => _mode != _Mode.view;
  Map<String, dynamic>? get _current =>
      _currentIdx >= 0 && _currentIdx < _receipts.length
          ? _receipts[_currentIdx]
          : null;
  bool get _isLocked   => _current?['status'] == 'LOCKED';
  bool get _isReversed => _current?['status'] == 'REVERSED';
  // E17: isBusy getter
  bool get _isBusy => _isSaving || _isPrinting;

  // ── Palette (modern) ─────────────────────────────────────────────────────────
  static const _bg = Color(0xFFF0F4F8);
  static const _panelBg = Colors.white;
  static const _border = Color(0xFFCBD5E1);
  static const _inputBg = Colors.white;
  static const _btnBg = Color(0xFFF1F5F9);
  static const _gridHdr = Color(0xFFECF3F7);
  static const _receiptNoYellow = Color(0xFFFFFBEB);
  static const _primary = Color(0xFF00789B);
  static const _sectionAccent = Color(0xFF0D3B5E);
  static const _titleGrad1 = Color(0xFF003D52);
  static const _titleGrad2 = Color(0xFF00789B);
  // E42: society name constant
  static const _kSocietyName =
      'L&T GROUP EMPLOYEES COOPERATIVE THRIFT & CREDIT SOCIETY LTD';

  // ═══ LIFECYCLE ════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    // E02: initialise date label
    _dateLabelCtrl.text = _dispDate(_receiptDate);
    // E19: load ledgers first, then receipts
    _loadLedgers().then((_) => _loadReceipts());
  }

  @override
  void dispose() {
    _receiptNoCtrl.dispose();
    _maxAmountCtrl.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _drawnOnCtrl.dispose();
    _chequeNoCtrl.dispose();
    _chequeDtCtrl.dispose();
    _depositedInCtrl.dispose();
    _memberSearchCtrl.dispose();
    _pdoNoCtrl.dispose();
    _utrCtrl.dispose();
    for (final l in _lines) l.dispose();
    _memberDebounce?.cancel();
    // E02: dispose date label controller
    _dateLabelCtrl.dispose();
    super.dispose();
  }

  // ═══ DATA ═════════════════════════════════════════════════════════════════════

  Future<void> _loadReceipts() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    try {
      final list = await ReceiptService().getReceipts();
      if (!mounted) return;
      setState(() {
        _receipts = list;
        _isLoading = false;
      });
      if (widget.receipt != null) {
        final id = widget.receipt!['id'] as int?;
        final idx = _receipts.indexWhere((r) => r['id'] == id);
        if (idx >= 0) {
          _navigateTo(idx);
        } else {
          _receipts.insert(0, Map<String, dynamic>.from(widget.receipt!));
          _navigateTo(0);
        }
      } else if (_receipts.isNotEmpty) {
        _navigateTo(_receipts.length - 1); // start at most recent
      } else {
        _clearForm();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        // E34: improved error message with retry hint
        _errorMsg =
            '${e.toString().replaceFirst(RegExp(r'^Exception: '), '')} Tap Retry to try again.';
      });
    }
  }

  Future<void> _loadLedgers() async {
    try {
      final list = await ReceiptService().getLedgers();
      if (!mounted) return;
      setState(() {
        _ledgers = list;
        // E15: clear error on success
        _ledgerLoadError = null;
        // E25: build cached items
        _ledgerItems = [
          const DropdownMenuItem<int?>(
            value: null,
            child: Text('— None —', style: TextStyle(fontSize: 12)),
          ),
          ..._ledgers.map(
            (l) => DropdownMenuItem<int?>(
              value: l['id'] as int,
              child: Text(
                l['name']?.toString() ?? 'Ledger #${l["id"]}',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ];
        // Upgrade placeholder names once ledgers are loaded
        for (final line in _lines) {
          if (line.accountId != null &&
              (line.accountDesc.isEmpty ||
                  line.accountDesc.startsWith('Account #'))) {
            final l = list.firstWhere(
              (l) => l['id']?.toString() == line.accountId.toString(),
              orElse: () => {},
            );
            final name = l['name']?.toString();
            if (name != null && name.isNotEmpty) line.accountDesc = name;
          }
        }
      });
    } catch (e) {
      // E15: track ledger load error
      if (!mounted) return;
      setState(
        () => _ledgerLoadError = 'Failed to load accounts. Tap to retry.',
      );
    }
  }

  Future<void> _navigateTo(int idx) async {
    if (idx < 0 || idx >= _receipts.length) return;
    setState(() {
      _currentIdx = idx;
      _errorMsg = null;
    });
    _populate(_receipts[idx]); // instant populate from list data
    // Silently fetch full detail so account_id / items are available
    final id = _receipts[idx]['id'] as int?;
    if (id == null) return;
    try {
      final detail = await ReceiptService().getReceiptById(id);
      if (!mounted || _currentIdx != idx) return;
      _receipts[idx] = detail;
      if (_mode == _Mode.view) _populate(detail);
    } catch (_) {
      // Keep list data — detail fetch is best-effort
    }
  }

  void _populate(Map<String, dynamic> r) {
    // Normalize backend values to exact dropdown keys (case-insensitive guard)
    final pm =
        const {
          'cash': 'CASH',
          'bank': 'BANK',
          'upi': 'UPI',
          'online': 'UPI', // legacy — map to UPI
          'neft': 'NEFT',
          'others': 'OTHERS',
          'other': 'OTHERS',
          'adj': 'ADJ',
          'adjustment': 'ADJ',
        }[r['payment_mode']?.toString().toLowerCase() ?? ''] ??
        r['payment_mode']?.toString() ??
        'CASH';
    final fromRaw = r['received_from']?.toString().toLowerCase() ?? '';
    final receivedFrom =
        const {'member': 'Member', 'pdo': 'PDO', 'others': 'Others'}[fromRaw] ??
        'Member'; // always a valid dropdown value
    // Robust account_id parsing — backend may return int or string
    final acctId =
        r['account_id'] != null
            ? int.tryParse(r['account_id'].toString())
            : null;

    // Resolve ledger name — use string comparison so int/string type mismatch never fails
    String acctDesc = '';
    if (acctId != null) {
      final l = _ledgers.firstWhere(
        (l) => l['id']?.toString() == acctId.toString(),
        orElse: () => {},
      );
      acctDesc =
          l['name']?.toString() ??
          r['account_description']?.toString() ??
          r['account_name']?.toString() ??
          r['account_type']?.toString() ??
          'Account #$acctId';
    }

    setState(() {
      // E01: use _paymentMode (normalized above)
      _paymentMode = pm;
      _receivedFrom = receivedFrom;
      _memberId = r['member_id'] as int?;
      _memberName = r['member_name'] as String?;
      _memberNo = r['member_no']?.toString();
      _memberSearchCtrl.clear();
      _memberResults = [];
      try {
        _receiptDate = DateTime.parse(r['receipt_date'] ?? '');
      } catch (_) {
        _receiptDate = DateTime.now();
      }
      _dateLabelCtrl.text = _dispDate(_receiptDate);

      // E04: parse cheque date
      try {
        final cd = r['cheque_date']?.toString() ?? '';
        _chequeDate = cd.isNotEmpty ? DateTime.parse(cd) : null;
        _chequeDtCtrl.text =
            _chequeDate != null
                ? _dispDate(_chequeDate!)
                : (r['cheque_date'] ?? '');
      } catch (_) {
        _chequeDate = null;
      }

      _receiptNoCtrl.text = r['receipt_no']?.toString() ?? '';
      _nameCtrl.text = r['member_name']?.toString() ?? '';
      _descCtrl.text =
          r['narration']?.toString() ?? r['description']?.toString() ?? '';
      _drawnOnCtrl.text =
          r['drawn_on']?.toString() ?? r['bank_name']?.toString() ?? '';
      _chequeNoCtrl.text =
          r['reference_no']?.toString() ?? r['cheque_no']?.toString() ?? '';
      _depositedInCtrl.text =
          r['deposited_in']?.toString() ??
          r['deposit_account']?.toString() ??
          '';
      _maxAmountCtrl.text = r['max_amount']?.toString() ?? '';
      _pdoNoCtrl.text = r['pdo_no']?.toString() ?? '';
      // UTR: populated for UPI/NEFT; reference_no carries it from backend
      final isUpiNeft = pm == 'UPI' || pm == 'NEFT';
      _utrCtrl.text = isUpiNeft ? (r['reference_no']?.toString() ?? '') : '';
      _activeRow = 0;

      // ── Load grid line items ────────────────────────────────────────────────
      for (final l in _lines) l.dispose();
      _lines.clear();

      // Backend returns items array (multi-line) or single account (legacy compat)
      final rawItems = r['items'];
      if (rawItems is List && rawItems.isNotEmpty) {
        for (final item in rawItems) {
          final line = _GridLine();
          line.accountId =
              item['account_id'] != null
                  ? int.tryParse(item['account_id'].toString())
                  : null;
          line.amtCtrl.text = item['amount']?.toString() ?? '';
          line.refCtrl.text =
              item['ref_no']?.toString() ??
              item['reference_no']?.toString() ??
              '';
          if (line.accountId != null) {
            final l2 = _ledgers.firstWhere(
              (l2) => l2['id']?.toString() == line.accountId.toString(),
              orElse: () => {},
            );
            line.accountDesc =
                l2['name']?.toString() ??
                item['account_name']?.toString() ??
                item['account_description']?.toString() ??
                'Account #${line.accountId}';
          }
          _lines.add(line);
        }
      } else {
        // Single-account fallback
        final line = _GridLine();
        line.accountId = acctId;
        line.accountDesc = acctDesc;
        line.amtCtrl.text = r['amount']?.toString() ?? '';
        line.refCtrl.text = r['reference_no']?.toString() ?? '';
        _lines.add(line);
      }
      // Always keep at least one blank entry row for editing
      _lines.add(_GridLine());
    });
  }

  // E06: All mutations inside setState; E01 / E02 / E04 / E07 / E08 / E15 applied
  void _clearForm() {
    setState(() {
      _paymentMode = 'CASH';
      _receivedFrom = 'Member';
      _receiptDate = DateTime.now();
      _chequeDate = null;
      _memberId = null;
      _memberName = null;
      _editingId = null;
      _ledgerLoadError = null;
      _memberSearchCtrl.clear();
      _pdoNoCtrl.clear();
      _memberResults = [];
      _memberNo = null;
      _receiptNoCtrl.clear();
      _nameCtrl.clear();
      _descCtrl.clear();
      _drawnOnCtrl.clear();
      _chequeNoCtrl.clear();
      _chequeDtCtrl.clear();
      _depositedInCtrl.clear();
      _utrCtrl.clear();
      _maxAmountCtrl.clear();
      _activeRow = 0;
      for (final l in _lines) l.dispose();
      _lines
        ..clear()
        ..add(_GridLine());
      _dateLabelCtrl.text = _dispDate(DateTime.now());
    });
  }

  // ═══ MEMBER SEARCH ════════════════════════════════════════════════════════════

  void _onMemberSearchChanged(String q) {
    _memberDebounce?.cancel();
    if (q.length < 2) {
      setState(() {
        _memberResults = [];
        _isMemberSearching = false;
      });
      return;
    }
    setState(() => _isMemberSearching = true);
    final gen = ++_searchGen;
    _memberDebounce = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted) return;
      final results = await ReceiptService().searchMembers(q);
      if (!mounted || gen != _searchGen) return;
      setState(() {
        _memberResults = results;
        _isMemberSearching = false;
      });
    });
  }

  void _selectMember(Map<String, dynamic> m) {
    final id = m['id'] as int;
    final name = m['member_name']?.toString() ?? 'Member #$id';
    final no = m['member_no']?.toString();
    setState(() {
      _memberId = id;
      _memberName = name;
      _memberNo = no;
      _nameCtrl.text = name;
      _memberSearchCtrl.clear();
      _memberResults = [];
      // Clear first line's account when member changes
      if (_lines.isNotEmpty) {
        _lines[0].accountId = null;
        _lines[0].accountDesc = '';
      }
    });
  }

  // ═══ ACTIONS ══════════════════════════════════════════════════════════════════

  void _doAdd() {
    setState(() {
      _mode = _Mode.add;
      _currentIdx = -1;
    });
    _clearForm();
  }

  void _doChange() {
    if (_current == null) {
      _showMsg('No receipt selected.');
      return;
    }
    if (_isLocked) {
      _showMsg('This receipt is LOCKED and cannot be changed.');
      return;
    }
    // E08: capture editing id
    _editingId = _current?['id'] as int?;
    setState(() => _mode = _Mode.change);
  }

  Future<void> _doDelete() async {
    // E03: capture id BEFORE showDialog
    if (_current == null) {
      _showMsg('No receipt selected.');
      return;
    }
    if (_isLocked) {
      _showMsg('This receipt is LOCKED and cannot be deleted.');
      return;
    }
    final id = _current?['id'] as int?;
    if (id == null) {
      _showMsg('No receipt selected.');
      return;
    }
    final no = _receiptNoCtrl.text.isNotEmpty ? _receiptNoCtrl.text : '#$id';
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Delete Receipt'),
            content: Text('Delete receipt $no? This cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
    if (ok != true || !mounted) return;
    setState(() {
      _isSaving = true;
      _errorMsg = null;
    });
    try {
      await ReceiptService().deleteReceipt(id);
      if (!mounted) return;
      _showMsg('Receipt $no deleted.', ok: true);
      await _loadReceipts();
      if (!mounted) return;
      setState(() {
        _mode = _Mode.view;
        _isSaving = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMsg = e.toString().replaceFirst(RegExp(r'^Exception: '), '');
      });
    }
  }

  Future<void> _doSave() async {
    if (!_validate()) return;

    // ── Confirm before creating a new receipt ────────────────────────────────
    // Prevents accidental saves when data was auto-populated (e.g. Retrieve Values)
    if (_mode == _Mode.add) {
      final payer = _memberName ?? _nameCtrl.text.trim();
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          actionsPadding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.receipt_long_rounded, color: _primary, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('Confirm New Receipt',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Divider(height: 16),
              _confirmRow(Icons.person_outline_rounded, 'Payer', payer.isNotEmpty ? payer : '—'),
              const SizedBox(height: 6),
              _confirmRow(Icons.payments_outlined, 'Amount',
                  _fmtAmt(_totalAmount.toStringAsFixed(2))),
              const SizedBox(height: 6),
              _confirmRow(Icons.credit_card_outlined, 'Payment Mode', _pmDisplayLabel),
              const SizedBox(height: 6),
              _confirmRow(Icons.calendar_today_outlined, 'Date', _dateLabelCtrl.text),
              const Divider(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
                ),
                child: const Row(children: [
                  Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFB45309)),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text('This will create a permanent new receipt.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF92400E))),
                  ),
                ]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.save_rounded, size: 15),
              label: const Text('Create Receipt'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    setState(() {
      _isSaving = true;
      _errorMsg = null;
    });

    final narr = _descCtrl.text.trim();
    final pm = _paymentMode;

    // Build multi-line items (only non-zero rows)
    final filledLines = _lines.where((l) => l.parsedAmount > 0).toList();
    final items =
        filledLines
            .map(
              (l) => <String, dynamic>{
                if (l.accountId != null) 'account_id': l.accountId,
                'amount': l.parsedAmount.toStringAsFixed(2),
                if (l.refCtrl.text.trim().isNotEmpty)
                  'ref_no': l.refCtrl.text.trim(),
              },
            )
            .toList();
    final totalAmt = _totalAmount;

    // Single-account/amount fields kept for backward compat with old backend
    final firstLine = filledLines.isNotEmpty ? filledLines.first : null;

    final payload = <String, dynamic>{
      'receipt_date': _apiDate(_receiptDate),
      if (_memberId != null) 'member_id': _memberId,
      // PDO: send company name + PDO code; Others: send name
      if (_receivedFrom != 'Member' && _nameCtrl.text.trim().isNotEmpty)
        'member_name': _nameCtrl.text.trim(),
      if (_receivedFrom == 'PDO' && _pdoNoCtrl.text.trim().isNotEmpty)
        'pdo_no': _pdoNoCtrl.text.trim(),
      if (firstLine?.accountId != null) 'account_id': firstLine!.accountId,
      'amount': totalAmt.toStringAsFixed(2),
      'payment_mode': pm,
      'received_from': _receivedFrom,
      if (narr.isNotEmpty) 'narration': narr,
      // Multi-line items array (backend should store via receipt_items table)
      'items': items,
      if (_isChequeDD) ...{
        'reference_no': _chequeNoCtrl.text.trim(),
        'drawn_on': _drawnOnCtrl.text.trim(),
        if (_chequeDate != null) 'cheque_date': _apiDate(_chequeDate!),
        'deposited_in': _depositedInCtrl.text.trim(),
      } else if (_isUpiNeft && _utrCtrl.text.trim().isNotEmpty)
        'reference_no': _utrCtrl.text.trim()
      else if (firstLine != null && firstLine.refCtrl.text.trim().isNotEmpty)
        'reference_no': firstLine.refCtrl.text.trim(),
    };

    try {
      final Map<String, dynamic> saved;
      if (_mode == _Mode.add) {
        saved = await ReceiptService().createReceipt(payload);
      } else {
        // E08: guard against lost id
        if (_editingId == null) {
          setState(() {
            _isSaving = false;
            _errorMsg = 'Receipt id lost. Cancel and try again.';
          });
          return;
        }
        saved = await ReceiptService().updateReceipt(_editingId!, payload);
      }
      if (!mounted) return;

      final rNo = saved['receipt_no']?.toString() ?? '';
      final balance = saved['account_balance'];
      String msg = rNo.isNotEmpty ? 'Receipt $rNo saved.' : 'Receipt saved.';
      if (balance != null) msg += '  Balance: ${_fmtAmt(balance)}';
      _showMsg(msg, ok: true);

      await _loadReceipts();
      if (!mounted) return;
      setState(() {
        _mode = _Mode.view;
        _isSaving = false;
      });
      widget.onSaved?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMsg = e.toString().replaceFirst(RegExp(r'^Exception: '), '');
      });
    }
  }

  // Reverse: creates a reversal receipt for a mistake. Standard accounting practice.
  Future<void> _doReverse() async {
    if (_current == null) {
      _showMsg('No receipt selected.');
      return;
    }
    if (_isReversed) {
      _showMsg('This receipt has already been reversed.');
      return;
    }
    if (_isLocked) {
      _showMsg('This receipt is LOCKED — it cannot be reversed.');
      return;
    }
    final no =
        _receiptNoCtrl.text.isNotEmpty
            ? _receiptNoCtrl.text
            : '#${_current!['id']}';
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Reverse Receipt'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reverse receipt $no?'),
                const SizedBox(height: 8),
                const Text(
                  'A reversal will create a negative entry to cancel this receipt. '
                  'The original receipt will be marked REVERSED.',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Reverse',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
    if (ok != true || !mounted) return;
    setState(() {
      _isSaving = true;
      _errorMsg = null;
    });
    try {
      // Send reversal request to backend
      await ReceiptService().reverseReceipt(_current!['id'] as int);
      if (!mounted) return;
      _showMsg('Receipt $no reversed.', ok: true);
      await _loadReceipts();
      if (!mounted) return;
      setState(() {
        _mode = _Mode.view;
        _isSaving = false;
      });
    } catch (e) {
      if (!mounted) return;
      final raw = e.toString().replaceFirst(RegExp(r'^Exception: '), '');
      // Friendly message when backend reverse endpoint is not yet implemented
      final msg =
          raw.toLowerCase().contains('not found')
              ? 'Reverse endpoint not available on the server. Please apply the backend reverse prompt first.'
              : raw;
      setState(() {
        _isSaving = false;
        _errorMsg = msg;
      });
    }
  }

  // Retrieve Values for New Member: auto-populates Share Capital line item.
  Future<void> _doRetrieveValues() async {
    if (_memberId == null) {
      _showMsg('Select a member first, then click Retrieve Values.');
      return;
    }

    // Look for Share Capital ledger in the loaded ledgers
    final shareLedger = _ledgers.firstWhere(
      (l) => (l['name']?.toString() ?? '').toLowerCase().contains('share'),
      orElse: () => {},
    );
    if (shareLedger.isEmpty) {
      _showMsg('Share Capital account not found in ledger list.');
      return;
    }

    // Try local max amount first; if unavailable fetch from API
    double maxAmt = double.tryParse(_maxAmountCtrl.text.trim()) ?? 0.0;
    if (maxAmt <= 0) {
      setState(() => _isSaving = true);
      try {
        final fetched = await ReceiptService().getMemberMaxAmount(_memberId!);
        if (!mounted) return;
        maxAmt = fetched ?? 0.0;
        if (maxAmt > 0) {
          setState(() => _maxAmountCtrl.text = maxAmt.toStringAsFixed(2));
        }
      } catch (_) {
        // ignore — will just not pre-fill the amount
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }

    // Pre-fill first grid row with Share Capital and max amount
    setState(() {
      if (_lines.isEmpty) _lines.add(_GridLine());
      _lines[0].accountId = int.tryParse(shareLedger['id']?.toString() ?? '');
      _lines[0].accountDesc =
          shareLedger['name']?.toString() ?? 'Share Capital';
      if (maxAmt > 0) _lines[0].amtCtrl.text = maxAmt.toStringAsFixed(2);
      if (_memberNo != null) _lines[0].refCtrl.text = _memberNo!;
      // Ensure there's a blank trailing row
      if (_lines.last.hasData) _lines.add(_GridLine());
    });
    final msg =
        maxAmt > 0
            ? 'Share Capital entry loaded. Amount: ${_fmtAmt(maxAmt.toStringAsFixed(2))}'
            : 'Share Capital account set. Enter the amount manually.';
    _showMsg(msg, ok: maxAmt > 0);
  }

  void _doCancel() {
    setState(() {
      _mode = _Mode.view;
      _errorMsg = null;
    });
    if (_current != null) {
      _populate(_current!);
    } else if (_receipts.isNotEmpty) {
      _navigateTo(_receipts.length - 1);
    } else {
      _clearForm();
    }
  }

  void _doExit() {
    if (widget.onSaved != null) {
      widget.onSaved!();
    } else {
      Navigator.maybePop(context);
    }
  }

  Future<void> _doView() async {
    if (_receipts.isEmpty) {
      _showMsg('No receipts to search.');
      return;
    }
    final searchCtrl = TextEditingController();
    String searchType = 'receipt';
    List<Map<String, dynamic>> filtered = List.from(_receipts);

    await showDialog<void>(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder: (ctx, setS) {
              void filter(String q) {
                setS(() {
                  if (q.trim().isEmpty) {
                    filtered = List.from(_receipts);
                  } else if (searchType == 'receipt') {
                    filtered =
                        _receipts
                            .where(
                              (r) => (r['receipt_no']?.toString() ?? '')
                                  .toLowerCase()
                                  .contains(q.toLowerCase()),
                            )
                            .toList();
                  } else {
                    filtered =
                        _receipts
                            .where(
                              (r) => (r['member_name']?.toString() ?? '')
                                  .toLowerCase()
                                  .contains(q.toLowerCase()),
                            )
                            .toList();
                  }
                });
              }

              return AlertDialog(
                titlePadding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                title: const Text(
                  'View Receipt',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                contentPadding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                content: SizedBox(
                  width: 420,
                  height: 380,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Search by:',
                            style: TextStyle(fontSize: 13),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text(
                              'Receipt No',
                              style: TextStyle(fontSize: 12),
                            ),
                            selected: searchType == 'receipt',
                            onSelected:
                                (_) => setS(() {
                                  searchType = 'receipt';
                                  searchCtrl.clear();
                                  filtered = List.from(_receipts);
                                }),
                          ),
                          const SizedBox(width: 6),
                          ChoiceChip(
                            label: const Text(
                              'Member Name',
                              style: TextStyle(fontSize: 12),
                            ),
                            selected: searchType == 'member',
                            onSelected:
                                (_) => setS(() {
                                  searchType = 'member';
                                  searchCtrl.clear();
                                  filtered = List.from(_receipts);
                                }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: searchCtrl,
                        autofocus: true,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          border: const OutlineInputBorder(),
                          hintText:
                              searchType == 'receipt'
                                  ? 'Enter receipt number…'
                                  : 'Enter member name…',
                          prefixIcon: const Icon(Icons.search, size: 18),
                        ),
                        onChanged: filter,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child:
                            filtered.isEmpty
                                ? const Center(
                                  child: Text(
                                    'No receipts found.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                )
                                : ListView.builder(
                                  itemCount: filtered.length,
                                  itemBuilder: (_, i) {
                                    final r = filtered[i];
                                    // E27: format date with _dispDate
                                    final dateStr =
                                        (() {
                                          final raw =
                                              r['receipt_date']?.toString() ??
                                              '';
                                          try {
                                            return _dispDate(
                                              DateTime.parse(raw),
                                            );
                                          } catch (_) {
                                            return raw;
                                          }
                                        })();
                                    return InkWell(
                                      // E12: guard with mounted check
                                      onTap: () {
                                        Navigator.of(ctx).pop();
                                        final idx = _receipts.indexWhere(
                                          (x) => x['id'] == r['id'],
                                        );
                                        if (idx >= 0 && mounted)
                                          _navigateTo(idx);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              color: Colors.grey.shade200,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 80,
                                              child: Text(
                                                r['receipt_no']?.toString() ??
                                                    '#${r['id']}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                r['member_name']?.toString() ??
                                                    '—',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Text(
                                              dateStr,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancel'),
                  ),
                ],
              );
            },
          ),
    );
    searchCtrl.dispose();
  }

  // E09: _isPrinting guard + try/finally
  Future<void> _doPrint() async {
    if (_current == null) return;
    if (_isPrinting) return;
    setState(() => _isPrinting = true);
    try {
      final r = _current!;
      final receiptNo =
          _receiptNoCtrl.text.isNotEmpty ? _receiptNoCtrl.text : '#${r['id']}';

      // E10: derive values from _current! map for view-mode printing
      // PDF uses ASCII-safe fallbacks — Helvetica has no Unicode support
      final memberName = _pdfSafe(
          _current!['member_name']?.toString().isNotEmpty == true
              ? _current!['member_name'].toString()
              : (_nameCtrl.text.isNotEmpty ? _nameCtrl.text : '-'));

      final narration = _descCtrl.text.trim();

      // Resolve account name: in-memory state → ledger lookup → receipt fields → dash
      String acctDesc = _gridAcctDesc;
      if (acctDesc.isEmpty && _selectedAccountId != null) {
        final l = _ledgers.firstWhere(
          (l) => l['id'] == _selectedAccountId,
          orElse: () => {},
        );
        acctDesc = l['name']?.toString() ?? '';
      }
      if (acctDesc.isEmpty) {
        acctDesc =
            r['account_description']?.toString() ??
            r['account_name']?.toString() ??
            r['account_type']?.toString() ??
            '-';
      }
      acctDesc = _pdfSafe(acctDesc);

      // refNo kept for single-line cheque field; multi-line uses _lines below
      final refNo = r['reference_no']?.toString() ?? '';

      // E10: read receipt date from _current!
      final date =
          (() {
            try {
              return _dispDate(DateTime.parse(_current!['receipt_date'] ?? ''));
            } catch (_) {
              return _dispDate(_receiptDate);
            }
          })();

      // E10: derive payment mode from _current! map
      final actualPmRaw = _current!['payment_mode']?.toString() ?? _paymentMode;
      final actualPm =
          const {
            'cash': 'CASH',
            'bank': 'BANK',
            'adj': 'ADJ',
            'adjustment': 'ADJ',
          }[actualPmRaw.toLowerCase()] ??
          actualPmRaw;
      final isChequePrint = actualPm == 'BANK';
      final pmLabel = const {
        'CASH': 'Cash',
        'BANK': 'Cheque / DD',
        'UPI': 'UPI',
        'NEFT': 'NEFT',
        'OTHERS': 'Others',
        'ADJ': 'Adjustment',
      }[actualPm] ?? actualPm;
      // PDO no (from controller or _current map)
      final printPdoNo =
          _pdoNoCtrl.text.isNotEmpty
              ? _pdoNoCtrl.text
              : (r['pdo_no']?.toString() ?? '');

      // Cheque fields: controller (populated during edit) → _current! map (loaded from backend)
      // _current! is always fresher than controllers in view mode when backend omits these fields
      final printChequeNo =
          _chequeNoCtrl.text.isNotEmpty
              ? _chequeNoCtrl.text
              : (r['reference_no']?.toString() ??
                  r['cheque_no']?.toString() ??
                  '');
      final printDrawnOn = _pdfSafe(
          _drawnOnCtrl.text.isNotEmpty
              ? _drawnOnCtrl.text
              : (r['drawn_on']?.toString() ?? r['bank_name']?.toString() ?? ''));
      final printChequeDt =
          _chequeDtCtrl.text.isNotEmpty
              ? _chequeDtCtrl.text
              : (() {
                final raw = r['cheque_date']?.toString() ?? '';
                if (raw.isEmpty) return '';
                try {
                  return _dispDate(DateTime.parse(raw));
                } catch (_) {
                  return raw;
                }
              })();
      final printDepositedIn = _pdfSafe(
          _depositedInCtrl.text.isNotEmpty
              ? _depositedInCtrl.text
              : (r['deposited_in']?.toString() ??
                  r['deposit_account']?.toString() ??
                  ''));
      // Narration: controller may be stale in view mode — also check _current!
      final printNarration = _pdfSafe(
          _descCtrl.text.trim().isNotEmpty
              ? _descCtrl.text.trim()
              : (r['narration']?.toString() ??
                  r['description']?.toString() ??
                  ''));

      // Build PDF line items from in-memory _lines (filled rows only)
      // PDF-safe amounts: replace ₹ with "Rs." (Helvetica has no Unicode ₹)
      final printLines = _lines.where((l) => l.parsedAmount > 0).toList();
      // Fallback: if lines empty (viewing old receipt), build from receipt data
      final hasPrintLines = printLines.isNotEmpty;
      final totalDouble =
          hasPrintLines
              ? _totalAmount
              : double.tryParse(
                    (_current!['amount']?.toString() ?? '0')
                        .replaceAll(',', '')
                        .replaceAll('₹', '')
                        .replaceAll('Rs.', ''),
                  ) ??
                  0.0;
      final totalFmt = _fmtAmt(
        totalDouble.toStringAsFixed(2),
      ).replaceAll('₹', 'Rs.');

      final fontRegular = pw.Font.ttf(
          await rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
      final fontBold = pw.Font.ttf(
          await rootBundle.load('assets/fonts/Roboto-Bold.ttf'));
      final doc = pw.Document(
        theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
      );
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a5.landscape,
          margin: const pw.EdgeInsets.all(24),
          build:
              (pw.Context ctx) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Society header — E42: use constant
                  pw.Center(
                    child: pw.Column(
                      children: [
                        pw.Text(
                          _kSocietyName,
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'RECEIPT',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.Divider(thickness: 1.5),
                  pw.SizedBox(height: 6),
                  // Receipt No + Date
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Receipt No: $receiptNo',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Date: $date',
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  // Received From
                  pw.Row(
                    children: [
                      pw.Text(
                        'Received From: ',
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                      pw.Text(
                        memberName,
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        '  (${r['received_from']?.toString() ?? _receivedFrom})',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  // PDO No shown on its own line (matches legacy layout)
                  if ((r['received_from'] ?? _receivedFrom) == 'PDO' &&
                      printPdoNo.isNotEmpty)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 2),
                      child: pw.Row(
                        children: [
                          pw.Text(
                            'PDO No: ',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            printPdoNo,
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  pw.SizedBox(height: 4),
                  if (printNarration.isNotEmpty)
                    pw.Row(
                      children: [
                        pw.Text(
                          'Description: ',
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                        pw.Text(
                          printNarration,
                          style: const pw.TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Payment Mode: $pmLabel',
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                  // Cheque detail rows — read from _current! map, controller as fallback
                  if (isChequePrint) ...[
                    pw.SizedBox(height: 2),
                    pw.Row(
                      children: [
                        pw.Text(
                          'Cheque No: ',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          printChequeNo,
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                    if (printDrawnOn.isNotEmpty) ...[
                      pw.SizedBox(height: 2),
                      pw.Row(
                        children: [
                          pw.Text(
                            'Drawn On: ',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Text(
                              printDrawnOn,
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (printChequeDt.isNotEmpty) ...[
                      pw.SizedBox(height: 2),
                      pw.Row(
                        children: [
                          pw.Text(
                            'Cheque Date: ',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            printChequeDt,
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                    if (printDepositedIn.isNotEmpty)
                      pw.Text(
                        'Deposited In: $printDepositedIn',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                  ],
                  pw.SizedBox(height: 12),
                  // Account entries table — E33: use amtFormatted
                  pw.Table(
                    border: pw.TableBorder.all(width: 0.5),
                    columnWidths: const {
                      0: pw.FlexColumnWidth(4),
                      1: pw.FlexColumnWidth(2),
                      2: pw.FlexColumnWidth(2),
                    },
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.grey300,
                        ),
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              'A/C Description',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              'Ref No',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              'Amount',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 10,
                              ),
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                      // Data rows — one per line item
                      if (hasPrintLines)
                        ...printLines.map(
                          (l) => pw.TableRow(
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(4),
                                child: pw.Text(
                                  _pdfSafe(l.accountDesc.isNotEmpty
                                      ? l.accountDesc
                                      : '-'),
                                  style: const pw.TextStyle(fontSize: 10),
                                ),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(4),
                                child: pw.Text(
                                  l.refCtrl.text,
                                  style: const pw.TextStyle(fontSize: 10),
                                ),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(4),
                                child: pw.Text(
                                  _fmtAmt(
                                    l.parsedAmount.toStringAsFixed(2),
                                  ).replaceAll('₹', 'Rs.'),
                                  style: const pw.TextStyle(fontSize: 10),
                                  textAlign: pw.TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(
                                acctDesc,
                                style: const pw.TextStyle(fontSize: 10),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(
                                refNo,
                                style: const pw.TextStyle(fontSize: 10),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(
                                totalFmt,
                                style: const pw.TextStyle(fontSize: 10),
                                textAlign: pw.TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.grey100,
                        ),
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              'TOTAL',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(''),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              totalFmt,
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 10,
                              ),
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 24),
                  // Signature row — PDF-009: height 1.0
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Container(
                            width: 130,
                            height: 1.0,
                            color: PdfColors.black,
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            "Receiver's Signature",
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Container(
                            width: 130,
                            height: 1.0,
                            color: PdfColors.black,
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'Authorised Signatory',
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.Spacer(),
                  pw.Center(
                    child: pw.Text(
                      'This is a computer generated receipt.',
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ),
                ],
              ),
        ),
      );

      await Printing.layoutPdf(onLayout: (_) async => doc.save());
    } catch (e) {
      if (mounted) {
        _showMsg(
          'Print failed: ${e.toString().replaceFirst(RegExp(r'^Exception: '), '')}',
        );
      }
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  // ═══ HELPERS ══════════════════════════════════════════════════════════════════

  bool _validate() {
    // Received From: Member requires member selection
    if (_receivedFrom == 'Member' && _memberId == null) {
      setState(
        () =>
            _errorMsg =
                'Please select a member — type a name in the NAME field and click a result.',
      );
      return false;
    }
    // PDO / Others: name required, letters and spaces only
    if (_receivedFrom != 'Member') {
      final name = _nameCtrl.text.trim();
      if (name.isEmpty) {
        setState(() => _errorMsg = 'Name is required.');
        return false;
      }
      // E18: extended regex
      if (!RegExp(r"^[A-Za-z0-9 .&'\-]+$").hasMatch(name)) {
        setState(
          () => _errorMsg = 'Name must contain letters and spaces only.',
        );
        return false;
      }
    }
    // Cheque / DD: mandatory header fields
    if (_isChequeDD) {
      if (_drawnOnCtrl.text.trim().isEmpty) {
        setState(() => _errorMsg = 'Drawn On is required for Cheque / DD.');
        return false;
      }
      if (_chequeNoCtrl.text.trim().isEmpty) {
        setState(() => _errorMsg = 'Cheque No is required for Cheque / DD.');
        return false;
      }
      // cheque date: accept either date-picker selection or typed DD/MM/YYYY
      if (_chequeDate == null && _chequeDtCtrl.text.trim().isEmpty) {
        setState(() => _errorMsg = 'Cheque Date is required for Cheque / DD.');
        return false;
      }
      // parse typed date if picker wasn't used
      if (_chequeDate == null && _chequeDtCtrl.text.trim().isNotEmpty) {
        final parts = _chequeDtCtrl.text.trim().split('/');
        if (parts.length == 3) {
          final d = int.tryParse(parts[0]),
              m = int.tryParse(parts[1]),
              y = int.tryParse(parts[2]);
          if (d != null && m != null && y != null) {
            setState(() { _chequeDate = DateTime(y, m, d); });
          }
        }
        if (_chequeDate == null) {
          setState(
            () => _errorMsg = 'Cheque Date must be in DD/MM/YYYY format.',
          );
          return false;
        }
      }
    }
    // Must have at least one line with an amount
    final filledLines = _lines.where((l) => l.parsedAmount > 0).toList();
    if (filledLines.isEmpty) {
      setState(() => _errorMsg = 'Enter at least one amount in the grid.');
      return false;
    }
    // Each filled line must have an account selected (when ledgers are available)
    if (_ledgers.isNotEmpty) {
      for (int i = 0; i < _lines.length; i++) {
        final l = _lines[i];
        if (l.parsedAmount > 0 && l.accountId == null) {
          setState(
            () => _errorMsg = 'Row ${i + 1}: Please select an A/C Description.',
          );
          return false;
        }
      }
    }
    // E14: total vs max amount check
    final total = _totalAmount;
    final maxAmt = double.tryParse(_maxAmountCtrl.text.trim());
    if (maxAmt != null && maxAmt > 0 && total > maxAmt) {
      setState(
        () =>
            _errorMsg =
                'Total ${_fmtAmt(total.toStringAsFixed(2))} exceeds maximum allowed ${_fmtAmt(maxAmt.toStringAsFixed(2))}.',
      );
      return false;
    }
    return true;
  }

  String _dispDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  String _apiDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final p = await showDatePicker(
      context: context,
      initialDate: _receiptDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2099),
    );
    if (p != null && mounted) {
      setState(() => _receiptDate = p);
      // E02: update date label controller
      _dateLabelCtrl.text = _dispDate(p);
    }
  }

  // E04: new cheque date picker
  Future<void> _pickChequeDate() async {
    final p = await showDatePicker(
      context: context,
      initialDate: _chequeDate ?? _receiptDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2099),
    );
    if (p != null && mounted) {
      setState(() {
        _chequeDate = p;
        _chequeDtCtrl.text = _dispDate(p);
      });
    }
  }

  String _fmtAmt(dynamic raw) => fmtAmount(raw);

  // Strips characters Helvetica cannot render so the pdf library never emits
  // "Unable to find a font to draw …" warnings.
  static String _pdfSafe(String s) => s
      .replaceAll('—', '--')   // em dash  —
      .replaceAll('–', '-')    // en dash  –
      .replaceAll('‘', "'")    // '
      .replaceAll('’', "'")    // '
      .replaceAll('“', '"')    // "
      .replaceAll('”', '"')    // "
      .replaceAll('…', '...')  // …
      .replaceAll('₹', 'Rs.');     // rupee sign

  void _showMsg(String msg, {bool ok = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              ok
                  ? Icons.check_circle_outline_rounded
                  : Icons.info_outline_rounded,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(msg, style: const TextStyle(fontSize: 13))),
          ],
        ),
        backgroundColor: ok ? const Color(0xFF166534) : const Color(0xFF1E3A5F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ═══ BUILD ════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _bg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: _primary),
              const SizedBox(height: 16),
              Text(
                'Loading receipts…',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    // E20: CallbackShortcuts for keyboard navigation
    return Scaffold(
      backgroundColor: _bg,
      body: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.f2): () {
            if (!_isEditMode && !_isBusy) _doAdd();
          },
          const SingleActivator(LogicalKeyboardKey.f4): () {
            if (!_isEditMode && !_isBusy && _current != null && !_isLocked)
              _doChange();
          },
          const SingleActivator(LogicalKeyboardKey.f10): () {
            if (_isEditMode && !_isSaving) _doSave();
          },
          const SingleActivator(LogicalKeyboardKey.escape): () {
            if (_isEditMode) _doCancel();
          },
          const SingleActivator(LogicalKeyboardKey.pageUp): () {
            if (!_isEditMode && !_isBusy && _currentIdx > 0)
              _navigateTo(_currentIdx - 1);
          },
          const SingleActivator(LogicalKeyboardKey.pageDown): () {
            if (!_isEditMode && !_isBusy && _currentIdx < _receipts.length - 1)
              _navigateTo(_currentIdx + 1);
          },
          const SingleActivator(LogicalKeyboardKey.home, control: true): () {
            if (!_isEditMode && !_isBusy) _navigateTo(0);
          },
          const SingleActivator(LogicalKeyboardKey.end, control: true): () {
            if (!_isEditMode && !_isBusy) _navigateTo(_receipts.length - 1);
          },
        },
        child: Focus(
          autofocus: true,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _buildTitleBar(),
                  const SizedBox(height: 8),
                  _buildFormPanel(),
                  const SizedBox(height: 6),
                  Expanded(child: _buildGrid()),
                  if (_errorMsg != null) _buildErrorRow(),
                  const SizedBox(height: 8),
                  _buildButtons(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Title bar ──────────────────────────────────────────────────────────────────

  Widget _buildTitleBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_titleGrad1, _titleGrad2],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
      child: Row(
        children: [
          const Icon(
            Icons.receipt_long_rounded,
            color: Colors.white70,
            size: 20,
          ),
          const SizedBox(width: 10),
          const Text(
            'Receipt Management',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
          if (_isEditMode) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Text(
                _mode == _Mode.add ? 'ADD MODE' : 'EDIT MODE',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
          const Spacer(),
          Tooltip(
            message:
                _memberId == null
                    ? 'Select a member first to retrieve values'
                    : 'Pre-fills Share Capital ledger and member max amount',
            child: _btn(
              'Retrieve Values',
              icon: Icons.download_outlined,
              width: 144,
              height: 34,
              tint: true,
              onPressed:
                  (_isEditMode && _memberId != null) ? _doRetrieveValues : null,
            ),
          ),
        ],
      ),
    );
  }

  // ── Form panel ────────────────────────────────────────────────────────────────

  Widget _buildFormPanel() {
    return Container(
      decoration: BoxDecoration(
        color: _panelBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 3,
            child: ColoredBox(color: _sectionAccent),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Status banners ────────────────────────────────────────────
              if (_isLocked)   _buildLockedBanner(),
              if (_isReversed) _buildReversedBanner(),
              // ── Two-pane body ─────────────────────────────────────────────
              LayoutBuilder(
                builder: (ctx, constraints) {
                  if (constraints.maxWidth >= 900) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left pane carries its own right-border — no separate divider widget needed
                        _buildLeftPane(wide: true),
                        Expanded(child: _buildRightPane()),
                      ],
                    );
                  }
                  // Narrow fallback: stack vertically
                  return Column(
                    children: [_buildLeftPane(wide: false), _buildRightPane()],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLockedBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFBEB),
        border: Border(bottom: BorderSide(color: Color(0xFFFDE68A), width: 1)),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock_rounded, size: 14, color: Color(0xFFB45309)),
          SizedBox(width: 6),
          Text(
            'LOCKED — Read Only',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFFB45309),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReversedBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: const BoxDecoration(
        color: Color(0xFFFFF1F2),
        border: Border(bottom: BorderSide(color: Color(0xFFFCA5A5), width: 1)),
      ),
      child: const Row(children: [
        Icon(Icons.undo_rounded, size: 14, color: Color(0xFFB91C1C)),
        SizedBox(width: 6),
        Text('REVERSED — This receipt has been cancelled',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: Color(0xFFB91C1C))),
      ]),
    );
  }

  Widget _buildLeftPane({bool wide = true}) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionAccentHeader(Icons.receipt_outlined, 'Receipt Details'),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_row1(), const SizedBox(height: 8), _row2()],
          ),
        ),
      ],
    );
    if (!wide) {
      return Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFE2EAF4), width: 1)),
        ),
        child: content,
      );
    }
    // Wide mode: IntrinsicWidth lets the pane auto-size to its widest row
    // so rows never overflow regardless of field/label widths
    return Container(
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: Color(0xFFE2EAF4), width: 1)),
      ),
      child: IntrinsicWidth(child: content),
    );
  }

  Widget _buildRightPane() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionAccentHeader(Icons.person_outline_rounded, 'Payer Details'),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _nameRow(),
                const SizedBox(height: 8),
                _descRow(),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: _isChequeDD
                      ? Column(
                          children: [
                            const SizedBox(height: 8),
                            _chequeDetailBlock(),
                          ],
                        )
                      : _isUpiNeft
                          ? Column(
                              children: [
                                const SizedBox(height: 8),
                                _utrRefRow(),
                              ],
                            )
                          : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionAccentHeader(IconData icon, String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: const BoxDecoration(
        color: Color(0xFFF0F6F9),
        border: Border(
          top: BorderSide(color: Color(0xFFD1E4EC), width: 0.8),
          bottom: BorderSide(color: Color(0xFFD1E4EC), width: 0.8),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(icon, size: 13, color: _primary),
          ),
          const SizedBox(width: 7),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF003D52),
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  // Row 1: Receipt No | Cheque/DD checkbox | Date  (matches legacy UI)
  Widget _row1() {
    return Row(
      children: [
        _lbl('Receipt No'),
        _field(_receiptNoCtrl, width: 96, readOnly: true, bg: _receiptNoYellow),
        const SizedBox(width: 10),
        _lbl('Mode', width: 38),
        // ADJ is system-only; user chooses from _kPayModes for all other receipts
        if (_paymentMode == 'ADJ')
          _adjBadge()
        else
          _dropdown(
            value: _kPayModes.contains(_paymentMode) ? _paymentMode : 'CASH',
            items: _kPayModes,
            width: 100,
            onChanged: _isEditMode
                ? (v) => setState(() => _paymentMode = v ?? 'CASH')
                : null,
          ),
        const SizedBox(width: 16),
        _lbl('Date', width: 36),
        // Tap to pick date; shows DD/MM/YYYY with visible calendar icon
        GestureDetector(
          onTap: _isEditMode ? _pickDate : null,
          child: _fieldWithSuffix(
            ctrl: _dateLabelCtrl,
            width: 110,
            readOnly: true,
            suffixIcon: Icon(
              Icons.calendar_today_rounded,
              size: 14,
              color: _isEditMode ? _primary : Colors.grey.shade400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _adjBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFF59E0B), width: 1),
      ),
      child: const Text(
        'Adjustment',
        style: TextStyle(
          fontSize: 12,
          color: Color(0xFFB45309),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // UPI / NEFT: transaction reference / UTR no row
  Widget _utrRefRow() {
    return Row(
      children: [
        _lbl('Txn Ref / UTR No'),
        _field(_utrCtrl, width: 200, readOnly: !_isEditMode),
      ],
    );
  }

  // Row 2: Received From | Max.Amount
  Widget _row2() {
    return Row(
      children: [
        _lbl('Received From'),
        _dropdown(
          value: _receivedFrom,
          items: const ['Member', 'PDO', 'Others'],
          width: 100,
          onChanged:
              _isEditMode
                  ? (v) => setState(() {
                    _receivedFrom = v ?? 'Member';
                    if (v != 'Member') {
                      _memberId = null;
                      _memberName = null;
                      _memberNo = null;
                      _memberResults = [];
                      _memberSearchCtrl.clear();
                      _nameCtrl.clear();
                    }
                    if (v != 'PDO') _pdoNoCtrl.clear();
                  })
                  : null,
        ),
        const Spacer(),
        _lbl('Max.Amount', width: 78),
        // E13: max amount is always readOnly
        _field(_maxAmountCtrl, width: 90, readOnly: true),
      ],
    );
  }

  // NAME / PDO row — label and layout change based on received_from (matches legacy)
  Widget _nameRow() {
    // PDO: shows "PDO" label + PDO code field + company name field
    if (_receivedFrom == 'PDO') {
      return Row(
        children: [
          _lbl('PDO'),
          _field(_pdoNoCtrl, width: 72, readOnly: !_isEditMode, hint: 'PDO No'),
          const SizedBox(width: 4),
          Expanded(
            child: _field(
              _nameCtrl,
              readOnly: !_isEditMode,
              hint: _isEditMode ? 'Company name…' : null,
            ),
          ),
        ],
      );
    }

    final showMemberNo =
        _receivedFrom == 'Member' && _memberNo != null && _memberNo!.isNotEmpty;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _lbl(_receivedFrom == 'Member' ? 'Member No' : 'Name'),
        if (showMemberNo) ...[
          Container(
            width: 84,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF93C5FD)),
            ),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              _memberNo!,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1D4ED8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
        Expanded(
          child:
              _isEditMode && _receivedFrom == 'Member'
                  ? _memberSearchWidget()
                  : _field(_nameCtrl, readOnly: !_isEditMode),
        ),
      ],
    );
  }

  Widget _memberSearchWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_memberId != null)
          Container(
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF93C5FD)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                const Icon(
                  Icons.person_outline_rounded,
                  size: 15,
                  color: Color(0xFF2563EB),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _memberName ?? '',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF1E3A5F),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap:
                      () => setState(() {
                        _memberId = null;
                        _memberName = null;
                        _memberNo = null;
                        _nameCtrl.clear();
                        if (_lines.isNotEmpty) {
                          _lines[0].accountId = null;
                          _lines[0].accountDesc = '';
                        }
                      }),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            height: 32,
            decoration: BoxDecoration(
              color: _inputBg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _border),
            ),
            child: TextField(
              controller: _memberSearchCtrl,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 7,
                ),
                border: InputBorder.none,
                hintText: 'Type member name to search…',
                hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
                suffixIcon:
                    _isMemberSearching
                        ? const Padding(
                          padding: EdgeInsets.all(8),
                          child: SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _primary,
                            ),
                          ),
                        )
                        : null,
              ),
              onChanged: _onMemberSearchChanged,
            ),
          ),
        if (!_isMemberSearching &&
            _memberResults.isEmpty &&
            _memberSearchCtrl.text.length >= 2)
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 13,
                  color: Colors.amber.shade700,
                ),
                const SizedBox(width: 5),
                const Text(
                  'No members found. Try a different name.',
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ),
        if (_memberResults.isNotEmpty) ...[
          Container(
            constraints: const BoxConstraints(maxHeight: 240),
            margin: const EdgeInsets.only(top: 2),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.white,
              child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount:
                  _memberResults.length > 15 ? 15 : _memberResults.length,
              itemBuilder: (_, i) {
                final m = _memberResults[i];
                return InkWell(
                  onTap: () => _selectMember(m),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${m['member_name'] ?? ''}'
                          '${m['member_no'] != null ? "  (${m['member_no']})" : ""}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            ),
          ),
          if (_memberResults.length > 15)
            Padding(
              padding: const EdgeInsets.only(top: 3, left: 4),
              child: Text(
                'and ${_memberResults.length - 15} more…',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ),
        ],
      ],
    );
  }

  // Description row
  Widget _descRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _lbl('Description'),
        Expanded(child: _field(_descCtrl, readOnly: !_isEditMode, maxLines: 2)),
      ],
    );
  }

  // Visually-grouped cheque detail block with teal left-border accent
  Widget _chequeDetailBlock() {
    final en = _isEditMode;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 4),
      child: Stack(
        children: [
          const Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 3,
            child: ColoredBox(color: _primary),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Row(
                  children: [
                    _lbl('Drawn On'),
                    Expanded(child: _field(_drawnOnCtrl, readOnly: !en)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _lbl('Cheque No', width: 72),
                    _field(_chequeNoCtrl, width: 90, readOnly: !en),
                    const SizedBox(width: 8),
                    _lbl('Dt.', width: 24),
                    GestureDetector(
                      onTap: en ? _pickChequeDate : null,
                      child: _fieldWithSuffix(
                        ctrl: _chequeDtCtrl,
                        width: 95,
                        readOnly: !en,
                        hint: en ? '__/__/____' : '',
                        suffixIcon: Icon(
                          Icons.event_rounded,
                          size: 14,
                          color: en ? _primary : Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _lbl('Deposited In'),
                    Expanded(child: _field(_depositedInCtrl, readOnly: !en)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Grid (multi-line, matches legacy behaviour) ───────────────────────────────

  // Excel-style grid column widths (shared by header, rows, total)
  static const _xlRowNumW = 38.0;
  static const _xlRefW = 124.0;
  static const _xlAmtW = 138.0;
  static const _xlDelW =
      26.0; // delete-button column — always present to keep widths stable
  static const _xlLine = Color(0xFFBFC9D4); // Excel grid line colour

  Widget _buildGrid() {
    const rowH = 34.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _xlLine, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.09),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ── Excel column header ───────────────────────────────────────────────
          Container(
            height: 30,
            decoration: const BoxDecoration(
              color: _gridHdr,
              border: Border(bottom: BorderSide(color: _xlLine, width: 1.5)),
            ),
            child: Row(
              children: [
                // Row # column header
                Container(
                  width: _xlRowNumW,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    border: Border(
                      right: BorderSide(color: _xlLine, width: 1.5),
                    ),
                  ),
                  child: const Text(
                    '#',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4A5568),
                    ),
                  ),
                ),
                // A/C Description header (with inline ledger error button from Design C)
                Expanded(
                  flex: 4,
                  child: Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: const BoxDecoration(
                      border: Border(
                        right: BorderSide(color: _xlLine, width: 1.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'A/C Description',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF003D52),
                          ),
                        ),
                        if (_isEditMode &&
                            _ledgerLoadError != null &&
                            _ledgers.isEmpty) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 13,
                            color: Colors.orange.shade700,
                          ),
                          TextButton(
                            onPressed: _loadLedgers,
                            style: TextButton.styleFrom(
                              minimumSize: Size.zero,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              foregroundColor: Colors.orange.shade700,
                            ),
                            child: const Text(
                              'Retry',
                              style: TextStyle(fontSize: 10),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                // Ref No header
                Container(
                  width: _xlRefW,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: const BoxDecoration(
                    border: Border(
                      right: BorderSide(color: _xlLine, width: 1.5),
                    ),
                  ),
                  child: const Text(
                    'Ref No',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF003D52),
                    ),
                  ),
                ),
                // Amount header
                SizedBox(
                  width: _xlAmtW,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: const Text(
                      'Amount',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF003D52),
                      ),
                    ),
                  ),
                ),
                // Delete column placeholder — always present so widths stay stable
                SizedBox(width: _xlDelW),
              ],
            ),
          ),
          // ── Data rows — adaptive blank count via LayoutBuilder ─────────────────
          Expanded(
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                final blank = ((constraints.maxHeight / rowH).floor() -
                        _lines.length -
                        1)
                    .clamp(2, 8);
                final totalRows = _lines.length + blank;
                return ListView.builder(
                  itemCount: totalRows,
                  itemExtent: rowH,
                  itemBuilder: (_, i) => _buildGridRow(i),
                );
              },
            ),
          ),
          // ── Total row ──────────────────────────────────────────────────────────
          Container(
            height: 30,
            decoration: const BoxDecoration(
              color: Color(0xFFEBF4F7),
              border: Border(top: BorderSide(color: _xlLine, width: 1.5)),
            ),
            child: Row(
              children: [
                Container(
                  width: _xlRowNumW,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD4EAF0),
                    border: Border(
                      right: BorderSide(color: _xlLine, width: 1.5),
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: const BoxDecoration(
                      border: Border(
                        right: BorderSide(color: _xlLine, width: 1.5),
                      ),
                    ),
                    child: const Text(
                      'TOTAL',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _primary,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: _xlRefW,
                  decoration: const BoxDecoration(
                    border: Border(
                      right: BorderSide(color: _xlLine, width: 1.5),
                    ),
                  ),
                ),
                SizedBox(
                  width: _xlAmtW,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      _totalAmount > 0
                          ? _fmtAmt(_totalAmount.toStringAsFixed(2))
                          : '',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _primary,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
                // Delete column placeholder — keep widths stable
                SizedBox(width: _xlDelW),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridRow(int i) {
    final isDataRow = i < _lines.length;
    final line = isDataRow ? _lines[i] : null;
    final selected = i == _activeRow;

    // Row colour: selected = teal tint, else alternating white / near-white
    final rowColor =
        selected
            ? const Color(0xFFD6EEF5)
            : (i.isEven ? Colors.white : const Color(0xFFF7F9FC));
    // Row number gutter colour
    final gutterColor =
        selected ? const Color(0xFFADD8E6) : const Color(0xFFEEF1F5);

    return GestureDetector(
      onTap: () => setState(() => _activeRow = i),
      child: Container(
        // Bottom border on every row = horizontal grid lines
        decoration: BoxDecoration(
          color: rowColor,
          border: const Border(bottom: BorderSide(color: _xlLine, width: 0.8)),
        ),
        child: Row(
          children: [
            // ── Row number gutter (like Excel row indices) ─────────────────────
            Container(
              width: _xlRowNumW,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: gutterColor,
                border: const Border(
                  right: BorderSide(color: _xlLine, width: 1.5),
                ),
              ),
              child:
                  selected
                      ? const Icon(
                        Icons.arrow_right_rounded,
                        size: 17,
                        color: _primary,
                      )
                      : Text(
                        isDataRow ? '${i + 1}' : '',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
            ),
            // ── A/C Description ────────────────────────────────────────────────
            Expanded(
              flex: 4,
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(right: BorderSide(color: _xlLine, width: 1)),
                ),
                child:
                    _isEditMode && isDataRow
                        ? _acctDropdown(i)
                        : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            line?.accountDesc ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  (line?.accountDesc.isNotEmpty == true)
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFFD0D7DE),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
              ),
            ),
            // ── Ref No ──────────────────────────────────────────────────────────
            Container(
              width: _xlRefW,
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: _xlLine, width: 1)),
              ),
              child:
                  _isEditMode && isDataRow
                      ? _gridTF(line!.refCtrl)
                      : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          line?.refCtrl.text ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
            ),
            // ── Amount ──────────────────────────────────────────────────────────
            SizedBox(
              width: _xlAmtW,
              child:
                  _isEditMode && isDataRow
                      ? _gridTF(
                        line!.amtCtrl,
                        align: TextAlign.right,
                        onChanged: (_) => setState(() {}),
                        numeric: true,
                      )
                      : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          (line?.amtCtrl.text.isNotEmpty == true)
                              ? _fmtAmt(line!.amtCtrl.text)
                              : '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF1E293B),
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
            ),
            // ── Delete column — always same width so columns never shift ──────
            SizedBox(
              width: _xlDelW,
              child:
                  (_isEditMode && isDataRow && _lines.length > 1)
                      ? GestureDetector(
                        onTap:
                            () => setState(() {
                              _lines[i].dispose();
                              _lines.removeAt(i);
                              if (_activeRow >= _lines.length)
                                _activeRow = _lines.length - 1;
                            }),
                        child: Center(
                          child: Icon(
                            Icons.remove_circle_outline_rounded,
                            size: 15,
                            color: Colors.red.shade300,
                          ),
                        ),
                      )
                      : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _acctDropdown(int lineIdx) {
    final line = _lines[lineIdx];
    return DropdownButton<int?>(
      value: line.accountId,
      isExpanded: true,
      isDense: true,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      underline: const SizedBox(),
      style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
      hint: Text(
        'Select account…',
        style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
      ),
      items: _ledgerItems ?? [],
      onChanged: (v) {
        final name =
            v == null
                ? ''
                : (_ledgers
                        .firstWhere(
                          (l) => l['id']?.toString() == v.toString(),
                          orElse: () => {},
                        )['name']
                        ?.toString() ??
                    '');
        setState(() {
          line.accountId = v;
          line.accountDesc = name;
          if (lineIdx == _lines.length - 1 && v != null) {
            _lines.add(_GridLine());
          }
        });
      },
    );
  }

  Widget _gridTF(
    TextEditingController ctrl, {
    TextAlign align = TextAlign.left,
    void Function(String)? onChanged,
    bool numeric = false,
  }) {
    return TextField(
      controller: ctrl,
      textAlign: align,
      onChanged: onChanged,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true, signed: false)
          : TextInputType.text,
      inputFormatters: numeric
          ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))]
          : null,
      style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        border: InputBorder.none,
      ),
    );
  }

  // ── Error row ─────────────────────────────────────────────────────────────────

  Widget _buildErrorRow() {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFDC2626),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMsg!,
              style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626)),
            ),
          ),
          if (!_isEditMode)
            TextButton(
              onPressed: () {
                setState(() => _errorMsg = null);
                _loadReceipts();
              },
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: const Color(0xFFDC2626),
              ),
              child: const Text('Retry', style: TextStyle(fontSize: 12)),
            ),
          GestureDetector(
            onTap: () => setState(() => _errorMsg = null),
            child: const Icon(
              Icons.close_rounded,
              size: 15,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  // ── Action buttons ────────────────────────────────────────────────────────────

  Widget _buildButtons() {
    final hasCur = _current != null;
    // E17: isBusy
    final isBusy = _isBusy;
    // E17: gate navigation with isBusy
    final canNav = !_isEditMode && _receipts.isNotEmpty && !isBusy;
    final canEdit = hasCur && !_isEditMode && !_isLocked && !_isReversed;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEEF4F7), Color(0xFFF5F9FB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFB8D4DC), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: Column(
        children: [
          // ── Single horizontal row ───────────────────────────────────────────
          Row(
            children: [
              // CRUD group
              Tooltip(
                message: 'Reverse receipt',
                child: _btn(
                  'Reverse',
                  icon: Icons.undo_rounded,
                  onPressed:
                      !_isEditMode && !_isBusy && _current != null && !_isLocked && !_isReversed
                          ? _doReverse
                          : null,
                ),
              ),
              Tooltip(
                message: 'Add new receipt (F2)',
                child: _btn(
                  'Add',
                  icon: Icons.add_rounded,
                  hint: 'F2',
                  onPressed: !_isEditMode && !isBusy ? _doAdd : null,
                ),
              ),
              Tooltip(
                message: 'Edit current receipt (F4)',
                child: _btn(
                  'Change',
                  icon: Icons.edit_rounded,
                  hint: 'F4',
                  onPressed: canEdit ? _doChange : null,
                ),
              ),
              Tooltip(
                message: 'Delete current receipt',
                child: _btn(
                  'Delete',
                  icon: Icons.delete_outline_rounded,
                  onPressed: canEdit ? _doDelete : null,
                ),
              ),
              Tooltip(
                message: 'Search receipts',
                child: _btn(
                  'View',
                  icon: Icons.search_rounded,
                  onPressed: !_isEditMode && !isBusy ? _doView : null,
                ),
              ),
              Tooltip(
                message: 'Save receipt (F10)',
                child: _btn(
                  'Save',
                  icon: Icons.save_rounded,
                  hint: 'F10',
                  onPressed: _isEditMode && !_isSaving ? _doSave : null,
                  active: _isEditMode,
                ),
              ),
              Tooltip(
                message: 'Cancel editing (Esc)',
                child: _btn(
                  'Cancel',
                  icon: Icons.close_rounded,
                  hint: 'Esc',
                  onPressed: _isEditMode && !_isBusy ? _doCancel : null,
                ),
              ),
              // Divider between CRUD and navigation
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Container(
                  width: 1,
                  height: 28,
                  color: const Color(0xFFB8D4DC),
                ),
              ),
              // Navigation group
              Tooltip(
                message: 'First record',
                child: _btn(
                  'First',
                  icon: Icons.first_page_rounded,
                  onPressed:
                      canNav && _currentIdx > 0 ? () => _navigateTo(0) : null,
                ),
              ),
              Tooltip(
                message: 'Previous record (PgUp)',
                child: _btn(
                  'Prev',
                  icon: Icons.chevron_left_rounded,
                  hint: 'PgUp',
                  onPressed:
                      canNav && _currentIdx > 0
                          ? () => _navigateTo(_currentIdx - 1)
                          : null,
                ),
              ),
              Tooltip(
                message: 'Next record (PgDn)',
                child: _btn(
                  'Next',
                  icon: Icons.chevron_right_rounded,
                  hint: 'PgDn',
                  onPressed:
                      canNav && _currentIdx < _receipts.length - 1
                          ? () => _navigateTo(_currentIdx + 1)
                          : null,
                ),
              ),
              Tooltip(
                message: 'Last record',
                child: _btn(
                  'Last',
                  icon: Icons.last_page_rounded,
                  onPressed:
                      canNav && _currentIdx < _receipts.length - 1
                          ? () => _navigateTo(_receipts.length - 1)
                          : null,
                ),
              ),
              const Spacer(),
              // Utility group
              Tooltip(
                message: 'Print receipt',
                child: _btn(
                  'Print',
                  icon: Icons.print_rounded,
                  onPressed:
                      hasCur && !_isEditMode && !_isPrinting ? _doPrint : null,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Container(
                  width: 1,
                  height: 28,
                  color: const Color(0xFFB8D4DC),
                ),
              ),
              Tooltip(
                message: 'Exit receipt form',
                child: _btn(
                  'Exit',
                  icon: Icons.exit_to_app_rounded,
                  onPressed: _doExit,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          // ── Enriched status strip (Design B) ────────────────────────────────
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      _isEditMode
                          ? _primary
                          : (_receipts.isEmpty
                              ? Colors.grey.shade400
                              : const Color(0xFF16A34A)),
                ),
              ),
              const SizedBox(width: 7),
              Text(
                _isEditMode
                    ? (_mode == _Mode.add
                        ? 'Adding new receipt…'
                        : 'Editing receipt…')
                    : _receipts.isEmpty
                    ? 'No receipts found.'
                    : 'Record ${_currentIdx + 1} of ${_receipts.length}'
                        '${_current != null ? '  ·  ${_receiptNoCtrl.text}  ·  ${_dateLabelCtrl.text}' : ''}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
              if (_isLocked) ...[const SizedBox(width: 8), _lockedPill()],
              if (_isReversed) ...[const SizedBox(width: 8), _reversedPill()],
            ],
          ),
        ],
      ),
    );
  }

  Widget _lockedPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF59E0B), width: 0.8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_rounded, size: 10, color: Color(0xFFB45309)),
          SizedBox(width: 3),
          Text(
            'LOCKED',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFFB45309),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reversedPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFCA5A5), width: 0.8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.undo_rounded, size: 10, color: Color(0xFFB91C1C)),
          SizedBox(width: 3),
          Text(
            'REVERSED',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFFB91C1C),
            ),
          ),
        ],
      ),
    );
  }

  // ═══ SMALL WIDGET HELPERS ═════════════════════════════════════════════════════

  // Save-confirmation dialog row
  Widget _confirmRow(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, size: 14, color: Colors.grey.shade500),
      const SizedBox(width: 6),
      SizedBox(
        width: 100,
        child: Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ),
      Expanded(
        child: Text(value,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
      ),
    ]);
  }

  Widget _lbl(String text, {double width = 90}) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: SizedBox(
      width: width,
      child: Text(
        text,
        textAlign: TextAlign.right,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF334155),
        ),
      ),
    ),
  );

  Widget _field(
    TextEditingController ctrl, {
    double? width,
    bool readOnly = false,
    Color bg = _inputBg,
    int maxLines = 1,
    String? hint,
  }) {
    final isRO = readOnly;
    return Container(
      width: width,
      height: maxLines > 1 ? null : 32,
      decoration: BoxDecoration(
        color: isRO ? const Color(0xFFF1F5F9) : bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isRO ? const Color(0xFFE2E8F0) : _border),
        boxShadow:
            isRO
                ? null
                : [
                  BoxShadow(
                    color: const Color(0xFF00789B).withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
      ),
      child: TextField(
        controller: ctrl,
        readOnly: isRO,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 7,
          ),
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
        ),
      ),
    );
  }

  Widget _dropdown({
    required String value,
    required List<String> items,
    required double width,
    required void Function(String?)? onChanged,
  }) {
    return Container(
      width: width,
      height: 32,
      decoration: BoxDecoration(
        color: onChanged != null ? _inputBg : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        isDense: true,
        underline: const SizedBox(),
        style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
        items:
            items
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _btn(
    String label, {
    VoidCallback? onPressed,
    double width = 82,
    double height = 34,
    bool active = false,
    IconData? icon,
    bool tint = false,
    String? hint,
  }) {
    final bool enabled = onPressed != null;
    final Color bgColor =
        active
            ? const Color(0xFF00789B)
            : tint
            ? Colors.white.withValues(alpha: 0.18)
            : (enabled ? _btnBg : const Color(0xFFF1F5F9));
    final Color fgColor =
        active
            ? Colors.white
            : tint
            ? Colors.white
            : (enabled ? const Color(0xFF334155) : const Color(0xFFB0BAC7));
    final Color borderColor =
        active
            ? const Color(0xFF006480)
            : tint
            ? Colors.white.withValues(alpha: 0.4)
            : (enabled ? const Color(0xFFCBD5E1) : const Color(0xFFE8EDF3));

    Widget child;
    if (hint != null) {
      // Two-line layout: icon+label on top, hint key on bottom
      child = Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 13),
                const SizedBox(width: 3),
                Text(label, style: const TextStyle(fontSize: 11)),
              ],
            )
          else
            Text(label, style: const TextStyle(fontSize: 11)),
          Text(
            hint,
            style: TextStyle(
              fontSize: 9,
              color: fgColor.withValues(alpha: 0.7),
            ),
          ),
        ],
      );
    } else if (icon != null) {
      child = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontSize: 11),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    } else {
      child = Text(
        label,
        style: const TextStyle(fontSize: 12),
        textAlign: TextAlign.center,
        softWrap: true,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: SizedBox(
        width: width,
        height: height,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: bgColor,
            foregroundColor: fgColor,
            padding: const EdgeInsets.symmetric(horizontal: 3),
            elevation: enabled && !tint ? 1 : 0,
            shadowColor: Colors.black12,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: BorderSide(color: borderColor, width: 1),
            ),
            disabledBackgroundColor: const Color(0xFFF1F5F9),
            disabledForegroundColor: const Color(0xFFB0BAC7),
          ),
          onPressed: onPressed,
          child: child,
        ),
      ),
    );
  }

  // NEW: _fieldWithSuffix — for date fields needing a visible calendar icon
  Widget _fieldWithSuffix({
    required TextEditingController ctrl,
    double? width,
    bool readOnly = false,
    Color bg = Colors.white,
    String? hint,
    Widget? suffixIcon,
  }) {
    return Container(
      width: width,
      height: 32,
      decoration: BoxDecoration(
        color: readOnly ? const Color(0xFFF1F5F9) : bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: readOnly ? const Color(0xFFE2E8F0) : const Color(0xFFCBD5E1),
        ),
        boxShadow:
            readOnly
                ? null
                : [
                  BoxShadow(
                    color: const Color(0xFF00789B).withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
      ),
      child: TextField(
        controller: ctrl,
        readOnly: readOnly,
        style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 7,
          ),
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          suffixIcon:
              suffixIcon != null
                  ? Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: suffixIcon,
                  )
                  : null,
          suffixIconConstraints: const BoxConstraints(
            maxWidth: 28,
            maxHeight: 28,
          ),
        ),
      ),
    );
  }
}
