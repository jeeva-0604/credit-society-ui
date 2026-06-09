import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/receipt_format_utils.dart';

class ReceiptDetailScreen extends StatelessWidget {
  final Map<String, dynamic> receipt;

  const ReceiptDetailScreen({super.key, required this.receipt});

  @override
  Widget build(BuildContext context) {
    final status = receipt['status']?.toString() ?? 'POSTED';
    final isLocked = status == 'LOCKED';
    final isReversed = status == 'REVERSED';
    final paymentMode = receipt['payment_mode']?.toString() ?? '';
    final isBank = paymentMode.toUpperCase() == 'BANK';
    final receivedFrom = receipt['received_from']?.toString() ?? '';
    final isPdo = receivedFrom.toUpperCase() == 'PDO';

    return Scaffold(
      appBar: AppBar(
        title: Text(receipt['receipt_no']?.toString() ?? 'Receipt Detail'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── STATUS BADGE ─────────────────────────────────────────
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                decoration: BoxDecoration(
                  color: _statusColor(status).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _statusColor(status).withValues(alpha: 0.5)),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: _statusColor(status),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── RECEIPT DETAILS ──────────────────────────────────────
            _buildCard('Receipt', [
              _row('Receipt No',
                  receipt['receipt_no']?.toString() ?? '-', monospace: true),
              _row('Date', _fmtDate(receipt['receipt_date'])),
              if (receivedFrom.isNotEmpty)
                _row('Received From', receivedFrom),
              if (isPdo && (receipt['pdo_no']?.toString() ?? '').isNotEmpty)
                _row('PDO No', receipt['pdo_no'].toString()),
            ]),

            // ── MEMBER & ACCOUNT ─────────────────────────────────────
            _buildCard('Member & Account', [
              _row('Member', receipt['member_name']?.toString() ?? '-'),
              _row('Account',
                  receipt['account_number']?.toString() ?? '-'),
              if (receipt['account_balance'] != null)
                _row('Account Balance', _fmtAmount(receipt['account_balance']),
                    highlight: true),
            ]),

            // ── PAYMENT ──────────────────────────────────────────────
            _buildCard('Payment', [
              _row('Amount', _fmtAmount(receipt['amount']), highlight: true),
              _row('Payment Mode', paymentMode.isEmpty ? '-' : paymentMode),
              if (!isBank && (receipt['reference_no']?.toString() ?? '').isNotEmpty)
                _row('Reference No', receipt['reference_no'].toString()),
            ]),

            // ── CHEQUE / DD DETAILS ───────────────────────────────────
            if (isBank)
              _buildCard('Cheque / DD Details', [
                if ((receipt['reference_no']?.toString() ?? '').isNotEmpty)
                  _row('Cheque No', receipt['reference_no'].toString()),
                if ((receipt['drawn_on']?.toString() ?? '').isNotEmpty)
                  _row('Drawn On', receipt['drawn_on'].toString()),
                if (receipt['cheque_date'] != null)
                  _row('Cheque Date', _fmtDate(receipt['cheque_date'])),
                if ((receipt['deposited_in']?.toString() ?? '').isNotEmpty)
                  _row('Deposited In', receipt['deposited_in'].toString()),
              ]),

            // ── NARRATION ────────────────────────────────────────────
            if (receipt['narration'] != null)
              _buildCard('Notes', [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    receipt['narration'].toString(),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ]),

            // ── LOCKED NOTE ──────────────────────────────────────────
            if (isLocked)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock, color: AppColors.warning, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'This receipt is locked. Contact an administrator to make changes.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            // ── REVERSED NOTE ─────────────────────────────────────────
            if (isReversed)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.undo_rounded, color: AppColors.error, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'This receipt has been reversed and is no longer active.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: AppColors.grey_300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
            const Divider(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value,
      {bool monospace = false, bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textLight, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    highlight ? FontWeight.bold : FontWeight.w500,
                fontFamily: monospace ? 'monospace' : null,
                color: highlight ? AppColors.primary : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'POSTED':
        return AppColors.success;
      case 'CANCELLED':
      case 'REVERSED':
        return AppColors.error;
      case 'LOCKED':
        return AppColors.warning;
      default:
        return AppColors.textLight;
    }
  }

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
}
