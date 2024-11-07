import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'draft_order_page.dart';
import 'available_players_page.dart';

class DraftApp extends StatefulWidget {
  @override
  _DraftAppState createState() => _DraftAppState();
}

class _DraftAppState extends State<DraftApp> {
  int _selectedIndex = 0;
  List<List<dynamic>> _draftOrder = [];
  int _numberOfRounds = 1;

  @override
  void initState() {
    super.initState();
    _loadDraftOrder();
  }

  Future<void> _loadDraftOrder() async {
    final data = await rootBundle.loadString('assets/draft_order.csv');
    List<List<dynamic>> csvTable = const CsvToListConverter().convert(data);
    setState(() {
      _draftOrder = csvTable.take(33).toList();
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('NFL Draft App'),
      ),
body: _selectedIndex == 0
    ? Column(
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
      )
    : _selectedIndex == 1
        ? AvailablePlayersPage(draftOrder: _draftOrder)
        : TeamNeedsPage(),  // Display TeamNeedsPage when selected
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

class TeamNeedsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Team Needs will be displayed here.'),
    );
  }
}
