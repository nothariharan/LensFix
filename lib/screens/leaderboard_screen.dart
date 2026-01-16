import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  int _selectedTab = 1; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // NOIR THEME
      appBar: AppBar(
        title: Text("LEADERBOARD", style: GoogleFonts.bebasNeue(letterSpacing: 2, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // HEADER & PODIUM
          Container(
            padding: const EdgeInsets.only(bottom: 30),
            decoration: const BoxDecoration(
              color: Colors.transparent, 
              border: Border(bottom: BorderSide(color: Colors.white24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // TABS
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.white12),
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

                // PODIUM (Greyscale / Monochrome)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildPodiumItem(2, "Camelia", "6,500", Colors.grey[800]!, 140, Colors.grey[400]!),
                    _buildPodiumItem(1, "HARI", "7,120", Colors.white, 180, Colors.white, isWinner: true, textColor: Colors.black),
                    _buildPodiumItem(3, "Wilson", "4,800", Colors.grey[900]!, 110, Colors.grey[600]!),
                  ],
                ),
              ],
            ),
          ),

          // LIST
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
            color: isSelected ? Colors.black : Colors.grey,
            fontWeight: FontWeight.bold, fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildPodiumItem(int rank, String name, String score, Color color, double height, Color avatarColor, {bool isWinner = false, Color textColor = Colors.white}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.topRight,
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(shape: BoxShape.circle, color: isWinner ? Colors.white : Colors.grey[800]),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: isWinner ? Colors.black : Colors.black54,
                child: Text(name[0], style: TextStyle(fontWeight: FontWeight.bold, color: isWinner ? Colors.white : Colors.grey, fontSize: 20)),
              ),
            ),
            if (isWinner)
              const Positioned(
                top: -15, right: -5,
                child: Icon(Icons.workspace_premium, color: Colors.white, size: 30), // White Crown
              ),
          ],
        ),
        const SizedBox(height: 15),
        Container(
          width: 90, height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(rank.toString(), style: GoogleFonts.bebasNeue(fontSize: 48, color: textColor.withOpacity(0.5))),
              const SizedBox(height: 4),
              Text(name, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 2),
              Text(score, style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.bold)),
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
        color: const Color(0xFF111111), // Dark Grey Card
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 30, alignment: Alignment.center,
            child: Text(rank.toString().padLeft(2, '0'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          const SizedBox(width: 15),
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white10,
            child: Icon(Icons.person, color: Colors.grey[400]),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              Text("$points points", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}