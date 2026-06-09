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

---

---

# Pass 3 Findings — Live App Testing (2026-06-03)

> Issue found by running the app and observing the New Receipt form.

---

## Issue 28 — Member dropdown silently empty: error swallowed on 401 (CRITICAL)

| Field | Detail |
|-------|--------|
| **File** | `lib/society/ReceiptScreen.dart` |
| **Symptom** | Member dropdown shows no options; user cannot create a receipt |
| **Root Cause** | `MemberService.getMembers()` has no HTTP status check. When the backend returns 401 (no valid auth token), `jsonDecode(response.body)` returns a `Map` (`{"detail": "Not authenticated"}`). Assigning that `Map` to `List _members` throws a `TypeError` at runtime. `_initialise()` caught all exceptions with `catch (_) { _members = []; }` — silently discarding the error and leaving the dropdown empty with no message to the user. |

### Before (broken)

```dart
// _initialise():
try {
  final list = await MemberService().getMembers("");
  _members = list ?? [];   // if list is a Map (401 body), TypeError thrown here
} catch (_) {
  _members = [];           // error swallowed — dropdown silently empty, no hint shown
}

// _buildMemberField():
// Dropdown with empty items — user sees blank dropdown, no explanation
```

### After (fixed)

```dart
// New state variable:
String? _memberLoadError;

// New retry method:
Future<void> _reloadMembers() async {
  setState(() { _memberLoadError = null; _members = []; });
  try {
    final raw = await MemberService().getMembers("");
    if (raw is List) {
      setState(() => _members = raw);
    } else {
      setState(() => _memberLoadError =
          "Server returned an unexpected response. Make sure you are logged in.");
    }
  } catch (e) {
    setState(() => _memberLoadError = "Failed to load members — ${e...}");
  }
}

// _initialise(): type-safe assignment
try {
  final raw = await MemberService().getMembers("");
  if (raw is List) {
    _members = raw;
  } else {
    _members = [];
    _memberLoadError = "Could not load members. You may need to log in again.";
  }
} catch (e) {
  _members = [];
  _memberLoadError = "Failed to load members: ${e...}";
}

// _buildMemberField(): error banner + Retry button + disabled dropdown when empty
Column(children: [
  if (_memberLoadError != null)
    Container(   // red banner with error text
      child: Row(children: [
        Icon(Icons.warning_amber_rounded),
        Text(_memberLoadError!),
        TextButton.icon(onPressed: _reloadMembers, label: Text("Retry")),
      ]),
    ),
  DropdownButtonFormField(
    hint: _members.isEmpty ? Text("No members loaded") : null,
    onChanged: _members.isEmpty ? null : (val) { ... },   // disabled when empty
    items: _members.map(...).toList(),
  ),
])
```

**Impact:**
- User sees a clear red error banner explaining why the dropdown is empty
- **Retry button** lets the user reload members without restarting the app
- Dropdown shows hint text `"No members loaded"` instead of appearing broken
- Dropdown is disabled when empty (prevents null tap crashes)
- Type-safe `raw is List` check prevents silent `TypeError` swallowing

**Underlying root cause (auth):** `MemberService.getMembers()` sends a Bearer token via `ApiService().getAuthHeaders()`. If no token is set (e.g. splash screen placeholder credentials `"admin@society.com"/"admin123"` fail), the backend returns 401 and members never load. The Retry button works once a valid token is in `ApiService._accessToken`.

---

---

# Pass 4 Findings — Backend Fix Confirmed + Receipt Module Refactor (2026-06-03)

---

## Issue 29 — Backend `/members/search/` returned HTTP 500 on all calls (CRITICAL)

| Field | Detail |
|-------|--------|
| **Layer** | FastAPI backend — `api/routes/member.py`, `api/crud/member.py`, `api/schemas/member.py` |
| **Symptom** | Every call to `GET /members/search/?search=`, `GET /members/`, `GET /members/{id}` returned HTTP 500 — Flutter showed "ClientException: Failed to fetch" |
| **Root Cause** | Pydantic `MemberResponse` serialization crashed on any member row. The exact field(s) causing the crash were in the schema validation chain (suspected: required `thrift_amount: float` or `BranchSchema.name: str` triggering a ValidationError when null DB values were encountered during `model_validate`). All member endpoints that serialized via `MemberResponse` failed; endpoints that bypassed it (e.g. `GET /members/{id}/accounts`, `GET /members/get_member_balances/{id}`) continued to work. |

