import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NFL Draft App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: DraftApp(),
    );
  }
}

class DraftApp extends StatefulWidget {
  @override
  _DraftAppState createState() => _DraftAppState();
}

class _DraftAppState extends State<DraftApp> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    DraftOrderPage(),
    AvailablePlayersPage(),
  ];

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
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Draft',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Available Players',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}

class DraftOrderPage extends StatelessWidget {
  // Sample draft order data, replace with real data from backend
  final List<Map<String, dynamic>> draftOrder = [
    {'Pick': 1, 'Team': 'Chicago Bears', 'Previous Record': '3-14'},
    {'Pick': 2, 'Team': 'Houston Texans', 'Previous Record': '3-13-1'},
    {'Pick': 3, 'Team': 'Arizona Cardinals', 'Previous Record': '4-13'},
    // Add more draft picks here
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Expanded(
            child: DataTable(
              columns: [
                DataColumn(label: Text('Pick')),
                DataColumn(label: Text('Team')),
                DataColumn(label: Text('Previous Record')),
              ],
              rows: draftOrder
                  .map(
                    (pick) => DataRow(cells: [
                      DataCell(Text(pick['Pick'].toString())),
                      DataCell(Text(pick['Team'])),
                      DataCell(Text(pick['Previous Record'])),
                    ]),
                  )
                  .toList(),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Draft logic will be implemented here
            },
            child: Text('Draft'),
          ),
        ],
      ),
    );
  }
}

class AvailablePlayersPage extends StatelessWidget {
  // Sample available players data, replace with real data from backend
  final List<Map<String, dynamic>> availablePlayers = [
    {'Player': 'Player A', 'Position': 'QB', 'College': 'Alabama'},
    {'Player': 'Player B', 'Position': 'WR', 'College': 'LSU'},
    {'Player': 'Player C', 'Position': 'RB', 'College': 'Georgia'},
    // Add more players here
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: DataTable(
        columns: [
          DataColumn(label: Text('Player')),
          DataColumn(label: Text('Position')),
          DataColumn(label: Text('College')),
        ],
        rows: availablePlayers
            .map(
              (player) => DataRow(cells: [
                DataCell(Text(player['Player'])),
                DataCell(Text(player['Position'])),
                DataCell(Text(player['College'])),
              ]),
            )
            .toList(),
      ),
    );
  }
}
