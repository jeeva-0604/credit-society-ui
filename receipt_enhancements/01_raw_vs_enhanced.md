# Receipt Module Frontend — Raw vs Enhanced

> Agent: Receipt UI Analyst + API Integration Specialist  
> Date: 2026-06-03 (Pass 1) | Updated: 2026-06-03 (Pass 2 — Multi-Agent Audit)
> Scope: Flutter Frontend Only

---

> **Pass 2 Note:** Issues 12–31 were found and fixed by a 43-agent multi-agent audit run after Pass 1. Each agent independently audited a file, findings were adversarially verified by a second set of agents, then fixes were applied and QA-verified.

---

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

---

---

# Pass 2 Findings — Multi-Agent Audit (2026-06-03)

> 43 agents · 33 raw findings · 20 confirmed · 5 files patched

---

## Issue 12 — setState-after-dispose in _loadAccounts (CRITICAL)

| Field | Detail |
|-------|--------|
| **File** | `lib/society/ReceiptScreen.dart` |
| **Root Cause** | `_loadAccounts()` called `setState()` after an `await` with no `mounted` guard. Fast navigation away during the fetch would crash with "setState called after dispose". |

### Before (broken)
```dart
Future<void> _loadAccounts(int memberId) async {
  setState(() => _accountsLoading = true);
  final accounts = await MemberService().getAccounts(memberId); // no mounted check
  setState(() { _accounts = accounts; _accountsLoading = false; }); // crash risk
}
```

### After (fixed)
```dart
Future<void> _loadAccounts(int memberId) async {
  if (!mounted) return;
  setState(() => _accountsLoading = true);
  try {
    final accounts = await MemberService().getAccounts(memberId);
    if (!mounted) return;
    setState(() { _accounts = accounts; _accountsLoading = false; });
  } catch (_) {
    if (!mounted) return;
    setState(() => _accountsLoading = false);
  }
}
```

**Impact:** No crash when user navigates away during account load.

---

## Issue 13 — First-frame form flicker (_isInitialising = false on start)

| Field | Detail |
|-------|--------|
| **File** | `lib/society/ReceiptScreen.dart` |
| **Root Cause** | `_isInitialising` was initialised to `false`, so the form rendered for one frame before `initState` set it to `true`. Visible as a one-frame flicker of an incomplete form. |

### Before
```dart
bool _isInitialising = false;
```

### After
```dart
bool _isInitialising = true;   // spinner shown from frame 0
```

**Impact:** No flicker; spinner appears immediately until data is loaded.

---

## Issue 14 — Save button stays disabled after embedded save (MEDIUM)

| Field | Detail |
|-------|--------|
| **File** | `lib/society/ReceiptScreen.dart` |
| **Root Cause** | On success, `widget.onSaved!()` was called while `_isSaving = true`. In embedded mode, the parent replaces the widget, but if it doesn't, the button remains a spinner permanently. |

### After (fixed)
```dart
setState(() => _isSaving = false);   // re-enable button first
widget.onSaved!();                   // then notify parent
```

**Impact:** Button always re-enables; no permanently-spinning save button.

---

## Issue 15 — Deprecated Color.withOpacity() in ReceiptScreen (LOW)

| Field | Detail |
|-------|--------|
| **File** | `lib/society/ReceiptScreen.dart` (5 sites) |
| **Root Cause** | Flutter 3.27+ deprecates `.withOpacity(x)` in favour of `.withValues(alpha: x)`. Produces build warnings. |

### After (fixed)
All 5 call sites replaced: `disabledBackgroundColor`, info banner fill/border, error box fill/border.

```dart
// Before
AppColors.grey.withOpacity(0.15)
// After
AppColors.grey.withValues(alpha: 0.15)
```

---

## Issue 16 — Scroll nesting wrong: RefreshIndicator never triggers (HIGH)

| Field | Detail |
|-------|--------|
| **File** | `lib/society/ReceiptListScreen.dart` |
| **Root Cause** | The vertical `SingleChildScrollView` was nested *inside* the horizontal one. `RefreshIndicator` only works when the scrollable that absorbs the drag is its direct child. The horizontal wrapper intercepted all scroll gestures. |

