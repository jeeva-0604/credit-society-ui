# Receipt Module Frontend — Raw vs Enhanced

> Agent: Receipt UI Analyst + API Integration Specialist  
> Date: 2026-06-03  
> Scope: Flutter Frontend Only

---

## Issue 1 — Wrong API URLs in receipt_service.dart (CRITICAL)

| Field | Detail |
|-------|--------|
| **File** | `lib/service/receipt_service.dart` |
| **Lines** | 11 (POST URL), 32 (PUT URL) |
| **Root Cause** | URLs pointed to non-existent paths `/receipts/receipt` and `/receipts/receipt/$id` |

### Before (broken)

```dart
final url = Uri.parse("$baseUrl/receipts/receipt");       // POST
final url = Uri.parse("$baseUrl/receipts/receipt/$id");   // PUT
```

**Runtime result:** HTTP 404 Not Found on every create and every update.

### After (fixed)

```dart
final url = Uri.parse("$baseUrl/receipts/");    // POST
final url = Uri.parse("$baseUrl/receipts/$id"); // PUT
```

**Impact:** Create and Update now hit the correct endpoints.

---

## Issue 2 — Amount sent as double, backend expects decimal string (CRITICAL)

| Field | Detail |
|-------|--------|
| **File** | `lib/society/ReceiptScreen.dart` line 80 |
| **Root Cause** | `double.tryParse(amountCtrl.text)` passed directly as a JSON number; backend Pydantic validator expects a decimal string like `"1500.00"` |

### Before (broken)

```dart
"amount": double.tryParse(amountCtrl.text) ?? 0,   // sends 1500.0 as JSON number
```

### After (fixed)

```dart
final amount = double.tryParse(_amountCtrl.text.trim())!;
"amount": amount.toStringAsFixed(2),   // sends "1500.00" as JSON string
```

**Impact:** Backend correctly parses and validates the amount.

---

## Issue 3 — Navigator.pop does not work when ReceiptScreen is embedded

| Field | Detail |
|-------|--------|
| **File** | `lib/society/ReceiptScreen.dart` line 93 |
| **Root Cause** | `Navigator.pop(context)` is called but ReceiptScreen is rendered as an inline widget inside HomeScreen's Column (not pushed onto the Navigator stack). Pop silently does nothing. |

### Before (broken)

```dart
Navigator.pop(context);   // no-op when screen is embedded
```

### After (fixed)

```dart
// ReceiptScreen receives onSaved callback from parent
if (widget.onSaved != null) {
  widget.onSaved!();
} else {
  Navigator.pop(context);   // fallback for standalone use
}
```

HomeScreen's `_onReceiptSaved()` sets state to hide the form and rebuilds ReceiptListScreen with `UniqueKey()`.

**Impact:** After save, the form dismisses and the receipt list reloads correctly.

---

## Issue 4 — Receipt list never refreshes after create/edit

| Field | Detail |
|-------|--------|
| **File** | `lib/screens/home_screen.dart`, `lib/society/ReceiptListScreen.dart` |
| **Root Cause** | HomeScreen mounted ReceiptListScreen once in `_initNavItems()`. After save, it went back to the same stale widget instance — `initState` never re-ran, so `loadReceipts` never fired again. |

### After (fixed)

```dart
// HomeScreen._onReceiptSaved():
_activeScreen = ReceiptListScreen(
  key: UniqueKey(),   // forces Flutter to create fresh State → initState → loadReceipts
  onNewReceipt: ...,
  onEditReceipt: ...,
);
```

**Impact:** Receipt list always shows up-to-date data after every create or edit.

---

## Issue 5 — ONLINE payment mode missing from dropdown

| Field | Detail |
|-------|--------|
| **File** | `lib/society/ReceiptScreen.dart` line 161 |
| **Root Cause** | Dropdown items were `["CASH", "BANK", "UPI"]`. Backend accepts `CASH`, `BANK`, `UPI`, `ONLINE`. |

### Before

```dart
items: ["CASH", "BANK", "UPI"].map(...)
```

