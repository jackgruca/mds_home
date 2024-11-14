import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'available_players_page.dart';
import 'draft_order_page.dart';
import 'team_needs_page.dart';

bool _isLoadingAvailablePlayers = true;
bool _isLoadingTeamNeeds = true;

class DraftApp extends StatefulWidget {
  @override
  _DraftAppState createState() => _DraftAppState();
}

class _DraftAppState extends State<DraftApp> {
  int _selectedIndex = 1;
  List<List<dynamic>> _draftOrder = [];
  List<List<dynamic>> _availablePlayers = [];
  List<List<dynamic>> _teamNeeds = [];
  int _numberOfRounds = 1;

  @override
  void initState() {
    super.initState();
    _loadDraftOrder();
    _loadAvailablePlayers();
    _loadTeamNeeds();
  }

  Future<void> _loadDraftOrder() async {
    final data = await rootBundle.loadString('assets/draft_order.csv');
    List<List<dynamic>> csvTable = const CsvToListConverter().convert(data);
    setState(() {
      _draftOrder = csvTable.take(33).toList(); // Take first 32 rows + header
    });
  }

  Future<void> _loadAvailablePlayers() async {
    try {
      final data = await rootBundle.loadString('assets/available_players.csv');
      List<List<dynamic>> csvTable = const CsvToListConverter().convert(data);
      setState(() {
        _availablePlayers = csvTable;
        _isLoadingAvailablePlayers = false; // Set loading to false after data is loaded

      });
      print("Available Players Loaded: $_availablePlayers"); // Debugging statement
    } catch (e) {
      print("Error loading available players CSV: $e");
      setState(() {
        _isLoadingAvailablePlayers = false; // Stop loading state on error
    });
    }
  }

  Future<void> _loadTeamNeeds() async {
    try {
      final data = await rootBundle.loadString('assets/team_needs.csv');
      List<List<dynamic>> csvTable = const CsvToListConverter().convert(data);
      setState(() {
        _teamNeeds = csvTable;
        _isLoadingTeamNeeds = false; // Set loading to false after data is loaded

      });
      print("Team Needs Loaded: $_teamNeeds"); // Debugging statement
    } catch (e) {
      print("Error loading team needs CSV: $e");
      setState(() {
        _isLoadingTeamNeeds = false; // Stop loading state on error
    });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }


  @override
  Widget build(BuildContext context) {
    Widget currentPage;
    switch (_selectedIndex) {
      case 0:
        currentPage = Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Select Number of Rounds:'),
                  DropdownButton<int>(
                    value: _numberOfRounds,
                    onChanged: (int? newValue) {
                      setState(() {
                        _numberOfRounds = newValue ?? 1;
                      });
                    },
                    items: List.generate(7, (index) => index + 1)
                        .map<DropdownMenuItem<int>>((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text(value.toString()),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            Expanded(child: DraftOrderPage(draftOrder: _draftOrder)),
          ],
        );
        break;
      case 1:
        currentPage = _isLoadingAvailablePlayers
            ? Center(child: CircularProgressIndicator())
            : AvailablePlayersPage(availablePlayers: _availablePlayers);
        break;
      default:
        currentPage = _isLoadingTeamNeeds
            ? Center(child: CircularProgressIndicator())
            : TeamNeedsPage(teamNeeds: _teamNeeds);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('NFL Draft App'),
      ),
      body: currentPage,
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Draft Order',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Available Players',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Team Needs',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}
