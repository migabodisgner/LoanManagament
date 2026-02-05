import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
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

// Model class for multiple items
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo, primary: Colors.indigo[900]),
        useMaterial3: true,
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("THE BROTHER", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        centerTitle: true,
        backgroundColor: Colors.indigo[900],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.logout_rounded), onPressed: () => FirebaseAuth.instance.signOut()),
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("BUSINESS ANALYTICS", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                    Chip(label: Text(isAdmin ? "ADMIN MODE" : "STAFF MODE"), backgroundColor: isAdmin ? Colors.indigo[100] : Colors.green[100])
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    _buildStatCard("Active Loans", activeLoans.toString(), Icons.pending_actions, Colors.orange[800]!),
                    _buildStatCard("Total Debt", "${totalDebt.toStringAsFixed(0)} Rwf", Icons.account_balance_wallet, Colors.red[700]!),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildStatCard("Partial Paid (Qty)", partialPaidCount.toString(), Icons.people_outline, Colors.blue[700]!),
                    _buildStatCard("Partial Total", "${partialPaidAmount.toStringAsFixed(0)} Rwf", Icons.payments_outlined, Colors.teal[700]!),
                  ],
                ),
                const SizedBox(height: 30),
                const Text("OPERATIONS", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                const SizedBox(height: 15),
                _buildMenuButton(context, "Register New Loan", Icons.add_moderator_rounded, Colors.indigo, const AddLoanPage()),
                _buildMenuButton(context, "Master Loan Registry", Icons.manage_search_rounded, Colors.teal, const LoanListPage()),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String val, IconData icon, Color col) {
    return Expanded(
      child: Card(
        elevation: 4, color: col,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11)),
              Text(val, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext ctx, String tit, IconData ic, Color col, Widget target) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: col.withOpacity(0.1), child: Icon(ic, color: col)),
        title: Text(tit, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (ctx) => target)),
      ),
    );
  }
}

// ---------------- LOAN LIST PAGE (SEARCH & FILTER) ----------------
class LoanListPage extends StatefulWidget {
  const LoanListPage({super.key});
  @override
  State<LoanListPage> createState() => _LoanListPageState();
}

class _LoanListPageState extends State<LoanListPage> {
  String searchQuery = "";
  String filterStatus = "All";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Master Registry"), backgroundColor: Colors.teal[700], foregroundColor: Colors.white),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15), color: Colors.teal[700],
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => setState(() => searchQuery = val.toLowerCase()),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Search name or phone...", hintStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(Icons.search, color: Colors.white),
                    filled: true, fillColor: Colors.white.withOpacity(0.2),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ["All", "Active", "Paid"].map((status) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(label: Text(status), selected: filterStatus == status, onSelected: (selected) => setState(() => filterStatus = status)),
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
                  bool matchesSearch = data['customerName'].toString().toLowerCase().contains(searchQuery) || data['phone'].toString().contains(searchQuery);
                  bool matchesFilter = filterStatus == "All" || (filterStatus == "Active" ? (data['balance'] > 0) : (data['balance'] <= 0));
                  return matchesSearch && matchesFilter;
                }).toList();

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    var doc = filteredDocs[index];
                    var data = doc.data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: (data['balance'] > 0) ? Colors.red[50] : Colors.green[50],
                          child: Icon(Icons.person, color: (data['balance'] > 0) ? Colors.red : Colors.green),
                        ),
                        title: Text(data['customerName'] ?? "N/A", style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Balance: ${data['balance']} Rwf"),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(15),
                            child: Column(
                              children: [
                                _infoRow(Icons.phone, "Phone", data['phone'] ?? "N/A"),
                                _infoRow(Icons.shopping_basket, "Items", data['paintType'] ?? "N/A"),
                                _infoRow(Icons.summarize, "Total", "${data['totalAmount']} Rwf"),
                                _infoRow(Icons.price_check, "Paid", "${data['paidAmount']} Rwf"),
                                const Divider(),
                                if (isAdmin) Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton.icon(onPressed: () => FirebaseFirestore.instance.collection('loans').doc(doc.id).update({'balance': 0, 'paidAmount': data['totalAmount']}), icon: const Icon(Icons.done_all), label: const Text("Clear Debt"), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white)),
                                    IconButton(onPressed: () => FirebaseFirestore.instance.collection('loans').doc(doc.id).delete(), icon: const Icon(Icons.delete, color: Colors.red)),
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
    return Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Row(children: [Icon(ic, size: 16), const SizedBox(width: 10), Text("$lab: $val")]));
  }
}