### After

```dart
static const List<String> _paymentModes = ["CASH", "BANK", "UPI", "ONLINE"];
items: _paymentModes.map(...)
```

**Impact:** ONLINE receipts can now be created.

---

## Issue 6 — No date picker: receipt date was hardcoded

| Field | Detail |
|-------|--------|
| **File** | `lib/society/ReceiptScreen.dart` |
| **Root Cause** | No date field in the form. Date defaulted to `DateTime.now()`. Backend `receipt_date` field is required. |

### After (fixed)

```dart
InkWell(
  onTap: _pickDate,
  child: InputDecorator(
    decoration: InputDecoration(labelText: "Receipt Date *", ...),
    child: Text(_displayDate(_receiptDate)),
  ),
),
```

`showDatePicker` populates `_receiptDate`. Value is formatted as `YYYY-MM-DD` before sending.

**Impact:** User can select any date; API receives a correct date string.

---

## Issue 7 — Narration field defined but never rendered

| Field | Detail |
|-------|--------|
| **File** | `lib/society/ReceiptScreen.dart` |
| **Root Cause** | `narrationCtrl` was declared and populated from edit data, but no `TextFormField` widget rendered it in the form. |

### After (fixed)

```dart
TextFormField(
  controller: _narrationCtrl,
  decoration: const InputDecoration(labelText: "Narration", border: OutlineInputBorder()),
  maxLines: 2,
),
```

**Impact:** Narration is shown, editable, and sent to the API.

---

## Issue 8 — No form validators: invalid data submitted silently

| Field | Detail |
|-------|--------|
| **File** | `lib/society/ReceiptScreen.dart` |
| **Root Cause** | Amount and member fields had no `validator`. Empty/zero/negative amounts and null members were sent to the backend. |

### After (fixed)

- Amount: required, must parse as a valid decimal, must be > 0
- Member: required (not null)
- Payment mode: required (always has a value, but validated)

**Impact:** Client-side validation prevents bad requests and gives immediate user feedback.

---

## Issue 9 — Member editable on edit (backend forbids it)

| Field | Detail |
|-------|--------|
| **File** | `lib/society/ReceiptScreen.dart` |
| **Root Cause** | Member dropdown was shown as editable even in edit mode. Backend returns HTTP 422: "Changing the member on an existing receipt is not allowed." |

### After (fixed)

```dart
if (_isEdit) {
  // Show locked InputDecorator with member name
  return InputDecorator(
    decoration: InputDecoration(fillColor: AppColors.grey_200, filled: true, ...),
    child: Text(memberName),
  );
}
```

**Impact:** Member cannot be changed on edit; matches backend contract.

---

## Issue 10 — No loading state, no error display

| Field | Detail |
|-------|--------|
| **File** | `lib/society/ReceiptScreen.dart`, `lib/society/ReceiptListScreen.dart` |
| **Root Cause** | Errors thrown by API calls were caught and printed but never shown to the user. No `_isSaving` guard. |

### After (fixed)

- `_isSaving` bool disables the submit button and shows a `CircularProgressIndicator` during the API call
- `_errorMessage` string renders an error box inline below the form
- `_error` in list screen renders an error panel with Retry button
- Empty list shows empty-state widget with call-to-action

**Impact:** No silent failures; no duplicate submissions; user always knows what happened.

---

## Issue 11 — Receipt list missing columns and formatting

| Field | Detail |
|-------|--------|
| **File** | `lib/society/ReceiptListScreen.dart` |
| **Root Cause** | `receipt_no` column absent; amount shown as raw float; date shown as ISO string; `account_number` shown as empty string when null; status not shown |

### After (fixed)

| Column | Fix |
|--------|-----|
| `receipt_no` | Added as first column, monospace font |
| `receipt_date` | Formatted as DD/MM/YYYY |
| `amount` | Formatted as ₹1,500.00 (Indian number format) |
| `account_number` | Shows "-" when null |
| `status` | Coloured badge (green/red/orange) |
| `payment_mode` | Icon + label badge |
