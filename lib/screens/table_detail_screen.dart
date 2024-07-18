import 'package:billiard_x/screens/booking_payment_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TableDetailScreen extends StatefulWidget {
  final String tableId;

  TableDetailScreen({required this.tableId});

  @override
  _TableDetailScreenState createState() => _TableDetailScreenState();
}

class _TableDetailScreenState extends State<TableDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<DocumentSnapshot> _fetchTableData() async {
    return await _firestore.collection('billiardTables').doc(widget.tableId).get();
  }

  Future<QuerySnapshot> _fetchReviews() async {
    return await _firestore.collection('billiardTables').doc(widget.tableId).collection('reviews').get();
  }

  String formatRupiah(int value) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp');
    return formatter.format(value);
  }

  void _showGallery(BuildContext context, List<String> gallery, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) {
        return GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            color: Colors.black,
            child: Center(
              child: PageView.builder(
                itemCount: gallery.length,
                controller: PageController(initialPage: initialIndex),
                itemBuilder: (context, index) {
                  return Image.network(
                    gallery[index],
                    fit: BoxFit.contain,
                  );
                },
              ),
            ),
          ),
        );
      },
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
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _fetchTableData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return Center(child: Text('No data available'));
          }

          var tableData = snapshot.data!;
          var gallery = List<String>.from(tableData['gallery']);
          var price = tableData['price'] as int;

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(
                        tableData['imageUrl'],
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      tableData['name'],
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        Image.asset(
                          'assets/images/location.png',
                          height: 15,
                          width: 15,
                        ),
                        SizedBox(
                          width: 5,
                        ),
                        Text(
                          tableData['location'],
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: gallery.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              _showGallery(context, gallery, index);
                            },
                            child: Container(
                              margin: EdgeInsets.only(right: 10),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: Image.network(
                                  gallery[index],
                                  width: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Table Information',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildTableInfo(
                          iconPath: 'assets/images/d.png',
                          label: 'Price',
                          value: '${formatRupiah(price)} / hrs',
                        ),
                        _buildTableInfo(
                          iconPath: 'assets/images/k.png',
                          label: 'Open',
                          value: 'Everyday',
                        ),
                        _buildTableInfo(
                          iconPath: 'assets/images/b.png',
                          label: 'Rating',
                          value: tableData['rating'].toString(),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Description',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      tableData['description'],
                      textAlign: TextAlign.justify,
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Reviews',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 10),
                    FutureBuilder<QuerySnapshot>(
                      future: _fetchReviews(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(child: Text('No reviews available', style: TextStyle(color: Colors.white)));
                        }

                        var reviews = snapshot.data!.docs;

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: reviews.length,
                          itemBuilder: (context, index) {
                            var review = reviews[index];
                            return ListTile(
                              title: Text(
                                review['userName'],
                                style: TextStyle(color: Colors.white),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: List.generate(5, (i) {
                                      return Icon(
                                        i < review['rating'] ? Icons.star : Icons.star_border,
                                        color: Colors.yellow,
                                      );
                                    }),
                                  ),
                                  Text(
                                    review['review'],
                                    style: TextStyle(color: Colors.white54),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                    SizedBox(height: 80), // Space for the fixed buttons
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  color: Color(0xFF1F1F29),
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF686DCD),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BookingPaymentScreen(
                                  tableId: widget.tableId,
                                  tableName: tableData['name'],
                                  tableImageUrl: tableData['imageUrl'],
                                  tablePrice: price,
                                ),
                              ),
                            );
                            // Implement booking function here
                          },
                          child: Text(
                            'Book Now',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTableInfo({
    required String iconPath,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Image.asset(
              iconPath,
              height: 24,
              width: 24,
            ),
            SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                Text(
                  value,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
