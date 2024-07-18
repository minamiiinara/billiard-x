import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../widgets/custom_bottom_navigation_bar.dart';

class BookingsScreen extends StatefulWidget {
  @override
  _BookingsScreenState createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  int _currentIndex = 1;

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Center(child: Text("No user logged in"));
    }

    return Scaffold(
      backgroundColor: Color(0xFF1F1F29),
      body: Column(
        children: [
          SizedBox(height: 40), // Menambahkan jarak di atas teks "My Bookings"
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                SizedBox(width: 10),
                Text(
                  'My Bookings',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .where('userId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No bookings available', style: TextStyle(color: Colors.white)));
                }

                var bookings = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    var booking = bookings[index];
                    return Card(
                      color: Color(0xFF2F304A),
                      margin: EdgeInsets.all(10),
                      child: ListTile(
                        title: Text(booking['table'], style: TextStyle(color: Colors.white)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Date: ${DateFormat('dd MMM yyyy HH:mm').format(booking['bookingDate'].toDate())}",
                              style: TextStyle(color: Colors.white54),
                            ),
                            SizedBox(height: 5),
                            _buildStatusBadge(booking['status']),
                          ],
                        ),
                        trailing: Icon(Icons.arrow_forward_ios, color: Colors.white),
                        onTap: () {
                          Navigator.pushNamed(context, '/bookingDetail', arguments: booking);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index != _currentIndex) {
            if (index == 0) {
              Navigator.pushReplacementNamed(context, '/home');
            } else if (index == 1) {
              Navigator.pushReplacementNamed(context, '/bookings');
            }
          }
        },
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
}
