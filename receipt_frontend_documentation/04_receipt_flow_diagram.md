# Receipt Module — Flow Diagrams

> Agent: Documentation Engineer  
> Date: 2026-06-03

---

## Complete Data Flow: Create Receipt

```
╔═══════════════╗
║     USER      ║
╚═══════╤═══════╝
        │  Clicks [+] in Receipt List
        ▼
╔═══════════════════════╗
║    HomeScreen         ║
║  _showNewReceipt=true ║
╚═══════╤═══════════════╝
        │  Renders
        ▼
╔═══════════════════════════════════════════╗
║          ReceiptScreen (create mode)      ║
║                                           ║
║  [Receipt Date]   [DD/MM/YYYY]  📅        ║
║  [Member *]       [dropdown]              ║
║  [Account]        [dropdown]              ║
║  [Amount *]       [₹ ___]                 ║
║  [Payment Mode *] [CASH▼]                 ║
║  [Reference No]   [_____]                 ║
║  [Narration]      [______]                ║
║                                           ║
║  [    SAVE RECEIPT    ]                   ║
╚═══════╤═══════════════════════════════════╝
        │  User taps SAVE
        ▼
╔═══════════════════════╗
║  Form Validation      ║
║  • date: present      ║
║  • member: selected   ║
║  • amount: > 0        ║
║  • mode: selected     ║
╚═══════╤═══════════════╝
        │  PASS
        ▼
╔═══════════════════════╗
║   ReceiptService      ║
║  createReceipt(data)  ║
╚═══════╤═══════════════╝
        │  POST /receipts/
        ▼
╔═══════════════════════╗
║    REST API           ║
║  FastAPI Backend      ║
╚═══════╤═══════════════╝
        │  DB operations
        ▼
╔═══════════════════════╗
║    PostgreSQL DB      ║
║  receipts table       ║
║  journal_entries      ║
║  journal_details      ║
╚═══════╤═══════════════╝
        │  HTTP 200 ✓
        ▼
╔═══════════════════════╗
║   ReceiptService      ║
║  returns Map          ║
╚═══════╤═══════════════╝
        │
        ▼
╔═══════════════════════════════════════════╗
║         ReceiptScreen                     ║
║  SnackBar: "Receipt created successfully" ║
║  widget.onSaved()                         ║
╚═══════╤═══════════════════════════════════╝
        │
        ▼
╔═══════════════════════════════════════════╗
║         HomeScreen._onReceiptSaved()      ║
║  _showNewReceiptForm = false              ║
║  _activeScreen = ReceiptListScreen(       ║
║      key: UniqueKey()  ← forces refresh  ║
║  )                                        ║
╚═══════╤═══════════════════════════════════╝
        │  New State created
        ▼
╔═══════════════════════════════════════════╗
║         ReceiptListScreen (fresh)         ║
║  initState() → _load()                   ║
║  GET /receipts/                           ║
║                                           ║
║  ┌─────────────────────────────────────┐  ║
║  │ RCP-20260603-00001 │ 03/06/2026 │…  │  ║
║  └─────────────────────────────────────┘  ║
╚═══════════════════════════════════════════╝
```

---

## Error Path: API Rejects Request

```
╔═════════════════════════╗
║   ReceiptService        ║
║   POST /receipts/       ║
╚═══════════╤═════════════╝
            │  HTTP 422
            ▼
╔═════════════════════════╗
║  { "detail": "Member   ║
║   has no ledger..." }   ║
╚═══════════╤═════════════╝
            │
            ▼
╔═════════════════════════════════════════════╗
║   ReceiptScreen                             ║
║                                             ║
║  ┌─────────────────────────────────────┐    ║
║  │ ⚠ Member has no ledger configured. │    ║
║  │   Contact the administrator.        │    ║
║  └─────────────────────────────────────┘    ║
║                                             ║
║  [    SAVE RECEIPT    ]  ← re-enabled       ║
╚═════════════════════════════════════════════╝
```

---

## Edit Flow: Read-Only Member

```
╔══════════════════════════════════════════╗
║    ReceiptScreen (edit mode)             ║
║                                          ║
║  Receipt: RCP-20260603-00001  [POSTED]   ║
║                                          ║
║  [Receipt Date]   [03/06/2026]  📅       ║
║                                          ║
║  [Member]   TESTt   🔒                  ║
║             ↑ read-only: hover for why  ║
║                                          ║
║  [Account]  [dropdown: editable]         ║
║  [Amount]   [₹ 2000.00]                  ║
║  [Mode]     [BANK▼]                      ║
║  ...                                     ║
║                                          ║
║  [   UPDATE RECEIPT   ]                  ║
╚══════════════════════════════════════════╝
        │
        ▼
  PUT /receipts/{id}
  member_id unchanged ← sent from widget.receipt["member_id"]
        │
        ▼
  HTTP 200 → list refresh
```

---

## List Screen States

```
┌─────────────────────────────────────────────────────┐
│                   LOADING                           │
│                                                     │
│              ◌ (spinner)                            │
│                                                     │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│                    ERROR                            │
│                                                     │
│               ☁ (cloud-off icon)                   │
│        Failed to load receipts                      │
│        Network error: connection refused            │
│                                                     │
│              [ ↺  Retry ]                           │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│                    EMPTY                            │
│                                                     │
│               🧾 (receipt icon)                    │
│             No receipts yet                         │
│       Create your first receipt to get started.    │
│                                                     │
│              [ + Create Receipt ]                   │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│                    DATA                             │
│                                                     │
│  Receipt No   │ Date  │ Member │ … │ Status │ Act   │
│ ──────────────┼───────┼────────┼───┼────────┼────── │
│ RCP-20260603  │03/06  │ TESTt  │ … │●POSTED │  ✏   │
│ RCP-20260603  │03/06  │ John   │ … │●POSTED │  ✏   │
│  ...          │       │        │   │        │       │
└─────────────────────────────────────────────────────┘
```

---

## Component Dependency Tree

```
HomeScreen
├── NavigationRail (Receipts item)
├── ReceiptListScreen ─────────────────── GET /receipts/
│   ├── _StatusBadge
│   ├── _ModeBadge
│   └── _ColHeader
└── ReceiptScreen ─────────────────────── POST / PUT /receipts/
    ├── MemberService.getMembers()  ─────── GET /members/search/
    ├── MemberService.getAccounts()  ─────── GET /members/{id}/accounts
    └── ReceiptService.createReceipt()
        ReceiptService.updateReceipt()
```
