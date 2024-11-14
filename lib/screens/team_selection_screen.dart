import 'package:flutter/material.dart';
import 'draft_overview_screen.dart';

class TeamSelectionScreen extends StatefulWidget {
  @override
  _TeamSelectionScreenState createState() => _TeamSelectionScreenState();
}

class _TeamSelectionScreenState extends State<TeamSelectionScreen> {
  int _numberOfRounds = 1;
  double _speed = 1.0;
  double _randomness = 0.5;

  void _startDraft() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DraftApp()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('NFL Draft Setup'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                ),
                itemCount: 32,
                itemBuilder: (context, index) {
                  return ElevatedButton(
                    onPressed: () {
                      print("Team ${index + 1} selected");
                    },
                    child: Text('Team ${index + 1}'),
                  );
                },
              ),
            ),
            SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Number of Rounds:'),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Speed:'),
                Slider(
                  value: _speed,
                  min: 0.5,
                  max: 2.0,
                  divisions: 3,
                  label: '$_speed',
                  onChanged: (value) {
                    setState(() {
                      _speed = value;
                    });
                  },
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Randomness:'),
                Slider(
                  value: _randomness,
                  min: 0.0,
                  max: 1.0,
                  divisions: 5,
                  label: '$_randomness',
                  onChanged: (value) {
                    setState(() {
                      _randomness = value;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _startDraft,
              child: Text('Start Draft'),
            ),
          ],
        ),
      ),
    );
  }
}
