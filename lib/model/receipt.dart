class Receipt {
  final int id;
  final String? receiptNo;
  final String receiptDate;
  final int memberId;
  final String? memberName;
  final int? accountId;
  final String? accountNumber;
  final double? accountBalance;
  final double amount;
  final String paymentMode;
  final String? referenceNo;
  final String? narration;
  final String? status;
  final int? demandDetailId;
  final String? receivedFrom;
  final String? drawnOn;
  final String? chequeDate;
  final String? depositedIn;

  const Receipt({
    required this.id,
    this.receiptNo,
    required this.receiptDate,
    required this.memberId,
    this.memberName,
    this.accountId,
    this.accountNumber,
    this.accountBalance,
    required this.amount,
    required this.paymentMode,
    this.referenceNo,
    this.narration,
    this.status,
    this.demandDetailId,
    this.receivedFrom,
    this.drawnOn,
    this.chequeDate,
    this.depositedIn,
  });

  factory Receipt.fromJson(Map<String, dynamic> j) => Receipt(
        id: j['id'] as int,
        receiptNo: j['receipt_no'] as String?,
        receiptDate: j['receipt_date'] as String,
        memberId: j['member_id'] as int,
        memberName: j['member_name'] as String?,
        accountId: j['account_id'] as int?,
        accountNumber: j['account_number'] as String?,
        accountBalance: (j['account_balance'] as num?)?.toDouble(),
        amount: (j['amount'] as num).toDouble(),
        paymentMode: j['payment_mode'] as String,
        referenceNo: j['reference_no'] as String?,
        narration: j['narration'] as String?,
        status: j['status'] as String?,
        demandDetailId: j['demand_detail_id'] as int?,
        receivedFrom: j['received_from'] as String?,
        drawnOn: j['drawn_on'] as String?,
        chequeDate: j['cheque_date'] as String?,
        depositedIn: j['deposited_in'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'receipt_no': receiptNo,
        'receipt_date': receiptDate,
        'member_id': memberId,
        'member_name': memberName,
        'account_id': accountId,
        'account_number': accountNumber,
        'account_balance': accountBalance,
        'amount': amount,
        'payment_mode': paymentMode,
        'reference_no': referenceNo,
        'narration': narration,
        'status': status,
        'demand_detail_id': demandDetailId,
        'received_from': receivedFrom,
        'drawn_on': drawnOn,
        'cheque_date': chequeDate,
        'deposited_in': depositedIn,
      };
}
