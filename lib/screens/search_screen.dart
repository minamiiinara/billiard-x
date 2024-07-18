import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  void _performSearch() {
    setState(() {
      _searchQuery = _searchController.text;
    });
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
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search',
            hintStyle: TextStyle(color: Colors.white54),
            border: InputBorder.none,
          ),
          style: TextStyle(color: Colors.white),
          onSubmitted: (value) => _performSearch(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: _performSearch,
          ),
        ],
      ),
      body: _searchQuery.isEmpty
          ? Center(child: Text('Enter a search query to get results', style: TextStyle(color: Colors.white54)))
          : StreamBuilder(
              stream: _firestore.collection('billiardTables').snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData) {
                  return Center(child: Text('No data available'));
                }

                final data = snapshot.data!.docs;
                final searchQuery = _searchQuery.toLowerCase();
                final filteredData = data.where((doc) {
                  final name = doc['name'].toString().toLowerCase();
                  final location = doc['location'].toString().toLowerCase();
                  return name.contains(searchQuery) || location.contains(searchQuery);
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: filteredData.length,
                  itemBuilder: (context, index) {
                    final item = filteredData[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/tableDetail',
                          arguments: item.id,
                        );
                      },
                      child: Container(
                        margin: EdgeInsets.only(bottom: 10),
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Color(0xFF131316),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Stack(
                          children: [
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Image.network(
                                    item['imageUrl'],
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
                                        item['name'],
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 5),
                                      Text(
                                        'Open Everyday',
                                        style: TextStyle(color: Colors.white54, fontSize: 12),
                                      ),
                                      Row(
                                        children: [
                                          Image.asset(
                                            'assets/images/dollar-square.png',
                                            height: 12,
                                            width: 12,
                                          ),
                                          SizedBox(width: 4),
                                          RichText(
                                            text: TextSpan(
                                              children: [
                                                TextSpan(
                                                  text: item['price'].toString(),
                                                  style: TextStyle(color: Colors.white, fontSize: 12),
                                                ),
                                                TextSpan(
                                                  text: ' / hrs',
                                                  style: TextStyle(color: Colors.white54, fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Image.asset(
                                            'assets/images/location.png',
                                            height: 12,
                                            width: 12,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            item['location'],
                                            style: TextStyle(color: Colors.white54, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Positioned(
                              top: 5,
                              right: 5,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4.0),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    color: Colors.black.withOpacity(0.5),
                                    child: Row(
                                      children: [
                                        Text(
                                          item['rating'].toString(),
                                          style: TextStyle(color: Colors.white, fontSize: 12),
                                        ),
                                        Icon(Icons.star, color: Colors.yellow, size: 14),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
