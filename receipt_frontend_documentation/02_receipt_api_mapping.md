# Receipt Module — UI ↔ API Field Mapping

> Agent: API Integration Specialist + Validation Specialist  
> Date: 2026-06-03

---

## POST /receipts/ — Create Receipt

### Request: UI Field → API Field

| UI Element | API Field | Type | Required | Validation (frontend) | Validation (backend) |
|------------|-----------|------|----------|-----------------------|----------------------|
| Date picker | `receipt_date` | `"YYYY-MM-DD"` | Yes | Must be selectable date | Valid date |
| Member dropdown | `member_id` | `integer` | Yes | Not null | Member must exist; must have ledger_id |
| Account dropdown | `account_id` | `integer \| null` | No | — | If set, must be valid account |
| Amount field | `amount` | `"1500.00"` (string) | Yes | > 0, numeric | > 0 |
| Payment mode dropdown | `payment_mode` | `"CASH" \| "BANK" \| "UPI" \| "ONLINE"` | Yes | One of 4 values | Enum |
| Reference No field | `reference_no` | `string \| null` | No | Max 100 chars | — |
| Narration field | `narration` | `string \| null` | No | — | — |

### Request Example (CASH, no account)

```json
{
  "receipt_date": "2026-06-03",
  "member_id": 1,
  "account_id": null,
  "amount": "1500.00",
  "payment_mode": "CASH",
  "reference_no": null,
  "narration": "Monthly thrift deposit"
}
```

### Response: API Field → UI Action

| API Field | Action |
|-----------|--------|
| `message` | Ignored (SnackBar shows a static success message) |
| `receipt_id` | Not displayed |
| `receipt_no` | Shown in success SnackBar (future: navigate to detail) |
| `journal_id` | Not displayed |
| `amount` | Not displayed |
| `payment_mode` | Not displayed |

---

## PUT /receipts/{id} — Update Receipt

Same request schema as POST. Additional constraint:

| Rule | Enforcement |
|------|-------------|
| `member_id` cannot change | UI shows read-only field; `member_id` from `widget.receipt` always sent |

### Request Example (update amount + payment mode)

```json
{
  "receipt_date": "2026-06-03",
  "member_id": 1,
  "account_id": null,
  "amount": "2000.00",
  "payment_mode": "BANK",
  "reference_no": "CHQ-20001",
  "narration": "FD deposit"
}
```

---

## GET /receipts/ — List Receipts

### Response → DataTable Column Mapping

| API Field | Column Label | Format | Null Handling |
|-----------|-------------|--------|---------------|
| `receipt_no` | Receipt No | Monospace `"RCP-20260603-00001"` | `"-"` |
| `receipt_date` | Date | `DD/MM/YYYY` | `"-"` |
| `member_name` | Member | Direct string | `"-"` |
| `account_number` | Account | Direct string | `"-"` |
| `amount` | Amount | `₹1,500.00` (Indian format) | `"-"` |
| `payment_mode` | Mode | Icon + label | `"-"` |
| `status` | Status | Coloured badge | `"-"` |
| `id` | (hidden) | Passed in edit callback | — |
| `member_id` | (hidden) | Passed in edit callback | — |
| `account_id` | (hidden) | Passed in edit callback | — |
| `reference_no` | (hidden) | Passed in edit callback | — |
| `narration` | (hidden) | Passed in edit callback | — |

---

## GET /receipts/{id} — Single Receipt (used by edit pre-fill)

### Response → Form Field Mapping

| API Field | Form Widget | Pre-fill logic |
|-----------|------------|----------------|
| `receipt_date` | Date picker | `DateTime.parse(r["receipt_date"])` |
| `member_id` | Read-only label (edit) | `r["member_id"]` → ID; `r["member_name"]` → display |
| `account_id` | Account dropdown | `r["account_id"]` pre-selects dropdown |
| `amount` | Amount field | `r["amount"].toString()` |
| `payment_mode` | Mode dropdown | `r["payment_mode"] ?? "CASH"` |
| `reference_no` | Reference field | `r["reference_no"] ?? ""` |
| `narration` | Narration field | `r["narration"] ?? ""` |
| `receipt_no` | Info banner | `r["receipt_no"]` |
| `status` | Info banner | `r["status"]` |

> Note: The edit form uses the Map passed directly from the receipt list row (GET /receipts/ response). It does NOT make a separate GET /receipts/{id} call. This is acceptable because the list response includes all fields needed for pre-fill.

---

## Error Code Mapping

| HTTP Status | API `detail` | UI display |
|-------------|-------------|------------|
| 422 | `"amount must be greater than 0"` | Inline error box in form |
| 422 | `"Member ID 999 not found"` | Inline error box |
| 422 | `"Member 'John' has no ledger configured..."` | Inline error box |
| 422 | `"Changing the member on an existing receipt is not allowed."` | Inline error box (should not occur — UI prevents it) |
| 404 | `"Receipt #99 not found"` | Inline error box |
| 500 | `"Receipt creation failed: ..."` | Inline error box |
| Network error | (no response) | Inline error box with "Network error: ..." |

---

## Amount Format Contract

| Direction | Format | Example |
|-----------|--------|---------|
| Frontend → Backend | Decimal string | `"1500.00"` |
| Backend → Frontend (list) | Float | `1500.0` |
| Backend → Frontend (display) | Formatted string | `₹1,500.00` |

**Key detail:** `double.toStringAsFixed(2)` in Dart produces `"1500.00"` which matches the backend's `Decimal` field expectation.
