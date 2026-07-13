import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

void main() {
  runApp(const MyApp());
}

// STATIC — app-wide settings, written once, never changes
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // STATIC: app-wide theme — colors, fonts, and card styling applied everywhere
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3F51B5)),
        scaffoldBackgroundColor: const Color(0xFFF5F6FA),
        appBarTheme: const AppBarTheme(elevation: 0, centerTitle: false),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

// STATIC — the screen shell, not the brain
// Its ONLY job is to point to _HomeScreenState
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// STATIC — a small reusable widget, used 3 times in the stats card
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

class _HomeScreenState extends State<HomeScreen> {
  // LOGIC: the in-memory list — always kept in sync with the database
  List<Map<String, dynamic>> _goals = [];

  // LOGIC: holds the open database connection once it's ready
  Database? _db;

  // LOGIC: getters — recalculated fresh every single time they're read
  int get _totalGoals => _goals.length;
  int get _totalHours =>
      _goals.fold<int>(0, (sum, goal) => sum + (goal['hours'] as int));
  int get _doneCount => _goals.where((goal) => goal['done'] == true).length;

  @override
  void initState() {
    // Run Flutter's default setup first, then start loading our own data
    super.initState();
    // LOGIC: as soon as this screen is created, open the DB and load goals
    _initDatabase();
  }

  // LOGIC: opens (or creates) the database file and the goals table
  Future<void> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'study_planner.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute('''
          CREATE TABLE goals(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            subject TEXT NOT NULL,
            hours INTEGER NOT NULL,
            done INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );
    await _loadGoals();
  }

  // LOGIC: reads every row from the goals table into _goals
  Future<void> _loadGoals() async {
    final rows = await _db!.query('goals');
    setState(() {
      _goals = rows.map((row) {
        return {
          'id': row['id'],
          'subject': row['subject'],
          'hours': row['hours'],
          'done': row['done'] == 1, // SQLite stores bool as 0/1
        };
      }).toList();
    });
  }

  // LOGIC: flips one goal's done status in the DB, then in _goals, then redraws
  Future<void> _toggleDone(int index) async {
    final goal = _goals[index];
    final newDone = !(goal['done'] as bool);

    await _db!.update(
      'goals',
      {'done': newDone ? 1 : 0},
      where: 'id = ?',
      whereArgs: [goal['id']],
    );
    setState(() {
      _goals[index]['done'] = newDone;
    });
  }

  // LOGIC: removes one goal, then triggers a redraw
  Future<void> _deleteGoal(int index) async {
    final goal = _goals[index];

    await _db!.delete('goals', where: 'id = ?', whereArgs: [goal['id']]);
    setState(() {
      _goals.removeAt(index);
    });
  }

  // LOGIC: opens the Add Goal screen and waits for it to send data back
  Future<void> _openAddGoalScreen() async {
    final newGoal = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddGoalScreen()),
    );
    if (newGoal != null) {
      final id = await _db!.insert('goals', {
        'subject': newGoal['subject'],
        'hours': newGoal['hours'],
        'done': 0,
      });
      setState(() {
        _goals.add({
          'id': id,
          'subject': newGoal['subject'],
          'hours': newGoal['hours'],
          'done': false,
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Study Planner',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        // LOGIC: live progress summary, reads the getters directly
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_doneCount / $_totalGoals done',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // STATIC layout, LOGIC values — reused widget x3, reads getters
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    StatCard(
                      label: 'Goals',
                      value: '$_totalGoals',
                      icon: Icons.flag_outlined,
                      color: Colors.indigo,
                    ),
                    StatCard(
                      label: 'Hours',
                      value: '$_totalHours',
                      icon: Icons.schedule,
                      color: Colors.orange,
                    ),
                    StatCard(
                      label: 'Done',
                      value: '$_doneCount',
                      icon: Icons.check_circle_outline,
                      color: Colors.green,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // CONNECTION POINT 1: reading _goals to decide what to show
          Expanded(
            child: _goals.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.checklist_rtl,
                          size: 56,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No goals yet — add one!',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
                    itemCount: _goals.length,
                    itemBuilder: (context, index) {
                      final goal = _goals[index];
                      final bool done = goal['done'];

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        color: done ? Colors.grey.shade100 : Colors.white,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          leading: Icon(
                            done
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: done ? Colors.green : Colors.grey.shade400,
                          ),
                          title: Text(
                            goal['subject'],
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              decoration: done
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              color: done ? Colors.grey : Colors.black87,
                            ),
                          ),
                          subtitle: Text(
                            '${goal['hours']} hours',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // CONNECTION POINT 2: button press calls logic function
                              IconButton(
                                onPressed: () => _toggleDone(index),
                                icon: const Icon(Icons.check),
                                color: Colors.green,
                                tooltip: 'Mark done',
                              ),
                              IconButton(
                                onPressed: () => _deleteGoal(index),
                                icon: const Icon(Icons.delete_outline),
                                color: Colors.redAccent,
                                tooltip: 'Delete',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        // CONNECTION POINT 2: button press calls logic function
        onPressed: _openAddGoalScreen,
        icon: const Icon(Icons.add),
        label: const Text('Add Goal'),
      ),
    );
  }
}

// STATIC — the screen shell for adding a goal
class AddGoalScreen extends StatefulWidget {
  const AddGoalScreen({super.key});

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  // LOGIC: controllers read whatever the user types into each field
  final _subjectController = TextEditingController();
  final _hoursController = TextEditingController();

  // LOGIC: holds an error message to show, or null if there's no error
  String? _errorMessage;

  // LOGIC: validates input, and if valid, closes the screen with the new goal
  void _saveGoal() {
    final subject = _subjectController.text.trim();
    final hoursText = _hoursController.text.trim();
    final hours = int.tryParse(hoursText);

    if (subject.isEmpty) {
      setState(() => _errorMessage = 'Subject name cannot be empty.');
      return;
    }
    if (hours == null || hours <= 0) {
      setState(
        () => _errorMessage = 'Hours must be a number greater than zero.',
      );
      return;
    }

    Navigator.pop(context, {'subject': subject, 'hours': hours, 'done': false});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Goal',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: 'Subject',
                prefixIcon: Icon(Icons.book_outlined),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _hoursController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Hours planned',
                prefixIcon: Icon(Icons.schedule),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),

            // LOGIC: only shows if there's an error to display
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _saveGoal,
              child: const Text(
                'Save',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
