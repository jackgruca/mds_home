import 'package:flutter/material.dart';
import 'available_players_tab.dart';
import 'team_needs_tab.dart';
import 'draft_order_tab.dart';
import '../../widgets/draft/draft_control_buttons.dart';

class DraftApp extends StatefulWidget {
  const DraftApp({super.key});

  @override
  DraftAppState createState() => DraftAppState();
}

class DraftAppState extends State<DraftApp> {
  int _selectedIndex = 0;
  bool _isDraftRunning = false;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _toggleDraft() {
    setState(() {
      _isDraftRunning = !_isDraftRunning;
    });
  }

  void _restartDraft() {
    setState(() {
      _isDraftRunning = false;
      // Logic to reset the draft goes here
    });
  }

  void _requestTrade() {
    // Logic to request a trade goes here
    debugPrint("Trade requested");
  }

  @override
  Widget build(BuildContext context) {
    Widget currentPage;
    switch (_selectedIndex) {
      case 0:
        currentPage = DraftOrderTab();
        break;
      case 1:
        currentPage = AvailablePlayersTab();
        break;
      default:
        currentPage = TeamNeedsTab();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('NFL Draft'),
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: DraftControlButtons(
        isDraftRunning: _isDraftRunning,
        onToggleDraft: _toggleDraft,
        onRestartDraft: _restartDraft,
        onRequestTrade: _requestTrade,
      ),
    );
  }
}