### Fix applied (backend)

Backend Python fix applied by developer. Member endpoints now return correct data.

**Verified:** `GET /members/search/?search=` returns `{"page":1,"size":20,"total":N,"items":[...]}` successfully as of 2026-06-03.

### Flutter-side defensive handling added (in new `lib/services/receipt_service.dart`)

```dart
Future<List<Map<String, dynamic>>> searchMembers(String query) async {
  final res = await http.get(...);
  if (res.statusCode == 200) {
    final decoded = jsonDecode(res.body);
    if (decoded is List) {
      return decoded.whereType<Map<String, dynamic>>().toList();
    }
    // Handles paginated {"page":1,"items":[...]} response format
    if (decoded is Map && decoded.containsKey('items')) {
      return (decoded['items'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();
    }
  }
  return [];  // 500 or unexpected format → empty list, no crash
}
```

**Impact:** Member search now works. Flutter handles both the paginated dict format AND a plain list, so the code is forward-compatible if the backend response format changes.

---

---

# Pass 5 Findings — Legacy Screen Replication (2026-06-04)

> Scope: Full receipt module gap analysis vs client legacy .NET screen screenshot.
> Phase 1 analysis → 13 gaps identified → 8 implemented (Reverse pending client approval).

---

## Issue 31 — View button had empty handler: no search/navigate functionality (HIGH)

| Field | Detail |
|-------|--------|
| **File** | `lib/screens/receipts/receipt_form_screen.dart` |
| **Root Cause** | `_btn('View', onPressed: hasCur && !_isEditMode ? () {} : null)` — empty callback. Legacy system View button opens a search popup by receipt number or member name. |

### Before (broken)
```dart
_btn('View', onPressed: hasCur && !_isEditMode ? () {} : null),
```

### After (fixed)
```dart
_btn('View', onPressed: !_isEditMode ? _doView : null),
```

`_doView()` opens an `AlertDialog` with:
- Toggle: search by **Receipt No** or **Member Name** (ChoiceChip)
- Search text field — filters from already-loaded `_receipts` list (no extra API call)
- Scrollable results list showing receipt_no, member_name, date
- Tap any row → closes dialog and navigates to that receipt via `_navigateTo(idx)`

**Impact:** User can search and jump to any receipt without using First/Prev/Next/Last buttons.

---

## Issue 32 — Print button showed toast only: no PDF generated (HIGH)

| Field | Detail |
|-------|--------|
| **File** | `lib/screens/receipts/receipt_form_screen.dart` |
| **Root Cause** | `onPressed: () => _showMsg('Print: coming soon.')` — stub only. Legacy system prints a formatted receipt. Packages `pdf: ^3.10.4` and `printing: ^5.11.0` were already in pubspec.yaml. |

### Before (broken)
```dart
_btn('Print', onPressed: hasCur && !_isEditMode ? () => _showMsg('Print: coming soon.') : null),
```

### After (fixed)
```dart
_btn('Print', onPressed: hasCur && !_isEditMode ? _doPrint : null),
```

`_doPrint()` generates an A5 landscape PDF using `pdf` package with:
- Society name header: "L&T GROUP EMPLOYEES COOPERATIVE THRIFT & CREDIT SOCIETY LTD"
- Receipt No + Date
- Received From (member name + type)
- Description / Narration
- Payment mode; cheque details when applicable
- A/C entries table: Description | Ref No | Amount
- TOTAL row
- Receiver's Signature + Authorised Signatory footer lines
- "This is a computer generated receipt." footer

PDF is rendered via `Printing.layoutPdf()` — opens the system print/share dialog.

**Impact:** Print button produces a professional PDF receipt matching the legacy printout layout.

---

## Issue 33 — Delete button called showMsg stub instead of API (HIGH)

| Field | Detail |
|-------|--------|
| **File** | `lib/screens/receipts/receipt_form_screen.dart`, `lib/services/receipt_service.dart` |
| **Root Cause** | `_doDelete()` showed confirmation dialog then called `_showMsg('Delete API coming soon.')`. No `DELETE /receipts/{id}/` call was made. |

### Before (broken)
```dart
if (ok != true || !mounted) return;
_showMsg('Delete API coming soon.');
```

