import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const BrotherApp());
}

bool isAdmin = false;

// --- INVENTORY DATA ---
const List<String> productList = [
  "Silk Vinyl", "Weatherguard", "Enduit (Wall Putty)", "Plastic Emulsion", 
  "Super Gloss (Oil Paint)", "Varnish", "Wood Primer", "Wood Stain", 
  "Anti-Rust", "Bondex", "Textured Paint", "Thinner", "Petrol", 
  "Brushes", "Rollers", "Sandpaper", "Masking Tape"
];
const List<String> sizeList = ["1L", "4L", "5L", "10L", "20L", "Paki", "Piece"];
const List<String> brandList = ["Ameen", "Sadolin", "Regal", "Kansai Plascon", "Sika", "Other"];

class SelectedProduct {
  String name;
  String brand;
  String size;
  int qty;
  double price;
  SelectedProduct({required this.name, required this.brand, required this.size, required this.qty, required this.price});
  
  double get subTotal => qty * price;
}

class BrotherApp extends StatelessWidget {
  const BrotherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'The Brother Management',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A237E), primary: const Color(0xFF1A237E)),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            isAdmin = snapshot.data!.email == "manzimigabo@gmail.com"; 
            return const DashboardPage();
          }
          return const LoginPage();
        },
      ),
    );
  }
}

// ---------------- DASHBOARD PAGE ----------------
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("THE BROTHER", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A237E),
        elevation: 4,
        actions: [
          IconButton(icon: const Icon(Icons.logout_rounded, color: Colors.white), onPressed: () => FirebaseAuth.instance.signOut()),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('loans').snapshots(),
        builder: (context, snapshot) {
          int activeLoans = 0; double totalDebt = 0;
          int partialPaidCount = 0; double partialPaidAmount = 0;

          if (snapshot.hasData) {
            for (var doc in snapshot.data!.docs) {
              var data = doc.data() as Map<String, dynamic>;
              double balance = (data['balance'] ?? 0).toDouble();
              double paid = (data['paidAmount'] ?? 0).toDouble();
              if (balance > 0) {
                activeLoans++; totalDebt += balance;
                if (paid > 0) { partialPaidCount++; partialPaidAmount += paid; }
              }
            }
          }

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [const Color(0xFF1A237E).withOpacity(0.05), Colors.white],
              )
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("ANALYTICS OVERVIEW", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, letterSpacing: 1.1)),
                      Chip(
                        label: Text(isAdmin ? "ADMIN" : "STAFF", style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)), 
                        backgroundColor: isAdmin ? Colors.orange[800] : Colors.green[700]
                      )
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      _buildStatCard("Active Loans", activeLoans.toString(), Icons.pending_actions, const Color(0xFFE65100)),
                      _buildStatCard("Total Debt", "${totalDebt.toStringAsFixed(0)} Rwf", Icons.account_balance_wallet, const Color(0xFFB71C1C)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildStatCard("Partial Paid", partialPaidCount.toString(), Icons.people_outline, const Color(0xFF0D47A1)),
                      _buildStatCard("Paid Amount", "${partialPaidAmount.toStringAsFixed(0)} Rwf", Icons.payments_outlined, const Color(0xFF004D40)),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text("QUICK OPERATIONS", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                  const SizedBox(height: 15),
                  _buildMenuButton(context, "Register New Loan", Icons.add_moderator_rounded, const Color(0xFF1A237E), const AddLoanPage()),
                  _buildMenuButton(context, "Master Loan Registry", Icons.manage_search_rounded, const Color(0xFF00796B), const LoanListPage()),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String val, IconData icon, Color col) {
    return Expanded(
      child: Card(
        elevation: 6, color: col,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
              FittedBox(fit: BoxFit.scaleDown, child: Text(val, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext ctx, String tit, IconData ic, Color col, Widget target) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(15), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(backgroundColor: col.withOpacity(0.1), child: Icon(ic, color: col, size: 24)),
        title: Text(tit, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF263238))),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey[400]),
        onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (ctx) => target)),
      ),
    );
  }
}

