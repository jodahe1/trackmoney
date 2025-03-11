import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // Import the intl package

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Spending Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  double _totalSpent = 0.0;

  @override
  void initState() {
    super.initState();
    _loadTotalSpent();
  }

  Future<void> _loadTotalSpent() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _totalSpent = prefs.getDouble('totalSpent') ?? 0.0;
    });
  }

  Future<void> _saveSpending(double amount, String reason) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Save the spending for the day
    List<String>? dailySpending = prefs.getStringList(today) ?? [];
    dailySpending.add('$amount:$reason');
    await prefs.setStringList(today, dailySpending);

    // Update total spent
    _totalSpent += amount;
    await prefs.setDouble('totalSpent', _totalSpent);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daily Spending Tracker'),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(labelText: 'Amount Spent'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _reasonController,
                decoration: InputDecoration(labelText: 'Reason'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a reason';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    double amount = double.parse(_amountController.text);
                    String reason = _reasonController.text;
                    await _saveSpending(amount, reason);
                    _amountController.clear();
                    _reasonController.clear();
                  }
                },
                child: Text('Add Spending'),
              ),
              SizedBox(height: 20),
              Text('Total Spent: \$${_totalSpent.toStringAsFixed(2)}'),
            ],
          ),
        ),
      ),
    );
  }
}

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _dateController = TextEditingController();
  List<String> _spendingHistory = [];

  Future<void> _loadSpendingHistory(String date) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _spendingHistory = prefs.getStringList(date) ?? [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Spending History'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _dateController,
              decoration: InputDecoration(
                labelText: 'Select Date (yyyy-MM-dd)',
                suffixIcon: IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (pickedDate != null) {
                      String formattedDate =
                          DateFormat('yyyy-MM-dd').format(pickedDate);
                      _dateController.text = formattedDate;
                      _loadSpendingHistory(formattedDate);
                    }
                  },
                ),
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _spendingHistory.length,
                itemBuilder: (context, index) {
                  String entry = _spendingHistory[index];
                  List<String> parts = entry.split(':');
                  double amount = double.parse(parts[0]);
                  String reason = parts[1];
                  return ListTile(
                    title: Text('Amount: \$${amount.toStringAsFixed(2)}'),
                    subtitle: Text('Reason: $reason'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
