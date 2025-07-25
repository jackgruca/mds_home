# How to Access the Data Source Test Screen

## Method 1: Direct Web URL (Easiest if running on web)
If you're running Flutter on web, just append this to your URL:
```
http://localhost:<port>/#/test/data-source
```

For example:
- If your app is at `http://localhost:5000`, go to:
  - `http://localhost:5000/#/test/data-source`

## Method 2: Add Temporary Navigation (For mobile/desktop)

Add this temporary code to ANY screen where you want a test button:

```dart
// Add this anywhere in a build method (like in a Column or Row)
ElevatedButton(
  onPressed: () {
    Navigator.pushNamed(context, '/test/data-source');
  },
  child: Text('Test CSV Data'),
),
```

For example, in your Data Hub screen or any other screen you frequently use.

## Method 3: Use Flutter Inspector
1. Run your app in debug mode
2. Open Flutter Inspector
3. Select any widget
4. In the console, run:
```dart
Navigator.pushNamed(context, '/test/data-source');
```

## Method 4: Add to Existing Navigation
The test is already set up in your routes. You just need to navigate to it using the path `/test/data-source`.

## What You'll See
Once you navigate to the test screen, you'll see:
- Current data source (CSV or Firebase)
- Performance test results
- Toggle button to switch between sources
- Side-by-side performance comparison

This will help you validate that the CSV implementation is working correctly!