// ---------------- ADD LOAN PAGE (MULTIPLE PRODUCTS SUPPORTED) ----------------
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
      appBar: AppBar(title: const Text("New Multi-Item Loan")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildSectionTitle("Customer Info"),
            TextField(controller: _name, decoration: const InputDecoration(labelText: "Name", prefixIcon: Icon(Icons.person))),
            TextField(controller: _phone, decoration: const InputDecoration(labelText: "Phone", prefixIcon: Icon(Icons.phone)), keyboardType: TextInputType.phone),
            
            const SizedBox(height: 20),
            _buildSectionTitle("Add Products to Basket"),
            Container(
              padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.05), borderRadius: BorderRadius.circular(15)),
              child: Column(
                children: [
                  DropdownButtonFormField(value: sProduct, items: productList.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => sProduct = v!), decoration: const InputDecoration(labelText: "Product")),
                  Row(
                    children: [
                      Expanded(child: DropdownButtonFormField(value: sBrand, items: brandList.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => sBrand = v!), decoration: const InputDecoration(labelText: "Brand"))),
                      const SizedBox(width: 10),
                      Expanded(child: DropdownButtonFormField(value: sSize, items: sizeList.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => sSize = v!), decoration: const InputDecoration(labelText: "Size"))),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: _qtyCtrl, decoration: const InputDecoration(labelText: "Qty"), keyboardType: TextInputType.number)),
                      const SizedBox(width: 10),
                      Expanded(child: TextField(controller: _priceCtrl, decoration: const InputDecoration(labelText: "Price/Unit"), keyboardType: TextInputType.number)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(onPressed: _addToBasket, icon: const Icon(Icons.add_shopping_cart), label: const Text("ADD TO LIST"), style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white)),
                ],
              ),
            ),

            const SizedBox(height: 20),
            _buildSectionTitle("Basket Items (${basket.length})"),
            ...basket.map((item) => ListTile(
              title: Text("${item.name} (${item.brand})"),
              subtitle: Text("${item.qty} x ${item.price} = ${item.subTotal} Rwf"),
              trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => setState(() => basket.remove(item))),
            )),

            const Divider(height: 40),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("GRAND TOTAL:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), Text("${grandTotal.toStringAsFixed(0)} Rwf", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red))]),
            TextField(controller: _paid, decoration: const InputDecoration(labelText: "Amount Paid Now (Rwf)", prefixIcon: Icon(Icons.payments)), keyboardType: TextInputType.number),
            
            const SizedBox(height: 30),
            ElevatedButton(onPressed: _save, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55), backgroundColor: Colors.indigo[900], foregroundColor: Colors.white), child: const Text("COMPLETE & SAVE RECORD")),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String t) => Align(alignment: Alignment.centerLeft, child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)));
}

// ---------------- LOGIN PAGE ----------------
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
      body: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(40), child: Column(children: [
        const Icon(Icons.handyman_rounded, size: 80, color: Colors.indigo),
        const Text("THE BROTHER", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.indigo)),
        const SizedBox(height: 40),
        TextField(controller: _email, decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder())),
        const SizedBox(height: 15),
        TextField(controller: _pass, obscureText: true, decoration: const InputDecoration(labelText: "Password", border: OutlineInputBorder())),
        const SizedBox(height: 25),
        ElevatedButton(onPressed: () async {
          try { await FirebaseAuth.instance.signInWithEmailAndPassword(email: _email.text.trim(), password: _pass.text.trim()); }
          catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); }
        }, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55), backgroundColor: Colors.indigo[900], foregroundColor: Colors.white), child: const Text("SIGN IN")),
        TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpPage())), child: const Text("Create Staff Account"))
      ]))),
    );
  }
}

// ---------------- SIGN UP PAGE ----------------
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _email = TextEditingController(), _pass = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(), body: Padding(padding: const EdgeInsets.all(30), child: Column(children: [
      const Text("Staff Registration", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 25),
      TextField(controller: _email, decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder())),
      const SizedBox(height: 15),
      TextField(controller: _pass, obscureText: true, decoration: const InputDecoration(labelText: "Password", border: OutlineInputBorder())),
      const SizedBox(height: 30),
      ElevatedButton(onPressed: () async {
        try { await FirebaseAuth.instance.createUserWithEmailAndPassword(email: _email.text.trim(), password: _pass.text.trim()); Navigator.pop(context); }
        catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); }
      }, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55)), child: const Text("REGISTER NOW"))
    ])));
  }
}