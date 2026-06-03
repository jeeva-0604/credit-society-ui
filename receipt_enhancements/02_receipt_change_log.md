# Receipt Module Frontend — Change Log

> Agent: Flutter UI Engineer + API Integration Specialist  
> Date: 2026-06-03 (Pass 1) | Updated: 2026-06-03 (Pass 2 — Multi-Agent Audit, 43 agents)

---

## Files Modified

### `lib/service/receipt_service.dart`

| Change | Before | After |
|--------|--------|-------|
| POST URL | `$baseUrl/receipts/receipt` | `$baseUrl/receipts/` |
| PUT URL | `$baseUrl/receipts/receipt/$id` | `$baseUrl/receipts/$id` |
| Error handling POST | Generic `throw Exception("Failed to create receipt: ${body}")` | Extracts `detail` field from JSON response body |
| Error handling PUT | Generic `throw Exception("Failed to create receipt: ${body}")` | Extracts `detail` field from JSON response body |
| Exception propagation | Wrapped all exceptions including re-thrown ones in outer catch | `on Exception { rethrow }` prevents double-wrapping |

---

### `lib/society/ReceiptScreen.dart` (complete rewrite, same public interface + `onSaved`)

| Change | Before | After |
|--------|--------|-------|
| `onSaved` callback | Not present | Added `VoidCallback? onSaved` parameter |
| Date field | Not present | `InkWell` + `InputDecorator` + `showDatePicker` |
| ONLINE payment mode | Missing | Added to `_paymentModes = ["CASH", "BANK", "UPI", "ONLINE"]` |
| Narration field | Declared but never rendered | Full `TextFormField` with `maxLines: 2` |
| Amount type sent to API | `double` (e.g. `1500.0`) | Decimal string (e.g. `"1500.00"`) via `toStringAsFixed(2)` |
| Form validators | None | Amount: required + numeric + > 0; Member: required; Mode: required |
| Loading state | None | `_isSaving` bool disables button, shows spinner |
| Error display | None (exceptions silently dropped) | `_errorMessage` renders inline error box |
| Member field on edit | Editable dropdown (causes 422) | Read-only `InputDecorator` with lock icon + tooltip |
| Receipt info banner | None | Shows `receipt_no` and `status` when editing |
| Navigation after save | `Navigator.pop(context)` (no-op when embedded) | Calls `widget.onSaved!()` if set; else `Navigator.pop` |
| Controller disposal | Missing | `dispose()` disposes all 3 TextEditingControllers |
| Initialisation guard | `setState` called after dispose possible | Guards with `if (mounted)` |
| `print()` debug calls | Present | Removed |

---

### `lib/society/ReceiptListScreen.dart` (complete rewrite, same public interface)

| Change | Before | After |
|--------|--------|-------|
| `receipt_no` column | Missing | First column, monospace font |
| Date format | Raw ISO `"2026-06-03"` | DD/MM/YYYY `"03/06/2026"` |
| Amount format | Raw float `1500.0` | Indian rupee `₹1,500.00` |
| `account_number` null | Empty string `""` | Dash `"-"` |
| Status column | Missing | Colour-coded badge (`_StatusBadge`) |
| Payment mode | Plain text | Icon + label (`_ModeBadge`) |
| Error state | Missing (exception printed, empty list shown) | Full error panel with Retry button |
| Empty state | Missing (empty DataTable) | Illustration + CTA button |
| List refresh after save | Never triggered | `RefreshIndicator` pull-to-refresh + Refresh icon button |
| Horizontal scroll | Single `SingleChildScrollView` | Wrapped with second vertical `SingleChildScrollView` for tall lists |
| `isLoading` reset | Inconsistent | Correctly reset in `finally` via setState guards |
| `AppBar` foreground | Inherited (invisible on primary bg) | `foregroundColor: AppColors.white` |

---

### `lib/screens/home_screen.dart` (receipt section only — 2 methods added/changed)

