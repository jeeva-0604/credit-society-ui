import 'package:flutter/material.dart';
import '../../service/receipt_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/receipt_format_utils.dart';
import 'receipt_detail_screen.dart';

class ReceiptListScreen extends StatefulWidget {
  final VoidCallback? onNewReceipt;
  final Function(Map)? onEditReceipt;

  const ReceiptListScreen({super.key, this.onNewReceipt, this.onEditReceipt});

  @override
  State<ReceiptListScreen> createState() => _ReceiptListScreenState();
}

class _ReceiptListScreenState extends State<ReceiptListScreen> {
  List<Map<String, dynamic>> _receipts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final raw = await ReceiptService().getReceipts();
      if (mounted) {
        setState(() {
          _receipts = raw;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst(RegExp(r'^Exception: '), '');
          _isLoading = false;
        });
      }
    }
  }

  // ── FORMATTERS ────────────────────────────────────────────────────────────

  String _fmtDate(dynamic raw) {
    if (raw == null) return '-';
    if (raw is! String || raw.isEmpty) return raw.toString();
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  String _fmtAmount(dynamic raw) => fmtAmount(raw);

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipts'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _load,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New Receipt',
            onPressed: widget.onNewReceipt,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off,
                  size: 56, color: AppColors.error.withValues(alpha: 0.7)),
              const SizedBox(height: 12),
              const Text('Failed to load receipts',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                      fontSize: 16)),
              const SizedBox(height: 6),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textLight, fontSize: 12)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white),
                onPressed: _load,
              ),
            ],
          ),
        ),
      );
    }

    if (_receipts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 72, color: AppColors.grey_300),
            const SizedBox(height: 16),
            const Text('No receipts yet',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textLight)),
            const SizedBox(height: 8),
            const Text('Create your first receipt to get started.',
                style: TextStyle(color: AppColors.textLight)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Create Receipt'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white),
              onPressed: widget.onNewReceipt ?? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Use the New Receipt button above.')),
                );
              },
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
                AppColors.primary.withValues(alpha: 0.08)),
            dataRowMinHeight: 44,
            dataRowMaxHeight: 56,
            columnSpacing: 20,
            columns: const [
              DataColumn(label: _ColHeader('Receipt No')),
              DataColumn(label: _ColHeader('Date')),
              DataColumn(label: _ColHeader('Member')),
              DataColumn(label: _ColHeader('Account')),
              DataColumn(label: _ColHeader('Amount')),
              DataColumn(label: _ColHeader('Mode')),
              DataColumn(label: _ColHeader('Status')),
              DataColumn(label: _ColHeader('Actions')),
            ],
            rows: _receipts.map<DataRow>((r) {
              final isLocked = r['status'] == 'LOCKED' || r['status'] == 'REVERSED';
              return DataRow(cells: [
                DataCell(Text(r['receipt_no'] ?? '-',
                    style: const TextStyle(
                        fontFamily: 'monospace', fontSize: 12))),
                DataCell(Text(_fmtDate(r['receipt_date']))),
                DataCell(SizedBox(
                  width: 140,
                  child: Text(r['member_name'] ?? '-',
                      overflow: TextOverflow.ellipsis, maxLines: 1),
                )),
                DataCell(Text(r['account_number'] ?? '-')),
                DataCell(Text(_fmtAmount(r['amount']),
                    style: const TextStyle(fontWeight: FontWeight.w500))),
                DataCell(_ModeBadge(mode: r['payment_mode'])),
                DataCell(_StatusBadge(status: r['status'])),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility_outlined,
                          size: 18, color: AppColors.primary),
                      tooltip: 'View',
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReceiptDetailScreen(
                              receipt: Map<String, dynamic>.from(r)),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit_outlined,
                          size: 18,
                          color: isLocked
                              ? AppColors.grey_400
                              : AppColors.primary),
                      tooltip: r['status'] == 'LOCKED'
                          ? 'Receipt is locked'
                          : r['status'] == 'REVERSED'
                              ? 'Receipt has been reversed'
                              : 'Edit',
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: isLocked
                          ? null
                          : () => widget.onEditReceipt
                              ?.call(Map<String, dynamic>.from(r)),
                    ),
                  ],
                )),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ── SMALL STATELESS HELPERS ───────────────────────────────────────────────────

class _ColHeader extends StatelessWidget {
  final String text;
  const _ColHeader(this.text);

  @override
  Widget build(BuildContext context) =>
      Text(text,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13));
}

class _StatusBadge extends StatelessWidget {
  final String? status;
  const _StatusBadge({this.status});

  @override
  Widget build(BuildContext context) {
    final s = status ?? 'POSTED';
    final Color color;
    switch (s) {
      case 'POSTED':
        color = AppColors.success;
        break;
      case 'REVERSED':
      case 'CANCELLED':
        color = AppColors.error;
        break;
      case 'LOCKED':
        color = AppColors.warning;
        break;
      default:
        color = AppColors.textLight;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(s,
          style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600)),
    );
  }
}

class _ModeBadge extends StatelessWidget {
  final String? mode;
  const _ModeBadge({this.mode});

  static const _icons = {
    'CASH': Icons.payments_outlined,
    'BANK': Icons.account_balance_outlined,
    'UPI': Icons.phone_android_outlined,
    'ONLINE': Icons.language_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final label = mode ?? '-';
    final icon = _icons[label] ?? Icons.payment_outlined;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