// ---------------- LOAN LIST PAGE (REMAINS SAME AS PER REQUEST) ----------------
class LoanListPage extends StatefulWidget {
  const LoanListPage({super.key});
  @override
  State<LoanListPage> createState() => _LoanListPageState();
}

class _LoanListPageState extends State<LoanListPage> {
  String searchQuery = "";
  String filterStatus = "All";

  void _showPaymentDialog(String docId, double currentPaid, double total, double currentBalance) {
    final TextEditingController amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Record Payment", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Remaining Balance: $currentBalance Rwf", style: const TextStyle(color: Colors.red, fontSize: 13)),
            const SizedBox(height: 15),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Enter Amount Paid", border: OutlineInputBorder(), isDense: true),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (amountController.text.isNotEmpty) {
                double newPayment = double.parse(amountController.text);
                double totalPaidNow = currentPaid + newPayment;
                double newBalance = total - totalPaidNow;
                
                FirebaseFirestore.instance.collection('loans').doc(docId).update({
                  'paidAmount': totalPaidNow,
                  'balance': newBalance < 0 ? 0 : newBalance, 
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Update Payment"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Master Registry", style: TextStyle(color: Colors.white)), backgroundColor: const Color(0xFF00695C)),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12), color: const Color(0xFF00695C),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => setState(() => searchQuery = val.toLowerCase()),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Search name or phone...", hintStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(Icons.search, color: Colors.white),
                    filled: true, fillColor: Colors.white.withOpacity(0.2),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ["All", "Active", "Paid"].map((status) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 5),
                        child: ChoiceChip(
                          label: Text(status, style: const TextStyle(fontSize: 12)), 
                          selected: filterStatus == status, 
                          onSelected: (selected) => setState(() => filterStatus = status),
                        ),
                      );
                    }).toList(),
                  ),
                )
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('loans').orderBy('date', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                var filteredDocs = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  bool matchesSearch = (data['customerName'] ?? "").toString().toLowerCase().contains(searchQuery) || (data['phone'] ?? "").toString().contains(searchQuery);
                  bool matchesFilter = filterStatus == "All" || (filterStatus == "Active" ? (data['balance'] > 0) : (data['balance'] <= 0));
                  return matchesSearch && matchesFilter;
                }).toList();

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    var doc = filteredDocs[index];
                    var data = doc.data() as Map<String, dynamic>;
                    double bal = (data['balance'] ?? 0).toDouble();
                    double paid = (data['paidAmount'] ?? 0).toDouble();
                    double total = (data['totalAmount'] ?? 0).toDouble();

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: (bal > 0) ? Colors.red[50] : Colors.green[50],
                          child: Icon(Icons.person, color: (bal > 0) ? Colors.red : Colors.green, size: 20),
                        ),
                        title: Text(data['customerName'] ?? "N/A", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
                        subtitle: Text("Balance: $bal Rwf", style: const TextStyle(fontSize: 12)),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                _infoRow(Icons.phone, "Phone", data['phone'] ?? "N/A"),
                                _infoRow(Icons.shopping_basket, "Items", data['paintType'] ?? "N/A"),
                                _infoRow(Icons.summarize, "Total", "$total Rwf"),
                                _infoRow(Icons.price_check, "Paid", "$paid Rwf"),
                                const Divider(),
                                if (isAdmin) Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    TextButton.icon(
                                      onPressed: bal <= 0 ? null : () => _showPaymentDialog(doc.id, paid, total, bal), 
                                      icon: const Icon(Icons.add_card, size: 16), 
                                      label: const Text("Pay Partial", style: TextStyle(fontSize: 12)),
                                      style: TextButton.styleFrom(foregroundColor: Colors.blue)
                                    ),
                                    TextButton.icon(
                                      onPressed: bal <= 0 ? null : () => FirebaseFirestore.instance.collection('loans').doc(doc.id).update({'balance': 0, 'paidAmount': total}), 
                                      icon: const Icon(Icons.done_all, size: 16), 
                                      label: const Text("Clear All", style: TextStyle(fontSize: 12)), 
                                      style: TextButton.styleFrom(foregroundColor: Colors.green)
                                    ),
                                    IconButton(onPressed: () => FirebaseFirestore.instance.collection('loans').doc(doc.id).delete(), icon: const Icon(Icons.delete, color: Colors.red, size: 20)),
                                  ],
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData ic, String lab, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ic, size: 14, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(child: Text("$lab: $val", style: const TextStyle(fontSize: 12), softWrap: true)),
        ],
      ),
    );
  }
}

