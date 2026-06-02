# Receipt Module — Workflow Guide

> Agent: UX / Workflow Specialist + Documentation Engineer  
> Date: 2026-06-03

---

## Workflow 1: Load Receipt List

```
User navigates to Receipts → Receipts List
        │
        ▼
HomeScreen sets _activeScreen = ReceiptListScreen(...)
        │
        ▼
ReceiptListScreen.initState()
        │
        ▼
_load() called
  setState: _isLoading = true, _error = null
        │
        ▼
ReceiptService.getReceipts()
  GET /receipts/
        │
        ├─── HTTP 200 ──────────────────────────────────────────────────┐
        │                                                               │
        │                                                  setState: _receipts = data
        │                                                  _isLoading = false
        │                                                               │
        │                                                       DataTable rendered
        │
        └─── HTTP error / network ─────────────────────────────────────┐
                                                                        │
                                                          setState: _error = message
                                                          _isLoading = false
                                                                        │
                                                              Error panel + Retry button
```

---

## Workflow 2: Create New Receipt

```
User clicks [+] in Receipts List AppBar
        │
        ▼
ReceiptListScreen calls widget.onNewReceipt()
        │
        ▼
HomeScreen.setState:
  _showNewReceiptForm = true
  _editingReceipt = null
        │
        ▼
_buildScreen() returns _buildReceiptEntryArea(null)
        │
        ▼
ReceiptScreen(receipt: null, onSaved: _onReceiptSaved)
        │
        ▼
_initialise() (create mode)
  1. Load members via MemberService.getMembers("")
  2. No pre-fill (all fields start at defaults)
        │
        ▼
User fills form:
  - Taps date field → showDatePicker → _receiptDate set
  - Selects member → _loadAccounts(memberId) called
  - (optional) Selects account
  - Enters amount
  - Selects payment mode
  - (optional) Reference No + Narration
        │
        ▼
User taps [SAVE RECEIPT]
        │
        ▼
_formKey.currentState!.validate()
  ├─── FAIL → validator messages shown → stop
  └─── PASS ─────────────────────────────────────────────────────────┐
                                                                      │
                                                       setState: _isSaving = true
                                                       Button shows spinner
                                                                      │
                                                       ReceiptService.createReceipt(payload)
                                                       POST /receipts/
                                                                      │
                                                       ├─── HTTP 200 ──────────────────┐
                                                       │                              │
                                                       │                  SnackBar "created successfully"
                                                       │                              │
                                                       │                  widget.onSaved()
                                                       │                              │
                                                       │                  HomeScreen._onReceiptSaved()
                                                       │                    _showNewReceiptForm = false
                                                       │                    _activeScreen = ReceiptListScreen(key: UniqueKey())
                                                       │                              │
                                                       │                    New ReceiptListScreen.initState()
                                                       │                    _load() → fresh list shown
                                                       │
                                                       └─── HTTP 4xx/5xx ─────────────┐
                                                                                       │
                                                                          setState: _isSaving = false
                                                                          _errorMessage = detail
                                                                          Error box shown in form
```

---

## Workflow 3: Edit Existing Receipt

```
User clicks [Edit] icon on a receipt row
        │
        ▼
ReceiptListScreen calls widget.onEditReceipt(receiptMap)
        │
        ▼
HomeScreen.setState:
  _showNewReceiptForm = true
  _editingReceipt = receiptMap
        │
        ▼
_buildScreen() returns _buildReceiptEntryArea(receiptMap)
        │
        ▼
ReceiptScreen(receipt: receiptMap, onSaved: _onReceiptSaved)
        │
        ▼
_initialise() (edit mode)
  1. Load members list (needed in case user views other members)
  2. Pre-set _selectedMember from receiptMap["member_id"]
  3. Load accounts for that member
  4. Pre-fill all form fields from receiptMap
        │
        ▼
Form pre-filled:
  - Date: from receipt_date
  - Member: READ-ONLY (locked InputDecorator)
  - Account: pre-selected
  - Amount, Mode, Ref, Narration: pre-filled
  - Info banner: shows receipt_no + status
        │
        ▼
User modifies allowed fields and taps [UPDATE RECEIPT]
        │
        ▼
(same validation + save flow as Create, but uses PUT /receipts/{id})
```

---

## Workflow 4: Refresh Receipt List

**Method A: Pull-to-Refresh**
```
User pulls down on receipt list
        │
RefreshIndicator triggers
        │
_load() called → list reloads
```

**Method B: Refresh Button**
```
User taps ↻ icon in AppBar
        │
_load() called → list reloads
```

**Method C: After Save (automatic)**
```
Save success → _onReceiptSaved() in HomeScreen
        │
_activeScreen = ReceiptListScreen(key: UniqueKey(), ...)
        │
New State created → initState → _load() → list reloads
```

---

## State Transition Summary

```
LIST SCREEN
    │
    ├─── [+] click ──────────────────────────────► CREATE FORM
    │                                                   │
    │                                               Save success
    │                                                   │
    ◄───────────────────────────────────────────────────┤ (auto-refresh)
    │
    ├─── [Edit] click ───────────────────────────► EDIT FORM
    │                                                   │
    │                                               Save success
    │                                                   │
    ◄───────────────────────────────────────────────────┤ (auto-refresh)
    │
    ├─── [↺] Refresh ────────────────────────────► reload in place
    │
    └─── pull-to-refresh ────────────────────────► reload in place
```

---

## Data Flow for Account Dropdown

The account dropdown is dynamically populated based on the selected member. This is a two-step load:

```
1. initState → loadMembers()
        │
        ▼
   Member dropdown populated

2. User selects member (or edit mode pre-sets member)
        │
        ▼
   _loadAccounts(memberId)
   GET /members/{memberId}/accounts
        │
        ▼
   Account dropdown populated
   (linear progress indicator shown during fetch)

3. If no accounts returned:
        │
        ▼
   "— None —" is the only option
   account_id = null is sent to API
```