### Before (broken)
```dart
RefreshIndicator(
  child: SingleChildScrollView(          // horizontal — intercepts drag
    scrollDirection: Axis.horizontal,
    child: SingleChildScrollView(        // vertical inside
      child: DataTable(...)
    ),
  ),
)
```

### After (fixed)
```dart
RefreshIndicator(
  child: SingleChildScrollView(          // vertical outer — receives pull
    physics: AlwaysScrollableScrollPhysics(),
    child: SingleChildScrollView(        // horizontal inner
      scrollDirection: Axis.horizontal,
      child: DataTable(...)
    ),
  ),
)
```

**Impact:** Pull-to-refresh now works correctly.

---

## Issue 17 — Untyped receipt list: runtime cast exceptions (MEDIUM)

| Field | Detail |
|-------|--------|
| **File** | `lib/society/ReceiptListScreen.dart` |
| **Root Cause** | `List _receipts` was untyped (`dynamic`). If the API returned any non-Map entry, the DataRow builder would throw a runtime cast exception and crash the list. |

### After (fixed)
```dart
List<Map<String, dynamic>> _receipts = [];

// In _load():
_receipts = raw.whereType<Map<String, dynamic>>().toList();
```

**Impact:** Non-Map entries are silently filtered; no runtime cast crash.

---

## Issue 18 — Empty-state Create button crashes if onNewReceipt not wired (MEDIUM)

| Field | Detail |
|-------|--------|
| **File** | `lib/society/ReceiptListScreen.dart` |
| **Root Cause** | Empty-state button called `widget.onNewReceipt!()` with a hard `!`. If the parent didn't pass the callback, this threw a null dereference. |

### After (fixed)
```dart
onPressed: widget.onNewReceipt ?? () {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Navigation not available in this context.')),
  );
},
```

**Impact:** Graceful fallback instead of crash when callback is null.

---

## Issue 19 — Member name overflows DataTable column (MEDIUM)

| Field | Detail |
|-------|--------|
| **File** | `lib/society/ReceiptListScreen.dart` |
| **Root Cause** | Long member names had no width constraint; they pushed all subsequent columns off-screen even inside a horizontal scroll view. |

### After (fixed)
```dart
DataCell(SizedBox(
  width: 140,
  child: Text(r["member_name"] ?? "-",
    overflow: TextOverflow.ellipsis,
    maxLines: 1,
  ),
)),
```

**Impact:** Long names are truncated with ellipsis; column widths stay consistent.

---

## Issue 20 — _fmtDate crashes on non-String receipt_date (LOW)

| Field | Detail |
|-------|--------|
| **File** | `lib/society/ReceiptListScreen.dart` |
| **Root Cause** | `_fmtDate(String? iso)` assumed the field was always a String. If the backend returned a date as a DateTime object or number, the function would throw. |

### After (fixed)
```dart
String _fmtDate(dynamic raw) {
  if (raw == null) return "-";
  if (raw is! String) return raw.toString();
  // ... normal ISO parsing
}
```

---

## Issue 21 — _fmtAmount does not handle negative amounts (LOW)

| Field | Detail |
|-------|--------|
| **File** | `lib/society/ReceiptListScreen.dart` |
| **Root Cause** | Indian number formatting operated on the raw value; a negative amount like `-1500.00` produced `₹-1,500.00` with the minus sign in the wrong position. |

### After (fixed)
```dart
final isNeg = d < 0;
final abs = d.abs();
// ... format abs ...
return isNeg ? "-₹$formatted" : "₹$formatted";
```

---

## Issue 22 — Deprecated Color.withOpacity() in ReceiptListScreen (LOW)

| Field | Detail |
|-------|--------|
| **File** | `lib/society/ReceiptListScreen.dart` (4 sites) |

Fixed at: error icon, DataTable heading row, `_StatusBadge` fill and border.