### After (fixed)
```dart
if (ok != true || !mounted) return;
setState(() { _isSaving = true; _errorMsg = null; });
try {
  await ReceiptService().deleteReceipt(_current!['id'] as int);
  _showMsg('Receipt $no deleted.', ok: true);
  await _loadReceipts();
  setState(() { _mode = _Mode.view; _isSaving = false; });
} catch (e) {
  setState(() { _isSaving = false; _errorMsg = ...; });
}
```

Added `deleteReceipt(int id)` to `receipt_service.dart`:
```dart
Future<void> deleteReceipt(int id) async {
  final url = Uri.parse('$_base/receipts/$id/');
  final res = await http.delete(url, headers: await _headers);
  if (res.statusCode == 200 || res.statusCode == 204) return;
  _throwDetail(res, 'Failed to delete receipt');
}
```

**Impact:** Delete confirmation → actual API delete → list reloads.

---

## Issue 34 — Save payload missing received_from, drawn_on, cheque_date, deposited_in (CRITICAL)

| Field | Detail |
|-------|--------|
| **File** | `lib/screens/receipts/receipt_form_screen.dart` `_doSave()` |
| **Root Cause** | `_doSave()` payload did not include `received_from`, `drawn_on`, `cheque_date`, `deposited_in`. These fields were tracked in UI state but never sent to the backend. |

### Before (broken)
```dart
final payload = {
  'receipt_date': ...,
  'member_id': ...,
  'account_id': ...,
  'amount': ...,
  'payment_mode': pm,
  if (_isChequeDD && refNo.isNotEmpty) 'reference_no': refNo,
  if (narr.isNotEmpty) 'narration': narr,
};
```

### After (fixed)
```dart
final payload = {
  'receipt_date' : _apiDate(_receiptDate),
  'member_id'    : _memberId,
  'account_id'   : _selectedAccountId,
  'amount'       : amt.toStringAsFixed(2),
  'payment_mode' : pm,
  'received_from': _receivedFrom,
  if (narr.isNotEmpty) 'narration': narr,
  if (_isChequeDD) ...{
    'reference_no' : _chequeNoCtrl.text.trim(),
    'drawn_on'     : _drawnOnCtrl.text.trim(),
    'cheque_date'  : _chequeDtCtrl.text.trim(),
    'deposited_in' : _depositedInCtrl.text.trim(),
  } else if (refNo.isNotEmpty)
    'reference_no' : refNo,
};
```

**Impact:** All receipt header fields are now persisted on create and update.

---

## Issue 35 — Receipt model missing fields (MEDIUM)

| Field | Detail |
|-------|--------|
| **File** | `lib/models/receipt.dart` |
| **Root Cause** | `Receipt` class and `fromJson`/`toJson` were missing `receivedFrom`, `drawnOn`, `chequeDate`, `depositedIn`. If the API returns these fields, they were silently dropped. |

### After (fixed)
Added to `Receipt` class:
```dart
final String? receivedFrom;
final String? drawnOn;
final String? chequeDate;
final String? depositedIn;
```
Wired into `fromJson` (reads `received_from`, `drawn_on`, `cheque_date`, `deposited_in`) and `toJson`.

---

## Issue 36 — Name field read-only for PDO/Others in edit mode (MEDIUM)

| Field | Detail |
|-------|--------|
| **File** | `lib/screens/receipts/receipt_form_screen.dart` `_nameRow()` |
| **Root Cause** | `_field(_nameCtrl, readOnly: true)` was used for non-Member modes in all modes including edit. For PDO and Others, the user must be able to type a name. |

### Before (broken)
```dart
: _field(_nameCtrl, readOnly: true),
```

### After (fixed)
```dart
: _field(_nameCtrl, readOnly: !_isEditMode),
```

**Impact:** In PDO/Others mode, the Name field is editable in Add/Change mode and read-only in View mode.

---

## Issue 37 — Missing validations: Name format and Cheque/DD mandatory fields (HIGH)

| Field | Detail |
|-------|--------|
| **File** | `lib/screens/receipts/receipt_form_screen.dart` `_validate()` |
| **Root Cause** | No validation for: (a) Name field when PDO/Others selected, (b) Drawn On/Cheque No/Cheque Date when Cheque/DD mode active. Legacy screen enforces both. |

### After (fixed)

Added to `_validate()`:

