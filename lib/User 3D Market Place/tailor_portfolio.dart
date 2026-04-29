import 'package:flutter/material.dart';
import 'chat.dart';
import 'reel.dart';

class TailorPortfolioScreen extends StatelessWidget {
  final Map<String, dynamic> tailor;

  const TailorPortfolioScreen({
    super.key,
    this.tailor = const {
      'name': 'Master Tailor John',
      'image': 'assets/3.webp',
      'rating': 4.8,
      'about': 'Expert in men\'s bespoke tailoring with over 15 years of experience. Specializing in Sherwani and Shalwar Kameez.',
    },
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Tailor Profile"),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                   CircleAvatar(
                     radius: 40,
                     backgroundImage: AssetImage(tailor['image']),
                   ),
                   SizedBox(width: 20),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(
                           tailor['name'],
                           style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                         ),
                         SizedBox(height: 5),
                         Row(
                           children: [
                             Icon(Icons.star, color: Colors.amber, size: 20),
                             SizedBox(width: 5),
                             Text(tailor['rating'].toString(), style: TextStyle(fontWeight: FontWeight.bold)),
                             Text(" (120 orders)", style: TextStyle(color: Colors.grey)),
                           ],
                         ),
                       ],
                     ),
                   ),
                ],
              ),
            ),
            
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                         Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen()));
                      },
                      icon: Icon(Icons.message, color: Colors.white),
                      label: Text("Message", style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF059669), 
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      child: Text("Follow", style: TextStyle(color: Colors.black)),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 25),
            
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("About", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text(
                    tailor['about'],
                    style: TextStyle(color: Colors.grey[700], height: 1.5),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 25),
            
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text("Work Showcase", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: 15),
            
            
            GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ReelScreen()));
              },
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 20),
                height: 350,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.black,
                  image: DecorationImage(
                    image: AssetImage('assets/6.webp'), 
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken),
                  ),
                ),
                child: Center(
                  child: Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(Icons.play_arrow, color: Colors.white, size: 40),
                  ),
                ),
              ),
            ),
            Padding(
               padding: const EdgeInsets.all(20.0),
               child: Text("Tailored Suits Collection 2023", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
