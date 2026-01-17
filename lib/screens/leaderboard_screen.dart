import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  int _selectedTab = 2; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, 
      appBar: AppBar(
        title: Text("LEADERBOARD", style: GoogleFonts.bebasNeue(letterSpacing: 2, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').orderBy('xp', descending: true).limit(10).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.white));
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No data available", style: TextStyle(color: Colors.grey)));

          final users = snapshot.data!.docs;

          // Helpers
          Map<String, dynamic> getUser(int index) => index < users.length ? users[index].data() as Map<String, dynamic> : {};
          String getName(int index) => (getUser(index)['displayName'] ?? (getUser(index)['email'] ?? "User").split('@')[0]);
          String getScore(int index) => "${getUser(index)['xp'] ?? 0}";
          String getRole(int index) => getUser(index)['role'] ?? 'student';

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.only(bottom: 30),
                decoration: const BoxDecoration(color: Colors.transparent, border: Border(bottom: BorderSide(color: Colors.white24))),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.white12)),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [_buildTab("Today", 0), _buildTab("This Week", 1), _buildTab("All Time", 2)]),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (users.length > 1) _buildPodiumItem(rank: 2, name: getName(1), score: getScore(1), role: getRole(1), color: Colors.grey[800]!, height: 140, avatarColor: Colors.grey[400]!, rankColor: const Color(0xFFC0C0C0), scoreColor: Colors.greenAccent),
                        if (users.isNotEmpty) _buildPodiumItem(rank: 1, name: getName(0), score: getScore(0), role: getRole(0), color: Colors.white, height: 180, avatarColor: Colors.white, isWinner: true, textColor: Colors.black, rankColor: const Color(0xFFFFD700), scoreColor: Colors.green[800]!),
                        if (users.length > 2) _buildPodiumItem(rank: 3, name: getName(2), score: getScore(2), role: getRole(2), color: Colors.grey[900]!, height: 110, avatarColor: Colors.grey[600]!, rankColor: const Color(0xFFCD7F32), scoreColor: Colors.greenAccent),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: users.length > 3 ? users.length - 3 : 0,
                  itemBuilder: (context, index) {
                    int dataIndex = index + 3;
                    return _buildListItem(index + 4, getName(dataIndex), "${getScore(dataIndex)} pts", getRole(dataIndex));
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTab(String text, int index) {
    bool isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(color: isSelected ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: TextStyle(color: isSelected ? Colors.black : Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }

  Widget _buildPodiumItem({required int rank, required String name, required String score, required String role, required Color color, required double height, required Color avatarColor, bool isWinner = false, Color textColor = Colors.white, required Color rankColor, required Color scoreColor}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.topRight,
          clipBehavior: Clip.none,
          children: [
            Container(padding: const EdgeInsets.all(3), decoration: BoxDecoration(shape: BoxShape.circle, color: isWinner ? Colors.white : Colors.grey[800]), child: CircleAvatar(radius: 30, backgroundColor: isWinner ? Colors.black : Colors.black54, child: Text(name[0].toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: isWinner ? Colors.white : Colors.grey, fontSize: 20)))),
            if (isWinner) const Positioned(top: -15, right: -5, child: Icon(Icons.workspace_premium, color: Color(0xFFFFD700), size: 30)), 
          ],
        ),
        const SizedBox(height: 15),
        Container(
          width: 90, height: height,
          decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.vertical(top: Radius.circular(15)), border: Border.all(color: isWinner ? const Color(0xFFFFD700) : Colors.white24, width: isWinner ? 2 : 1), boxShadow: isWinner ? [BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.4), blurRadius: 25, spreadRadius: 1)] : []),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(rank.toString(), style: GoogleFonts.bebasNeue(fontSize: 48, color: rankColor)),
                  const SizedBox(height: 4),
                  Text(name, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14)),
                  // HELPER BADGE
                  if (role.toLowerCase() == 'helper')
                    Container(margin: const EdgeInsets.symmetric(vertical: 2), padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(4)), child: const Text("HELPER", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black))),
                  const SizedBox(height: 2),
                  Text(score, style: TextStyle(color: scoreColor, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListItem(int rank, String name, String points, String role) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
      child: Row(
        children: [
          Container(width: 30, alignment: Alignment.center, child: Text(rank.toString().padLeft(2, '0'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white54))),
          const SizedBox(width: 15),
          CircleAvatar(radius: 20, backgroundColor: Colors.white10, child: Icon(Icons.person, color: Colors.grey[400])),
          const SizedBox(width: 15),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                if (role.toLowerCase() == 'helper') ...[
                  const SizedBox(width: 8),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.orangeAccent, borderRadius: BorderRadius.circular(4)), child: const Text("HELPER", style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold))),
                ]
              ],
            ),
            Text(points, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ]),
        ],
      ),
    );
  }
}