import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReviewBottomSheet extends StatefulWidget {
  final String tableId;
  final String bookingId;

  ReviewBottomSheet({required this.tableId, required this.bookingId});

  @override
  _ReviewBottomSheetState createState() => _ReviewBottomSheetState();
}

class _ReviewBottomSheetState extends State<ReviewBottomSheet> {
  final TextEditingController _reviewController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  double _rating = 0.0;

  void _submitReview() async {
    if (_reviewController.text.isEmpty || _rating == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please provide a review and rating.'),
        ),
      );
      return;
    }

    User? user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You need to be logged in to submit a review.'),
        ),
      );
      return;
    }

    final userData = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final userName = userData['name'];

    final reviewData = {
      'userId': user.uid,
      'userName': userName,
      'tableId': widget.tableId,
      'bookingId': widget.bookingId,
      'review': _reviewController.text,
      'rating': _rating,
      'timestamp': Timestamp.now(),
    };

    await FirebaseFirestore.instance
        .collection('billiardTables')
        .doc(widget.tableId)
        .collection('reviews')
        .add(reviewData);

    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(widget.bookingId)
        .collection('reviews')
        .doc(user.uid)
        .set(reviewData);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your Rating',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.yellow,
                  ),
                  onPressed: () {
                    setState(() {
                      _rating = index + 1.0;
                    });
                  },
                );
              }),
            ),
            SizedBox(height: 20),
            Text(
              'Your Review',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _reviewController,
              maxLines: 5,
              decoration: InputDecoration(
                filled: true,
                fillColor: Color(0xFF2F304A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                hintText: 'Enter your review',
                hintStyle: TextStyle(color: Colors.white54),
              ),
              style: TextStyle(color: Colors.white),
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
                onPressed: _submitReview,
                child: Text(
                  'Submit Review',
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
}

void showReviewBottomSheet(BuildContext context, String tableId, String bookingId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Color(0xFF1F1F29),
    builder: (context) {
      return ReviewBottomSheet(
        tableId: tableId,
        bookingId: bookingId,
      );
    },
  );
}