// ---------------- ADD LOAN PAGE (UPDATED UI) ----------------
class AddLoanPage extends StatefulWidget {
  const AddLoanPage({super.key});
  @override
  State<AddLoanPage> createState() => _AddLoanPageState();
}

class _AddLoanPageState extends State<AddLoanPage> {
  final _name = TextEditingController(), _phone = TextEditingController(), _paid = TextEditingController();
  final _qtyCtrl = TextEditingController(text: "1"), _priceCtrl = TextEditingController();
  
  List<SelectedProduct> basket = [];
  String sProduct = productList[0], sBrand = brandList[0], sSize = sizeList[1];

  double get grandTotal => basket.fold(0, (sum, item) => sum + item.subTotal);

  void _addToBasket() {
    if (_priceCtrl.text.isEmpty) return;
    setState(() {
      basket.add(SelectedProduct(
        name: sProduct, brand: sBrand, size: sSize, 
        qty: int.parse(_qtyCtrl.text), price: double.parse(_priceCtrl.text)
      ));
      _priceCtrl.clear(); _qtyCtrl.text = "1";
    });
  }

  Future<void> _save() async {
    if (_name.text.isEmpty || basket.isEmpty) return;
    String itemsSummary = basket.map((e) => "${e.qty}x ${e.name}(${e.brand})").join(", ");
    double paid = double.parse(_paid.text.isEmpty ? "0" : _paid.text);
    
    await FirebaseFirestore.instance.collection('loans').add({
      'customerName': _name.text, 'phone': _phone.text, 
      'paintType': itemsSummary, 'totalAmount': grandTotal, 
      'paidAmount': paid, 'balance': grandTotal - paid,
      'recordedBy': FirebaseAuth.instance.currentUser?.email ?? "Staff",
      'date': FieldValue.serverTimestamp(),
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("New Multi-Item Loan", style: TextStyle(color: Colors.white)), backgroundColor: const Color(0xFF1A237E), iconTheme: const IconThemeData(color: Colors.white)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildSectionTitle("CUSTOMER INFORMATION"),
            const SizedBox(height: 10),
            TextField(controller: _name, decoration: InputDecoration(labelText: "Client Name", prefixIcon: const Icon(Icons.person), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), isDense: true)),
            const SizedBox(height: 10),
            TextField(controller: _phone, decoration: InputDecoration(labelText: "Phone Number", prefixIcon: const Icon(Icons.phone), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), isDense: true), keyboardType: TextInputType.phone),
            
            const SizedBox(height: 25),
            _buildSectionTitle("SELECT PRODUCTS"),
            Container(
              padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.05), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.indigo.withOpacity(0.1))),
              child: Column(
                children: [
                  DropdownButtonFormField(value: sProduct, isExpanded: true, items: productList.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(), onChanged: (v) => setState(() => sProduct = v!), decoration: const InputDecoration(labelText: "Select Paint/Item", isDense: true)),
                  Row(
                    children: [
                      Expanded(child: DropdownButtonFormField(value: sBrand, isExpanded: true, items: brandList.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12)))).toList(), onChanged: (v) => setState(() => sBrand = v!), decoration: const InputDecoration(labelText: "Brand", isDense: true))),
                      const SizedBox(width: 8),
                      Expanded(child: DropdownButtonFormField(value: sSize, isExpanded: true, items: sizeList.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12)))).toList(), onChanged: (v) => setState(() => sSize = v!), decoration: const InputDecoration(labelText: "Size", isDense: true))),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: _qtyCtrl, decoration: const InputDecoration(labelText: "Qty", isDense: true), keyboardType: TextInputType.number)),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: _priceCtrl, decoration: const InputDecoration(labelText: "Price (Unit)", isDense: true), keyboardType: TextInputType.number)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton.icon(onPressed: _addToBasket, icon: const Icon(Icons.add_shopping_cart, size: 18), label: const Text("ADD TO BASKET"), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[800], foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
                ],
              ),
            ),

            const SizedBox(height: 25),
            _buildSectionTitle("BASKET SUMMARY"),
            ...basket.map((item) => Card(
              elevation: 0, color: Colors.grey[100], margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                title: Text("${item.name} (${item.brand})", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: Text("${item.qty} x ${item.price} = ${item.subTotal} Rwf", style: const TextStyle(fontSize: 12)),
                trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: () => setState(() => basket.remove(item))),
              ),
            )),

            const Divider(height: 40),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("GRAND TOTAL:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1A237E))), Text("${grandTotal.toStringAsFixed(0)} Rwf", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red))]),
            const SizedBox(height: 15),
            TextField(controller: _paid, decoration: InputDecoration(labelText: "Amount Paid Now (Rwf)", prefixIcon: const Icon(Icons.payments), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), isDense: true), keyboardType: TextInputType.number),
            
            const SizedBox(height: 30),
            ElevatedButton(onPressed: _save, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55), backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text("COMPLETE TRANSACTION", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1))),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String t) => Align(alignment: Alignment.centerLeft, child: Text(t, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.indigo, fontSize: 12, letterSpacing: 1.2)));
}

