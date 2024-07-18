import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'midtrans_service.dart';
import 'payment_success_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingPaymentScreen extends StatefulWidget {
  final String tableId;
  final String tableName;
  final String tableImageUrl;
  final int tablePrice;

  BookingPaymentScreen({
    required this.tableId,
    required this.tableName,
    required this.tableImageUrl,
    required this.tablePrice,
  });

  @override
  _BookingPaymentScreenState createState() => _BookingPaymentScreenState();
}

class _BookingPaymentScreenState extends State<BookingPaymentScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  int _hours = 1;
  int _adminFee = 5000;
  int _totalCost = 0;
  String? _selectedTimeSlot;
  late String orderId;

  @override
  void initState() {
    super.initState();
    _calculateTotalCost();
    orderId = 'order-${DateTime.now().millisecondsSinceEpoch}';
    _setUserDetails();
    _listenToPaymentStatus();
  }

  void _setUserDetails() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _nameController.text = user.displayName ?? '';
      _emailController.text = user.email ?? '';

      // // Assuming phone number is stored in user's Firestore document
      // DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      // if (userDoc.exists) {
      //   setState(() {
      //     _phoneController.text = userDoc['phone'] ?? '';
      //   });
      // }
    }
  }

  void _calculateTotalCost() {
    setState(() {
      _totalCost = (_hours * widget.tablePrice) + _adminFee;
    });
  }

  void _incrementHours() {
    setState(() {
      _hours++;
      _calculateTotalCost();
    });
  }

  void _decrementHours() {
    if (_hours > 1) {
      setState(() {
        _hours--;
        _calculateTotalCost();
      });
    }
  }

  String formatRupiah(int value) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp');
    return formatter.format(value);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _selectTimeSlot(String time) {
    setState(() {
      _selectedTimeSlot = time;
    });
  }

  Future<void> _bookNow() async {
    if (_selectedTimeSlot == null || _dateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    // Simulate a delay and show loading animation
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      final midtransService = MidtransService();
      final redirectUrl = await midtransService.createTransaction(
        _totalCost,
        orderId,
        _nameController.text,
        _emailController.text,
        _phoneController.text,
      );

      await _saveBookingToFirestore(orderId);

      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              backgroundColor: Color(0xFF1F1F29),
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              title: Text(
                'Payment',
                style: TextStyle(color: Colors.white),
              ),
            ),
            body: WebViewWidget(
              controller: WebViewController()
                ..setJavaScriptMode(JavaScriptMode.unrestricted)
                ..setNavigationDelegate(
                  NavigationDelegate(
                    onPageStarted: (String url) {
                      if (url == 'https://example.com/') {
                        _onTransactionCompleted();
                      }
                    },
                  ),
                )
                ..loadRequest(Uri.parse(redirectUrl)),
            ),
          ),
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create transaction. Please try again.')),
      );
    }
  }

  Future<void> _saveBookingToFirestore(String orderId) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // User is not logged in, return or handle this case
      return;
    }

    final bookingData = {
      'userId': user.uid,
      'name': _nameController.text,
      'email': _emailController.text,
      'phone': _phoneController.text,
      'bookingDate': DateTime.now(),
      'timeSlot': '${_dateController.text} $_selectedTimeSlot:00',
      'hours': _hours,
      'table': widget.tableName,
      'tableId': widget.tableId,  // Tambahkan ini
      'status': 'pending',
      'amount': _totalCost,
      'order_id': orderId,
    };

    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(orderId)
        .set(bookingData);
  }

  void _listenToPaymentStatus() {
    FirebaseFirestore.instance
        .collection('bookings')
        .doc(orderId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data()?['status'] == 'settlement') {
        _onTransactionCompleted();
      }
    });
  }

  void _onTransactionCompleted() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentSuccessScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1F1F29),
      appBar: AppBar(
        backgroundColor: Color(0xFF1F1F29),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Booking Payment',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Information',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Color(0xFF2F304A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                hintText: 'Enter your name',
                hintStyle: TextStyle(color: Colors.white54),
              ),
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Color(0xFF2F304A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                hintText: 'Enter your email',
                hintStyle: TextStyle(color: Colors.white54),
              ),
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Color(0xFF2F304A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                hintText: 'Enter your phone number',
                hintStyle: TextStyle(color: Colors.white54),
              ),
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 20),
            Text(
              'Booking Information',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _dateController,
              readOnly: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: Color(0xFF2F304A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                hintText: 'Enter booking date',
                hintStyle: TextStyle(color: Colors.white54),
              ),
              style: TextStyle(color: Colors.white),
              onTap: () => _selectDate(context),
            ),
            SizedBox(height: 20),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTimeSlot('11:00'),
                    _buildTimeSlot('12:00'),
                    _buildTimeSlot('13:00'),
                    _buildTimeSlot('14:00'),
                    _buildTimeSlot('15:00'),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTimeSlot('16:00'),
                    _buildTimeSlot('17:00'),
                    _buildTimeSlot('18:00'),
                    _buildTimeSlot('19:00'),
                    _buildTimeSlot('20:00'),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Color(0xFF2F304A),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      widget.tableImageUrl,
                      height: 80,
                      width: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.tableName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              'Book for',
                              style: TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                            IconButton(
                              icon: Icon(Icons.remove_circle_outline, color: Colors.white),
                              onPressed: _decrementHours,
                            ),
                            Text(
                              '$_hours',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                            IconButton(
                              icon: Icon(Icons.add_circle_outline, color: Colors.white),
                              onPressed: _incrementHours,
                            ),
                            Text(
                              'hour(s)',
                              style: TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                          ],
                        ),
                        Text(
                          formatRupiah(widget.tablePrice),
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Summary',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Table Booking x $_hours hour(s)',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                Text(
                  formatRupiah(_hours * widget.tablePrice),
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Admin Fee',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                Text(
                  formatRupiah(_adminFee),
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
            Divider(color: Colors.white),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Grand Total',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  formatRupiah(_totalCost),
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF686DCD),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onPressed: _bookNow,
                child: Text(
                  'Book Now',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlot(String time) {
    bool isSelected = _selectedTimeSlot == time;
    return GestureDetector(
      onTap: () {
        _selectTimeSlot(time);
      },
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Color(0xFF2F304A),
          borderRadius: BorderRadius.circular(8.0),
          border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
        ),
        child: Text(
          time,
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}
