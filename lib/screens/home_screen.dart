import 'package:credit_society/society/ReceiptListScreen.dart';
import 'package:credit_society/society/collection_create_screen.dart';
import 'package:flutter/material.dart';
import '../society/AccountListScreen.dart';
import '../society/BankBookScreen.dart';
import '../society/DayBookScreen.dart';
import '../society/DemandGenScreen.dart';
import '../society/DemandListScreen.dart';
import '../society/LedgerListScreen.dart';
import '../society/LoanApplyScreen.dart';
import '../society/LoanListScreen.dart';
import '../society/MemberEntryScreen.dart';
import '../society/MemberListScreen.dart';
import '../society/ReceiptScreen.dart';
import '../society/TrialBalanceScreen.dart';
import '../utils/app_colors.dart';
import '../utils/nav_menu.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  Widget? _activeScreen;
  bool _isSubMenuOpen = false;
  bool _showMemberView = false;
  Map? _editingReceipt;
  Map? _editingMember;
  bool _showNewMemberForm = false;
  bool _showNewReceiptForm = false;
  late List<NavItem> _navItems;
  bool _showNewLoanForm = false; // Add this variable
  @override
  void initState() {
    super.initState();
    _initNavItems();
    _activeScreen = _navItems[0].screen;
  }

  void _initNavItems() {
    _navItems = [
      NavItem(label: 'Home',
          icon: Icons.dashboard,
          screen: _buildDashboardView(context)),
      NavItem(
        label: 'Members',
        icon: Icons.people,
        subMenus: [
          SubMenuItem(
            title: "Member List",
            icon: Icons.list,
            screen: MemberListScreen(
              onEdit: (Map memberData) {
                setState(() {
                  _editingMember = memberData;
                  _showNewMemberForm = false;
                  _isSubMenuOpen = false;
                });
              },
              onNew: () { // ✅ HANDLE NEW MEMBER HERE
                setState(() {
                  _showNewMemberForm = true;
                  _editingMember = null;
                  _isSubMenuOpen = false;
                });
              },
            ),
          ),
          SubMenuItem(title: "New Member",
            icon: Icons.person_add,
            screen: const MemberEntryScreen(),
            onTap: () {
              setState(() {
                _showNewMemberForm = true;
                _isSubMenuOpen = false;
              });
            },),
        ],
      ),
      NavItem(label: 'Accounts',
          icon: Icons.account_balance,
          subMenus: [
            SubMenuItem(title: 'Accounts List',
                icon: Icons.book,
                screen: const AccountListScreen()),
          ]
      ),
      NavItem(
        label: 'Receipts',
        icon: Icons.receipt_long,
        subMenus: [
          SubMenuItem(
            title: 'Receipts List',
            icon: Icons.book,
            screen: ReceiptListScreen(
              onNewReceipt: () {
                setState(() {
                  _showNewReceiptForm = true;
                  _editingReceipt = null;
                });
              },
              onEditReceipt: (Map receipt) {
                setState(() {
                  _showNewReceiptForm = true;
                  _editingReceipt = receipt;
                });
              },
            ),
          ),
        ],
      ),
      NavItem(
          label: 'Demand',
          icon: Icons.receipt_long,
          subMenus: [
            SubMenuItem(title: "Generation",
                icon: Icons.play_arrow,
                screen: const DemandGenScreen()),
            SubMenuItem(title: "Demand List",
                icon: Icons.list_alt,
                screen: const DemandListScreen()),
          ]
      ),

      NavItem(
          label: 'Collection',
          icon: Icons.receipt_long,
          subMenus: [
            SubMenuItem(title: "Create Collection",
                icon: Icons.play_arrow,
                screen: const CollectionCreateScreen()),
            // SubMenuItem(title: "Collection List",
            //     icon: Icons.list_alt,
            //     screen: const CollectionL()),
          ]
      ),
      NavItem(
        label: 'Loans',
        icon: Icons.account_balance_wallet,
        subMenus: [
          SubMenuItem(
            title: "Loan List",
            icon: Icons.list,
            screen: const LoanListScreen(), // ✅ create this
          ),
          SubMenuItem(
              title: "Apply Loan",
              icon: Icons.add,
              screen: const LoanApplyScreen(), // ✅ next screen
              onTap: () { // You'll need to update your NavItem/SubMenuItem class to support onTap
                setState(() {
                  _showNewLoanForm = true;
                  _isSubMenuOpen = false;
                });
              }
          ),
          // SubMenuItem(
          //   title: "Disbursement",
          //   icon: Icons.currency_rupee,
          //   screen: const LoanDisbursementScreen(), // ✅ later
          // ),
          // SubMenuItem(
          //   title: "Loan Payment",
          //   icon: Icons.payments,
          //   screen: const LoanPaymentScreen(), // ✅ later
          // ),
        ],
      ),
      NavItem(
        label: 'Reports',
        icon: Icons.assessment,
        subMenus: [
          SubMenuItem(title: 'Day Book',
              icon: Icons.book,
              screen: const DayBookScreen()),
          SubMenuItem(title: 'Bank Book',
              icon: Icons.account_balance_wallet,
              screen: const BankBookscreen()),
          SubMenuItem(title: 'Ledger',
              icon: Icons.leaderboard,
              screen: const LedgerListScreen()),
          SubMenuItem(title: 'Trial Balance',
              icon: Icons.assessment,
              screen: const TrialBalanceScreen()),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 600;

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: AppColors.grey_200,
        body: Column(
          children: [
            _buildGlobalHeader(context, isMobile),
            _buildTabBlock(),
            Expanded(
              child: Row(
                children: [
                  NavigationRail(
                    backgroundColor: AppColors.primary,
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: (int index) {
                      setState(() {
                        _selectedIndex = index;
                        if (_navItems[index].subMenus != null) {
                          _isSubMenuOpen = !_isSubMenuOpen;
                        } else {
                          _isSubMenuOpen = false;
                          _showNewMemberForm = false;
                          _editingMember = null;
                          _activeScreen = _navItems[index].screen;
                        }
                      });
                    },
                    labelType: NavigationRailLabelType.all,
                    destinations: _navItems.map((item) => NavigationRailDestination(
                      icon: Icon(item.icon),
                      label: Text(item.label),
                    )).toList(),
                  ),

                  if (_isSubMenuOpen && _navItems[_selectedIndex].subMenus != null)
                    _buildDynamicSubMenu(_navItems[_selectedIndex]),

                  Expanded(
                    child: _buildScreen(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScreen() {
    if (_showNewMemberForm) {
      return _buildMemberEntryArea(null);
    }
    if (_editingMember != null) {
      return _buildMemberEntryArea(_editingMember);
    }
    if (_showNewLoanForm) {
      return LoanApplyScreen();
    }
    if (_showNewReceiptForm) {
      return _buildReceiptEntryArea(_editingReceipt); // ✅ wrapper with back button
    }
    return _activeScreen ?? const Center(child: CircularProgressIndicator());
  }

  /// Called by ReceiptScreen after a successful create or update.
  /// Hides the form and rebuilds ReceiptListScreen with a UniqueKey so that
  /// initState fires and the list reloads fresh.
  void _onReceiptSaved() {
    setState(() {
      _showNewReceiptForm = false;
      _editingReceipt = null;
      _activeScreen = ReceiptListScreen(
        key: UniqueKey(),
        onNewReceipt: () {
          setState(() {
            _showNewReceiptForm = true;
            _editingReceipt = null;
          });
        },
        onEditReceipt: (Map receipt) {
          setState(() {
            _showNewReceiptForm = true;
            _editingReceipt = receipt;
          });
        },
      );
    });
  }

  Widget _buildReceiptEntryArea(Map? receiptData) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() {
                  _showNewReceiptForm = false;
                  _editingReceipt = null;
                }),
              ),
              Text(
                receiptData == null
                    ? "New Receipt Entry"
                    : "Edit Receipt #${receiptData['id']}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Expanded(
          child: ReceiptScreen(
            receipt: receiptData,
            onSaved: _onReceiptSaved,
          ),
        ),
      ],
    );
  }

  Widget _buildMemberEntryArea(Map? memberData) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() {
                  _showNewMemberForm = false;
                  _editingMember = null;
                }),
              ),
              Text(
                memberData == null ? "New Member Registration" : "Edit Member: ${memberData['member_name']}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Expanded(
          child: MemberEntryScreen(
            member: memberData,
            onSave: () {
              setState(() {
                _showNewMemberForm = false;
                _editingMember = null;
              });
            },),
        ),
      ],
    );
  }

  Widget _buildDynamicSubMenu(NavItem item) {
    return Container(
      width: 180,
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(right: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.primary.withOpacity(0.05),
            child: Text(item.label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          ),
          ...item.subMenus!.map((sub) => ListTile(
            leading: Icon(sub.icon, size: 20),
            title: Text(sub.title, style: const TextStyle(fontSize: 13)),
            onTap: () {
              setState(() {
                // If user clicks "New Member" in sub-menu
                if (sub.title == "New Member") {
                  _showNewMemberForm = true;
                  _editingMember = null;
                } else {
                  _showNewMemberForm = false;
                  _editingMember = null;
                  _activeScreen = sub.screen;
                }
                _isSubMenuOpen = false;
              });
            },
          )),
        ],
      ),
    );
  }

  Widget _buildGlobalHeader(BuildContext context, bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
      color: AppColors.primary,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(4)),
            child: const Icon(Icons.account_balance, color: AppColors.primary,
                size: 30), // Placeholder for logo
          ),
          const SizedBox(width: 15),
          if (!isMobile)
            const Expanded(
              child: Text(
                "L&T GROUP EMPLOYEES COOPERATIVE THRIFT & CREDIT SOCIETY LTD",
                style: TextStyle(color: AppColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          const Spacer(),
          const Text("Welcome, Admin",
              style: TextStyle(color: AppColors.white, fontSize: 12)),
          IconButton(
              icon: const Icon(Icons.power_settings_new, color: Colors.white),
              onPressed: () {}),
        ],
      ),
    );
  }

  Widget _buildTabBlock() {
    return Container(
      width: double.infinity,
      color: AppColors.white,
      child: const TabBar(
        isScrollable: true,
        labelColor: AppColors.primary,
        indicatorColor: AppColors.primary,
        tabs: [
          Tab(text: "Thrift Deposit"),
          Tab(text: "Fixed Deposit"),
          Tab(text: "Recurring Deposit"),
          Tab(text: "Loans"),
          Tab(text: "Shares Capital"),
        ],
      ),
    );
  }


  Widget _buildDashboardView(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1000) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _buildMainContent(context)),
              Expanded(flex: 1, child: _buildProfileSidebar(context)),
            ],
          );
        } else {
          return SingleChildScrollView(
            child: Column(
              children: [
                _buildProfileSidebar(context),
                _buildMainContent(context),
              ],
            ),
          );
        }
      },
    );
  }

  // --- Reusing your existing _buildMainContent, _buildProfileSidebar, etc. ---
  Widget _buildMainContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildActionButtons(context),
          const SizedBox(height: 20),
          _buildTableSection(
              "Upcoming Charges", ["Name", "Due Date", "Due", "Outstanding"]),
          const SizedBox(height: 20),
          _buildTableSection("Loan Account Overview",
              ["Account #", "Type", "Balance", "Paid"]),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        _actionBtn(context, Icons.visibility, "View", () {
          // Instead of Navigator.push, we update the state
          setState(() => _showMemberView = true);
        }),
        _actionBtn(context, Icons.add, "New Loan", () {}),
        _actionBtn(context, Icons.savings, "New Saving", () {}),
      ],
    );
  }

  Widget _actionBtn(BuildContext context, IconData icon, String label,
      VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }


  Widget _buildProfileSidebar(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          const CircleAvatar(radius: 40,
              backgroundColor: Color(0xFF00789B),
              child: Icon(Icons.person, color: Colors.white, size: 40)),
          const SizedBox(height: 10),
          const Text("ANTONY VIMAL",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Divider(),
          _infoRow("ID", "000024087"),
          _infoRow("Mobile", "6380115683"),
        ],
      ),
    );
  }

  Widget _buildTableSection(String title, List<String> columns) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            color: AppColors.primaryDark, // Darker blue for table headers
            child: Text(title, style: const TextStyle(
                color: AppColors.white, fontWeight: FontWeight.bold)),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 25,
              columns: columns.map((c) => DataColumn(label: Text(c))).toList(),
              rows: const [
                DataRow(cells: [
                  DataCell(Text("Sample")),
                  DataCell(Text("2024-01-01")),
                  DataCell(Text("100")),
                  DataCell(Text("0"))
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold))
        ],
      ),
    );
  }
}