// ---------------- LOGIN PAGE WITH BACKGROUND ----------------
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController(), _pass = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Professional Background Image (Paint/Hardware theme)
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage("https://images.unsplash.com/photo-1589939705384-5185138a04b9?q=80&w=2070&auto=format&fit=crop"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Dark Overlay for readability
          Container(color: const Color(0xFF1A237E).withOpacity(0.85)),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(40), 
              child: Column(
                children: [
                  const Icon(Icons.format_paint_rounded, size: 80, color: Colors.orange),
                  const SizedBox(height: 10),
                  const Text("THE BROTHER", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2)),
                  const Text("Paint Management System", style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 40),
                  TextField(
                    controller: _email, 
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Email Address", labelStyle: const TextStyle(color: Colors.white70),
                      enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.orange)),
                      prefixIcon: const Icon(Icons.email, color: Colors.white70),
                    )
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _pass, obscureText: true, 
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Password", labelStyle: const TextStyle(color: Colors.white70),
                      enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.orange)),
                      prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                    )
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () async {
                      try { await FirebaseAuth.instance.signInWithEmailAndPassword(email: _email.text.trim(), password: _pass.text.trim()); }
                      catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); }
                    }, 
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 55), 
                      backgroundColor: Colors.orange[800], 
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ), 
                    child: const Text("SIGN IN", style: TextStyle(fontWeight: FontWeight.bold))
                  ),
                  const SizedBox(height: 15),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpPage())), 
                    child: const Text("Create Staff Account", style: TextStyle(color: Colors.white70, fontSize: 13))
                  )
                ]
              )
            )
          ),
        ],
      ),
    );
  }
}

// ---------------- SIGN UP PAGE WITH BACKGROUND ----------------
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _email = TextEditingController(), _pass = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.white)),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage("https://images.unsplash.com/photo-1562564055-71e051d33c19?q=80&w=2070&auto=format&fit=crop"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.black.withOpacity(0.7)),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(40), 
              child: Column(
                children: [
                  const Text("Staff Registration", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 30),
                  TextField(
                    controller: _email, 
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Email", labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
                    )
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _pass, obscureText: true, 
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Password", labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
                    )
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () async {
                      try { 
                        await FirebaseAuth.instance.createUserWithEmailAndPassword(email: _email.text.trim(), password: _pass.text.trim()); 
                        Navigator.pop(context); 
                      } catch (e) { 
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); 
                      }
                    }, 
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 55), 
                      backgroundColor: Colors.blue[900], 
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ), 
                    child: const Text("REGISTER NOW")
                  )
                ]
              )
            )
          ),
        ],
      ),
    );
  }
}