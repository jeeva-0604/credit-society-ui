# Receipt Module — Frontend Architecture

> Agent: Flutter UI Engineer + Documentation Engineer  
> Date: 2026-06-03

---

## Layer Overview

```
┌─────────────────────────────────────────────────────────┐
│  PRESENTATION LAYER                                     │
│  lib/screens/home_screen.dart                           │
│    └─ manages navigation state + receipt list refresh   │
│                                                         │
│  lib/society/ReceiptListScreen.dart                     │
│    └─ loads + displays receipt table                    │
│                                                         │
│  lib/society/ReceiptScreen.dart                         │
│    └─ create / edit form                                │
├─────────────────────────────────────────────────────────┤
│  SERVICE LAYER                                          │
│  lib/service/receipt_service.dart                       │
│    └─ HTTP calls to receipt endpoints                   │
│                                                         │
│  lib/service/member_service.dart                        │
│    └─ getMembers() + getAccounts(memberId)              │
│                                                         │
│  lib/service/apiservice.dart                            │
│    └─ base URL resolution + auth headers                │
├─────────────────────────────────────────────────────────┤
│  BACKEND                                                │
│  FastAPI — http://localhost:8080/credit_society/api/v1  │
│    GET    /receipts/                                    │
│    GET    /receipts/{id}                                │
│    POST   /receipts/                                    │
│    PUT    /receipts/{id}                                │
│    GET    /members/search/                              │
│    GET    /members/{id}/accounts                        │
└─────────────────────────────────────────────────────────┘
```

---

## Presentation Layer Detail

### HomeScreen (`lib/screens/home_screen.dart`)

Manages the top-level navigation and receipt sub-flow state.

**Receipt-related state variables:**

| Variable | Type | Purpose |
|----------|------|---------|
| `_showNewReceiptForm` | `bool` | When true, shows ReceiptScreen instead of list |
| `_editingReceipt` | `Map?` | When non-null, ReceiptScreen loads this receipt for edit |
| `_activeScreen` | `Widget?` | Currently rendered main content widget |

**Receipt-related methods:**

| Method | Role |
|--------|------|
| `_buildReceiptEntryArea(Map?)` | Builds the header + embedded ReceiptScreen |
| `_onReceiptSaved()` | Callback from ReceiptScreen; hides form, refreshes list |

**Refresh mechanism:** `_onReceiptSaved()` sets `_activeScreen` to a new `ReceiptListScreen(key: UniqueKey(), ...)`. The `UniqueKey` forces Flutter to discard the previous State and create a new one, triggering `initState` → `_load()` → fresh receipt list.

---

### ReceiptListScreen (`lib/society/ReceiptListScreen.dart`)

Stateful widget that fetches and displays all receipts in a DataTable.

**State:**

| Variable | Purpose |
|----------|---------|
| `_receipts` | Raw list from GET /receipts/ |
| `_isLoading` | Shows CircularProgressIndicator |
| `_error` | Shows error panel with Retry button |

**UI States:**

| State | Condition | Widget Shown |
|-------|-----------|-------------|
| Loading | `_isLoading == true` | `CircularProgressIndicator` |
| Error | `_error != null` | Error panel + Retry |
| Empty | `_receipts.isEmpty` | Empty state + CTA |
| Data | `_receipts.isNotEmpty` | DataTable inside RefreshIndicator |

**Callbacks to HomeScreen:**

| Callback | Trigger | HomeScreen action |
|----------|---------|-------------------|
| `onNewReceipt` | `+` button in AppBar | Sets `_showNewReceiptForm = true`, `_editingReceipt = null` |
| `onEditReceipt(Map)` | Edit icon in row | Sets `_showNewReceiptForm = true`, `_editingReceipt = receipt` |

---

### ReceiptScreen (`lib/society/ReceiptScreen.dart`)

Stateful widget for creating and editing receipts.

**Props:**

| Prop | Type | Purpose |
|------|------|---------|
| `receipt` | `Map?` | When null = create mode; when set = edit mode |
| `onSaved` | `VoidCallback?` | Called after successful API response. HomeScreen passes `_onReceiptSaved`. Standalone use leaves this null and falls back to `Navigator.pop`. |

**State:**

| Variable | Purpose |
|----------|---------|
| `_members` | Loaded from GET /members/search/ |
| `_accounts` | Loaded from GET /members/{id}/accounts on member select |
| `_isInitialising` | True while member list loads on mount |
| `_isLoadingAccounts` | True while account list loads after member select |
| `_isSaving` | True during API call; disables button |
| `_errorMessage` | Inline error from API |
| `_receiptDate` | Selected date (defaults to `DateTime.now()`) |
| `_paymentMode` | Defaults to `"CASH"` |
| `_selectedMember` | Selected member ID |
| `_selectedAccount` | Selected account ID (nullable) |

---

## Service Layer Detail

### ReceiptService (`lib/service/receipt_service.dart`)

| Method | HTTP | URL | Returns |
|--------|------|-----|---------|
| `getReceipts()` | GET | `/receipts/` | `List<dynamic>` |
| `getReceiptById(id)` | GET | `/receipts/{id}` | `Map<String, dynamic>` |
| `createReceipt(data)` | POST | `/receipts/` | `Map<String, dynamic>` |
| `updateReceipt(id, data)` | PUT | `/receipts/{id}` | `Map<String, dynamic>` |

All methods extract the `detail` field from error response bodies for user-friendly error messages.

### MemberService (`lib/service/member_service.dart`)

| Method | Used by ReceiptScreen for |
|--------|--------------------------|
| `getMembers(search)` | Populating member dropdown |
| `getAccounts(memberId)` | Populating account dropdown after member select |

---

## Key Design Decisions

1. **Embedded vs navigated**: ReceiptScreen is an embedded widget inside HomeScreen, not pushed on the Navigator. The `onSaved` callback pattern replaces `Navigator.pop`.

2. **UniqueKey for forced refresh**: Rather than exposing a public `refresh()` method on the list screen's State, HomeScreen replaces the ReceiptListScreen widget with a new instance carrying a `UniqueKey()`. This is idiomatic Flutter.

3. **Amount as decimal string**: The backend Pydantic schema validates `amount` as a decimal string. Flutter sends `amount.toStringAsFixed(2)` to ensure correct format.

4. **Member read-only on edit**: Enforced in the UI to prevent a guaranteed 422 from the backend. A tooltip explains the constraint to the user.
