class CollectionItem {
  int memberId;
  int demandDetailId;
  int? loanId;
  int? scheduleId;

  double thriftAmount;
  double principalAmount;
  double interestAmount;
  double otherCharges;

  CollectionItem({
    required this.memberId,
    required this.demandDetailId,
    this.loanId,
    this.scheduleId,
    this.thriftAmount = 0,
    this.principalAmount = 0,
    this.interestAmount = 0,
    this.otherCharges = 0,
  });

  double total() {
    return thriftAmount + principalAmount + interestAmount + otherCharges;
  }

  Map<String, dynamic> toJson() => {
    "member_id": memberId,
    "demand_detail_id": demandDetailId,
    "loan_id": loanId,
    "schedule_id": scheduleId,
    "thrift_amount": thriftAmount,
    "principal_amount": principalAmount,
    "interest_amount": interestAmount,
    "other_charges": otherCharges,
  };
}