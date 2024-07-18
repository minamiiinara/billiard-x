import 'package:billiard_x/widgets/review_bottom_sheet.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class BookingDetailScreen extends StatefulWidget {
  final DocumentSnapshot booking;

  BookingDetailScreen({required this.booking});

  @override
  _BookingDetailScreenState createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  bool _hasReviewed = false;

  @override
  void initState() {
    super.initState();
    _checkIfReviewed();
  }

  Future<void> _checkIfReviewed() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final reviews = await FirebaseFirestore.instance
          .collection('billiardTables')
          .doc(widget.booking['tableId'])
          .collection('reviews')
          .where('userId', isEqualTo: userId)
          .where('bookingId', isEqualTo: widget.booking.id)
          .get();

      if (reviews.docs.isNotEmpty) {
        setState(() {
          _hasReviewed = true;
        });
      }
    }
  }

  void _showReviewBottomSheet(BuildContext context, String tableId, String bookingId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Color(0xFF1F1F29),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return ReviewBottomSheet(tableId: tableId, bookingId: bookingId);
      },
    ).then((_) {
      _checkIfReviewed();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1F1F29),
      appBar: AppBar(
        backgroundColor: Color(0xFF1F1F29),
        elevation: 0,
        title: Text('Booking Details', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Color(0xFF2F304A),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Amount', style: TextStyle(color: Colors.white54, fontSize: 16)),
                      Text(formatRupiah(widget.booking['amount']), style: TextStyle(color: Colors.white, fontSize: 18)),
                      SizedBox(height: 10),
                      Text('Date', style: TextStyle(color: Colors.white54, fontSize: 16)),
                      Text(DateFormat('HH:mm, dd MMM yyyy').format(widget.booking['bookingDate'].toDate()), style: TextStyle(color: Colors.white, fontSize: 18)),
                      SizedBox(height: 10),
                      Text('Place Booked', style: TextStyle(color: Colors.white54, fontSize: 16)),
                      Text(widget.booking['table'], style: TextStyle(color: Colors.white, fontSize: 18)),
                      SizedBox(height: 10),
                      Text('Time Booked', style: TextStyle(color: Colors.white54, fontSize: 16)),
                      Text(widget.booking['timeSlot'], style: TextStyle(color: Colors.white, fontSize: 18)),
                      SizedBox(height: 10),
                      Text('Status', style: TextStyle(color: Colors.white54, fontSize: 16)),
                      SizedBox(height: 5),
                      _buildStatusBadge(widget.booking['status']),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Center(
                  child: Text(
                    widget.booking['status'] == 'paid'
                        ? 'Show this receipt to the receptionist to claim your booking'
                        : 'Check your email for payment instructions. It may take a few minutes for the payment to be validated.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                Spacer(),
              ],
            ),
          ),
          if (widget.booking['status'] == 'paid')
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Color(0xFF1F1F29),
                padding: const EdgeInsets.all(20.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF686DCD),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onPressed: _hasReviewed
                        ? null
                        : () {
                            _showReviewBottomSheet(context, widget.booking['tableId'], widget.booking.id);
                          },
                    child: Text(
                      _hasReviewed ? 'Thank you for submitting your review' : 'Put a Review',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case 'paid':
        backgroundColor = Colors.green.withOpacity(0.2);
        textColor = Colors.green;
        break;
      case 'pending':
        backgroundColor = Colors.blue.withOpacity(0.2);
        textColor = Colors.blue;
        break;
      case 'need to pay':
        backgroundColor = Colors.red.withOpacity(0.2);
        textColor = Colors.red;
        break;
      default:
        backgroundColor = Colors.grey.withOpacity(0.2);
        textColor = Colors.grey;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
      ),
    );
  }

  String formatRupiah(int value) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp');
    return formatter.format(value);
  }
}
