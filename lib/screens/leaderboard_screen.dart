import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  int _selectedTab = 1; // 0: Today, 1: This Week, 2: All Time

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA), // Light Gray Background for the list part
      appBar: AppBar(
        title: Text("LEADERBOARD", style: GoogleFonts.bebasNeue(letterSpacing: 2)),
        centerTitle: true,
        backgroundColor: const Color(0xFF6246EA), // Deep Purple Header
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: () {},
          )
        ],
      ),
      body: Column(
        children: [
          // ---------------------------------------------
          // SECTION 1: THE PURPLE HEADER & PODIUM
          // ---------------------------------------------
          Container(
            padding: const EdgeInsets.only(bottom: 30),
            decoration: const BoxDecoration(
              color: Color(0xFF6246EA), // Deep Purple Brand Color
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // THE TABS (Today / This Week / All Time)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildTab("Today", 0),
                      _buildTab("This Week", 1),
                      _buildTab("All Time", 2),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // THE PODIUM (2 - 1 - 3 Layout)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end, // Align everything to the bottom
                  children: [
                    // Rank 2 (Left)
                    _buildPodiumItem(
                      rank: 2, 
                      name: "Camelia", 
                      score: "6,500", 
                      color: const Color(0xFF0090FF), // Bright Blue
                      height: 140, 
                      avatarColor: Colors.orangeAccent
                    ),
                    // Rank 1 (Center, Taller)
                    _buildPodiumItem(
                      rank: 1, 
                      name: "HARI", // YOU!
                      score: "7,120", 
                      color: const Color(0xFF8F6ED5), // Lighter Purple
                      height: 180, 
                      isWinner: true,
                      avatarColor: const Color(0xFF00F0FF) // Cyan for you
                    ),
                    // Rank 3 (Right)
                    _buildPodiumItem(
                      rank: 3, 
                      name: "Wilson", 
                      score: "4,800", 
                      color: const Color(0xFF003F88), // Dark Blue
                      height: 110, 
                      avatarColor: Colors.pinkAccent
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ---------------------------------------------
          // SECTION 2: THE LIST (Rank 4+)
          // ---------------------------------------------
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildListItem(4, "Jessica Anderson", "992 pts"),
                _buildListItem(5, "Sophia Anderson", "584 pts"),
                _buildListItem(6, "Ethan Carter", "448 pts"),
                _buildListItem(7, "Liam Johnson", "580 pts"),
                _buildListItem(8, "Noah Williams", "320 pts"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------
  // HELPER WIDGETS
  // ---------------------------------------------

  Widget _buildTab(String text, int index) {
    bool isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? const Color(0xFF6246EA) : Colors.white70,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildPodiumItem({
    required int rank,
    required String name,
    required String score,
    required Color color,
    required double height,
    required Color avatarColor,
    bool isWinner = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar + Crown if winner
        Stack(
          alignment: Alignment.topRight,
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: avatarColor,
                child: Text(
                  name[0], // First letter of name
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20),
                ),
              ),
            ),
            if (isWinner)
              const Positioned(
                top: -15,
                right: -5,
                child: Icon(Icons.workspace_premium, color: Color(0xFFFFD700), size: 30), // Gold Crown
              ),
          ],
        ),
        
        const SizedBox(height: 15),

        // The Podium Block
        Container(
          width: 90,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                rank.toString(),
                style: GoogleFonts.bebasNeue(
                  fontSize: 48,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  score, 
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListItem(int rank, String name, String points) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, // White card for contrast
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
           BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ]
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            alignment: Alignment.center,
            child: Text(
              rank.toString().padLeft(2, '0'),
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
            ),
          ),
          const SizedBox(width: 15),
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey.shade200,
            child: Icon(Icons.person, color: Colors.grey.shade400),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Text(
                "$points points",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          const Icon(Icons.arrow_drop_up, color: Colors.green), // Indicator that they are moving up
        ],
      ),
    );
  }
}