```dart
color.withOpacity(0.12)  →  color.withValues(alpha: 0.12)
color.withOpacity(0.45)  →  color.withValues(alpha: 0.45)
AppColors.primary.withOpacity(0.08)  →  AppColors.primary.withValues(alpha: 0.08)
AppColors.error.withOpacity(0.7)     →  AppColors.error.withValues(alpha: 0.7)
```

---

## Issue 23 — PUT URL missing trailing slash (MEDIUM)

| Field | Detail |
|-------|--------|
| **File** | `lib/service/receipt_service.dart` |
| **Root Cause** | FastAPI redirects `PUT /receipts/$id` (no slash) to `PUT /receipts/$id/` (with slash), but the HTTP client follows with GET, converting the PUT to a GET — silently returning 200 with wrong semantics. |

### Before
```dart
Uri.parse("$baseUrl/receipts/$id")
```

### After
```dart
Uri.parse("$baseUrl/receipts/$id/")
```

---

## Issue 24 — getReceipts / getReceiptById swallowed error detail (MEDIUM)

| Field | Detail |
|-------|--------|
| **File** | `lib/service/receipt_service.dart` |
| **Root Cause** | GET methods threw generic exceptions on non-200 status without extracting the `detail` field from FastAPI's JSON error body. UI showed generic messages. |

### After (fixed)
```dart
final body = jsonDecode(response.body);
final detail = body is Map ? (body["detail"] ?? "Unknown error") : "Unknown error";
throw Exception(detail);
```

---

## Issue 25 — Auth login sent credentials in JSON body, not query params (CRITICAL)

| Field | Detail |
|-------|--------|
| **File** | `lib/service/auth_service.dart` |
| **Root Cause** | A workflow agent changed the login call to use a JSON body (`body: jsonEncode({...})`). The FastAPI backend endpoint is `POST /auth/login?email=...&password=...` — it reads query parameters, not a JSON body. This caused all login attempts to fail with 422. |

### Before (broken — introduced by workflow agent)
```dart
final url = Uri.parse("$_baseUrl/auth/login");
final response = await http.post(url,
  headers: {"Content-Type": "application/json"},
  body: jsonEncode({"email": email, "password": password}),
);
```

### After (fixed)
```dart
final url = Uri.parse("$_baseUrl/auth/login")
    .replace(queryParameters: {"email": email, "password": password});
final response = await http.post(url,
  headers: {"Content-Type": "application/json"},
);
```

**Impact:** Login succeeds; JWT token is obtained and stored for subsequent API calls.

---

## Issue 26 — Stale ReceiptListScreen cached in nav items (HIGH)

| Field | Detail |
|-------|--------|
| **File** | `lib/screens/home_screen.dart` (receipt section only) |
| **Root Cause** | `_initNavItems()` created a static `ReceiptListScreen` instance at startup with inline callbacks. Every time the user clicked "Receipts List" in the nav menu, they got the same stale widget instance — `initState` never re-ran, so the list never refreshed from the server. |

### After (fixed)
```dart
// _initNavItems: placeholder only
SubMenuItem(title: 'Receipts List', screen: const SizedBox.shrink())

// onTap handler: fresh instance every time
else if (sub.title == 'Receipts List') {
  setState(() => _activeScreen = ReceiptListScreen(
    key: UniqueKey(),
    onNewReceipt: ...,
    onEditReceipt: ...,
  ));
}
```

**Impact:** Every nav click loads a fresh list from the API.

---

## Issue 27 — Receipt form not cleared on module switch (MEDIUM)

| Field | Detail |
|-------|--------|
| **File** | `lib/screens/home_screen.dart` (receipt section only) |
| **Root Cause** | `onDestinationSelected` reset member/loan form flags but not `_showNewReceiptForm` or `_editingReceipt`. Navigating to another module and back left the receipt form open in its previous state. |

### After (fixed)
```dart
onDestinationSelected: (index) {
  setState(() {
    // existing resets...
    _showNewReceiptForm = false;   // NEW
    _editingReceipt = null;        // NEW
  });
},
```

**Impact:** Receipt form always starts fresh when the Receipts module is re-entered.