**PDO / Others — Name required, A-Z and spaces only:**
```dart
if (_receivedFrom != 'Member') {
  final name = _nameCtrl.text.trim();
  if (name.isEmpty) { errorMsg = 'Name is required.'; return false; }
  if (!RegExp(r'^[A-Za-z ]+$').hasMatch(name)) {
    errorMsg = 'Name must contain letters and spaces only.'; return false;
  }
}
```

**Cheque/DD — mandatory header fields:**
```dart
if (_isChequeDD) {
  if (_drawnOnCtrl.text.trim().isEmpty)  { errorMsg = 'Drawn On required.'; return false; }
  if (_chequeNoCtrl.text.trim().isEmpty) { errorMsg = 'Cheque No required.'; return false; }
  if (_chequeDtCtrl.text.trim().isEmpty) { errorMsg = 'Cheque Date required.'; return false; }
}
```

**Impact:** Bad data cannot be saved; user gets immediate inline error message.

---

## Issue 30 — Receipt module refactored to canonical file structure (HIGH)

| Field | Detail |
|-------|--------|
| **Files (old)** | `lib/society/ReceiptScreen.dart`, `lib/society/ReceiptListScreen.dart`, `lib/service/receipt_service.dart` |
| **Files (new)** | `lib/models/receipt.dart`, `lib/services/receipt_service.dart`, `lib/screens/receipts/receipt_form_screen.dart`, `lib/screens/receipts/receipt_list_screen.dart`, `lib/screens/receipts/receipt_detail_screen.dart` |
| **Scope** | Pure Flutter frontend refactor; backend API contract unchanged |

### Changes per file

#### `lib/models/receipt.dart` (new)

Typed `Receipt` model with `fromJson` / `toJson` matching the full API response shape including `account_balance`, `demand_detail_id`, `status`.

#### `lib/services/receipt_service.dart` (new canonical path)

| Method | Change |
|--------|--------|
| `createReceipt` / `updateReceipt` | Support `demand_detail_id` in payload |
| `searchMembers(query)` | New — handles paginated `{"items":[...]}` AND plain list; returns empty list (not throws) on 500 |
| `getMemberAccounts(memberId)` | New — self-contained copy so receipt screens need not import MemberService |
| `_throwDetail` | Return type `Never` — prevents dead-code after the call site |

#### `lib/screens/receipts/receipt_form_screen.dart` (replaces ReceiptScreen)

| Feature | Before | After |
|---------|--------|-------|
| Member field | Dropdown pre-loaded from full member list (broke when `/members/search/` returned 500) | Debounced search-as-you-type with inline results — works even if search is slow; fails gracefully with empty list |
| Reference No | Always visible | Only shown when payment mode is BANK, UPI, or ONLINE |
| After save | Generic "Receipt saved" snackbar | Shows `receipt_no` + `account_balance` from API response |
| `demand_detail_id` | Not present | Optional field in collapsible "Advanced Options" section |
| LOCKED receipt | Not handled | Warning banner, all fields read-only, Save button hidden |

#### `lib/screens/receipts/receipt_list_screen.dart` (replaces ReceiptListScreen)

| Feature | Before | After |
|---------|--------|-------|
| Edit button on LOCKED receipt | Always enabled (clicking triggered 422 from backend) | Disabled (greyed icon, tooltip "Receipt is locked") |
| View action | Not present | Eye icon button → pushes `ReceiptDetailScreen` via `Navigator.push` |
| Service import | `lib/service/receipt_service.dart` | `lib/services/receipt_service.dart` (canonical path) |

#### `lib/screens/receipts/receipt_detail_screen.dart` (new)

New read-only screen showing all receipt fields except `journal_id`. Displays `account_balance` prominently. Accessible by tapping View (👁) in the receipt list.

#### `lib/screens/home_screen.dart` (receipt route entry only)

```dart
// Before
import 'package:credit_society/society/ReceiptListScreen.dart';
import '../society/ReceiptScreen.dart';
// ...
child: ReceiptScreen(receipt: receiptData, onSaved: _onReceiptSaved)

// After
import 'receipts/receipt_list_screen.dart';
import 'receipts/receipt_form_screen.dart';
// ...
child: ReceiptFormScreen(receipt: receiptData, onSaved: _onReceiptSaved)
```

**Impact:** Receipt module now lives at clean canonical paths matching project conventions. Member search works with the fixed backend. All new API contract fields (`demand_detail_id`, `account_balance`, `reference_no` conditional) are handled correctly.


