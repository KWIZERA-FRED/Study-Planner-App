import 'package:flutter/material.dart';
import 'api_service.dart';

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
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// STATIC — small reusable widget, used 3 times in the stats card
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
  List<Map<String, dynamic>> _goals = [];
  bool _isLoading = true;
  String? _loadError;

  int get _totalGoals => _goals.length;
  int get _totalHours =>
      _goals.fold<int>(0, (sum, goal) => sum + (goal['hours'] as int));
  int get _doneCount => _goals.where((goal) => goal['done'] == true).length;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final goals = await ApiService.fetchGoals();
      setState(() {
        _goals = goals;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _loadError = 'Could not reach the server. Is the backend running?';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleDone(int index) async {
    final goal = _goals[index];
    final newDone = !(goal['done'] as bool);

    try {
      await ApiService.updateGoal(goal['id'] as int, done: newDone);
      setState(() {
        _goals[index]['done'] = newDone;
      });
    } catch (e) {
      _showError('Could not update the goal. Check your connection.');
    }
  }

  Future<void> _deleteGoal(int index) async {
    final goal = _goals[index];

    try {
      await ApiService.deleteGoal(goal['id'] as int);
      setState(() {
        _goals.removeAt(index);
      });
    } catch (e) {
      _showError('Could not delete the goal. Check your connection.');
    }
  }

  Future<void> _openAddGoalScreen() async {
    final newGoal = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddGoalScreen()),
    );
    if (newGoal != null) {
      try {
        final created = await ApiService.createGoal(
          newGoal['subject'] as String,
          newGoal['hours'] as int,
        );
        setState(() {
          _goals.add(created);
        });
      } catch (e) {
        _showError('Could not save the goal. Check your connection.');
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
                  color: Colors.white.withValues(alpha: 0.2),
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
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _loadError != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.cloud_off,
                          size: 56,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _loadError!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadGoals,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _goals.isEmpty
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
                : RefreshIndicator(
                    onRefresh: _loadGoals,
                    child: ListView.builder(
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
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
  final _subjectController = TextEditingController();
  final _hoursController = TextEditingController();
  String? _errorMessage;

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