| Change | Before | After |
|--------|--------|-------|
| `_onReceiptSaved()` method | Did not exist | New method: hides form, rebuilds `ReceiptListScreen` with `UniqueKey()` for forced refresh |
| `_buildReceiptEntryArea` | `ReceiptScreen(receipt: receiptData)` | `ReceiptScreen(receipt: receiptData, onSaved: _onReceiptSaved)` |

---

---

## Pass 2 — Multi-Agent Audit Changes (2026-06-03)

> 43 agents · 33 raw findings · 20 confirmed · 5 files patched

### `lib/society/ReceiptScreen.dart`

| Change | Before | After |
|--------|--------|-------|
| `_loadAccounts` mounted guard | No guard before/after await | `if (!mounted) return` before setState and after every await |
| `_isInitialising` initial value | `false` (one-frame flicker) | `true` (spinner from frame 0) |
| `_isSaving` reset on embedded save | Reset only on error path | Reset before `widget.onSaved!()` call on success too |
| `withOpacity` deprecation (5 sites) | `.withOpacity(x)` | `.withValues(alpha: x)` |

### `lib/society/ReceiptListScreen.dart`

| Change | Before | After |
|--------|--------|-------|
| Scroll nesting (RefreshIndicator) | Horizontal outer, vertical inner | Vertical outer, horizontal inner — RefreshIndicator now works |
| Receipt list type | Untyped `List` | `List<Map<String, dynamic>>` with `whereType` filter |
| Empty-state Create button | Hard `widget.onNewReceipt!()` (null crash) | Null-safe with SnackBar fallback |
| Member name column | Unbounded — overflowed table | `SizedBox(width:140)` + `TextOverflow.ellipsis` |
| `_fmtDate` | `String?` only — crashed on non-String | `dynamic` with `raw is! String` guard |
| `_fmtAmount` | Broke on negatives | `isNeg` flag, formats `abs`, prefixes `-` before `₹` |
| `withOpacity` deprecation (4 sites) | `.withOpacity(x)` | `.withValues(alpha: x)` |

### `lib/service/receipt_service.dart`

| Change | Before | After |
|--------|--------|-------|
| PUT URL trailing slash | `$baseUrl/receipts/$id` | `$baseUrl/receipts/$id/` (prevents silent GET redirect) |
| `getReceipts` error detail | Generic exception message | Extracts `detail` from FastAPI JSON error body |
| `getReceiptById` error detail | Hardcoded "not found" | Extracts `detail` from FastAPI JSON error body |

### `lib/service/auth_service.dart`

| Change | Before (broken by audit agent) | After (fixed) |
|--------|-------------------------------|---------------|
| Login credential placement | JSON body (`body: jsonEncode(...)`) | Query parameters (`?email=...&password=...`) matching FastAPI contract |

### `lib/screens/home_screen.dart` (receipt section only)

| Change | Before | After |
|--------|--------|-------|
| Receipts nav item | Static `ReceiptListScreen` cached at startup | `SizedBox.shrink()` placeholder; fresh `ReceiptListScreen(key: UniqueKey())` built on every tap |
| Receipt form on module switch | Not cleared | `_showNewReceiptForm = false; _editingReceipt = null;` added to `onDestinationSelected` |

---

## Files Created

| File | Purpose |
|------|---------|
| `receipt_enhancements/01_raw_vs_enhanced.md` | Issue → Root Cause → Fix → Impact for all 11 bugs |
| `receipt_enhancements/02_receipt_change_log.md` | This file |
| `receipt_enhancements/03_receipt_test_report.md` | Test cases, expected vs actual, pass/fail |
| `receipt_enhancements/04_receipt_ui_improvements.md` | UI/UX improvements catalogue |
| `receipt_frontend_documentation/01_receipt_architecture.md` | Screen → Service → API → Backend |
| `receipt_frontend_documentation/02_receipt_api_mapping.md` | Field-by-field UI ↔ API mapping |
| `receipt_frontend_documentation/03_receipt_workflow.md` | Create / Edit / Load / Refresh flows |
| `receipt_frontend_documentation/04_receipt_flow_diagram.md` | ASCII flow diagrams |
