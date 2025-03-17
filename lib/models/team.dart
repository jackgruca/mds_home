// lib/models/team.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TeamData {
  final String name;
  final String? logo;
  final String? abbreviation;
  
  const TeamData({
    required this.name,
    this.logo,
    this.abbreviation,
  });
  
  static Future<TeamData> fromName(String teamName) async {
    String? logo = await _getTeamLogoAddress(teamName);
    return TeamData(
      name: teamName,
      logo: logo,
    );
  }
  
  // Logic to fetch team logo from ESPN API
  static Future<String?> _getTeamLogoAddress(String teamName) async {
    try {
      String teamID = await _getTeamID(teamName);
      if (teamID == "TEAM ID NOT FOUND") return null;

      final teamData = await _getTeamAPI(teamID);
      if (teamData.isNotEmpty) {
        return teamData['logos']?[0]['href'];
      }
    } catch (e) {
      debugPrint("Error getting team logo address: $e");
    }
    return null;
  }

  static Future<String> _getTeamID(String teamName) async {
    String url = "https://site.api.espn.com/apis/site/v2/sports/football/nfl/teams";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['sports'] != null) {
          for (var sport in data['sports']) {
            if (sport['leagues'] != null) {
              for (var league in sport['leagues']) {
                if (league['teams'] != null) {
                  for (var team in league['teams']) {
                    if (team['team'] != null) {
                      String? location = team['team']['location'];
                      String? name = team['team']['name'];
                      String teamLocAndName = "$location $name";
                      if (teamLocAndName.toLowerCase() == teamName.toLowerCase()) {
                        String id = team['team']['id'];
                        return id;
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching team ID: $teamName...$e');
    }
    return "TEAM ID NOT FOUND";
  }

  static Future<Map<String, dynamic>> _getTeamAPI(String teamID) async {
    String url = 'https://site.api.espn.com/apis/site/v2/sports/football/nfl/teams/$teamID';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        return data['team'] ?? {};
      }
    } catch (e) {
      debugPrint('Error fetching team info: $e');
    }
    return {};
  }
}

// This is the Team widget, but renamed to make it distinct from the model
class TeamSelector extends StatefulWidget {
  final String teamName;
  final ValueChanged<String> onTeamSelected;

  const TeamSelector({
    super.key,
    required this.teamName,
    required this.onTeamSelected,
  });

  @override
  TeamSelectorState createState() => TeamSelectorState();
}

class TeamSelectorState extends State<TeamSelector> {
  String? teamLogo;
  bool isHovered = false;

  @override
  void initState() {
    super.initState();
    _fetchTeamLogo();
  }

  Future<void> _fetchTeamLogo() async {
    try {
      final logo = await TeamData._getTeamLogoAddress(widget.teamName);
      setState(() {
        teamLogo = logo;
      });
    } catch (e) {
      debugPrint("Error fetching logo: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    String imgNotFound =
        "https://media.istockphoto.com/id/1409329028/vector/no-picture-available-placeholder-thumbnail-icon-illustration-design.jpg?s=612x612&w=0&k=20&c=_zOuJu755g2eEUioiOUdz_mHKJQJn-tDgIAhQzyeKUQ=";

    return GestureDetector(
      onTap: () {
        widget.onTeamSelected(widget.teamName);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MouseRegion(
            onEnter: (_) => setState(() => isHovered = true),
            onExit: (_) => setState(() => isHovered = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 100.0,
              height: 100.0,
              decoration: BoxDecoration(
                color: isHovered ? Colors.black.withOpacity(0.5) : Colors.grey,
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: NetworkImage(
                    teamLogo ?? imgNotFound,
                  ),
                  fit: BoxFit.cover,
                  colorFilter: isHovered
                      ? ColorFilter.mode(
                          Colors.black.withOpacity(0.5), BlendMode.darken)
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            widget.teamName,
            style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16.0),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}