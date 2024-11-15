import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Team extends StatefulWidget {
  final String teamName;

  const Team({
    super.key,
    required this.teamName,
  });

  @override
  TeamState createState() => TeamState();
}

class TeamState extends State<Team> {
  String? teamLogo;

  @override
  void initState() {
    super.initState();
    _fetchTeamLogo();
  }

  Future<void> _fetchTeamLogo() async {
    try {
      final logo = await _getTeamLogoAddress(widget.teamName);
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 100.0,
          height: 100.0,
          decoration: BoxDecoration(
            color: Colors.grey,
            shape: BoxShape.circle,
            image: DecorationImage(
              image: NetworkImage(
                teamLogo ?? imgNotFound,
              ),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 8.0), // Space between image and text
        Text(
          widget.teamName,
          style: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16.0),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<String> _getTeamLogoAddress(String teamName) async {
    try {
      String teamID = await getTeamID(teamName);
      if (teamID == "TEAM ID NOT FOUND") return "Unknown";

      final teamData = await _getTeamAPI(teamID);
      if (teamData.isNotEmpty) {
        return teamData['logos']?[0]['href'] ?? "Unknown";
      }
    } catch (e) {
      debugPrint("Error getting team logo address: $e");
    }
    return "Unknown"; // Fallback
  }

  Future<String> getTeamID(String teamName) async {
    String url =
        "https://site.api.espn.com/apis/site/v2/sports/football/nfl/teams";
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
                      if (teamLocAndName.toLowerCase() ==
                          teamName.toLowerCase()) {
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
    debugPrint("Team ID not found... $teamName...");
    return "TEAM ID NOT FOUND";
  }

  Future<Map<String, dynamic>> _getTeamAPI(String teamID) async {
    String url =
        'https://site.api.espn.com/apis/site/v2/sports/football/nfl/teams/$teamID';
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
