import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// --- Simple API client ---
class ApiClient {
  // Use the ngrok URL you provided
  static const String baseUrl = 'https://ff5ae32c379e.ngrok-free.app';

  // timeout for requests
  final Duration _timeout = const Duration(seconds: 10);

  Future<bool> login({String? username, String? email, required String hash}) async {
    final uri = Uri.parse('$baseUrl/login');
    final body = <String, dynamic>{'hash': hash};
    if (username != null && username.isNotEmpty) {
      body['username'] = username;
    } else if (email != null && email.isNotEmpty) {
      body['email'] = email;
    }

    final resp = await http.post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body)).timeout(_timeout);
    return resp.statusCode == 200;
  }

  Future<bool> register({required String username, required String email, required String hash}) async {
    final uri = Uri.parse('$baseUrl/register');
    final body = {'username': username, 'email': email, 'hash': hash};
    final resp = await http.post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body)).timeout(_timeout);
    return resp.statusCode == 201;
  }
}

// --- Theme Management ---

// Manages the app's current theme
// We use a ValueNotifier to allow any widget to listen to theme changes.
class ThemeManager {
  static final ValueNotifier<ThemeMode> themeNotifier =
      ValueNotifier(ThemeMode.dark);
}

// Defines the color palettes for light and dark modes
class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: Colors.indigo,
    colorScheme: ColorScheme.light(
      primary: Colors.indigo,
      secondary: Colors.indigoAccent,
      background: Colors.grey.shade100,
      surface: Colors.white,
      onBackground: Colors.black,
      onSurface: Colors.black,
    ),
    scaffoldBackgroundColor: Colors.grey.shade100,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 1,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      margin: const EdgeInsets.only(bottom: 12.0),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      filled: true,
      fillColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: Colors.indigoAccent,
    // This color scheme is inspired by the "Things 3" dark mode
    colorScheme: ColorScheme.dark(
      primary: Colors.indigoAccent,
      secondary: Colors.indigo,
      background: const Color(0xFF121212), // Very dark background
      surface: const Color(0xFF1E1E1E), // Card/Modal background
      onBackground: Colors.grey.shade200,
      onSurface: Colors.grey.shade200,
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: const Color(0xFF1E1E1E),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        // We'll use the priority color for the border, not a default
      ),
      margin: const EdgeInsets.only(bottom: 12.0),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: Colors.grey.shade800),
      ),
      filled: true,
      fillColor: const Color(0xFF2A2A2A),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
    ),
  );
}

// --- App Entry Point ---

void main() {
  runApp(const TaskManagerApp());
}

class TaskManagerApp extends StatelessWidget {
  const TaskManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ValueListenableBuilder rebuilds the app when the theme changes
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.themeNotifier,
      builder: (_, themeMode, __) {
        return MaterialApp(
          title: 'Task Manager',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          debugShowCheckedModeBanner: false,
          initialRoute: '/login',
          routes: {
            '/login': (context) => const LoginPage(),
            '/register': (context) => const RegisterPage(),
            '/home': (context) => const HomePage(),
          },
        );
      },
    );
  }
}

// --- Authentication Pages ---

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      _performLogin();
    }
  }

  Future<void> _performLogin() async {
    final String username = _usernameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;

    // compute a simple SHA256 hash of the password to send to the server
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes).toString();

    final api = ApiClient();
    try {
      final success = await api.login(username: username.isNotEmpty ? username : null, email: username.isEmpty ? email : null, hash: digest);
      if (success) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid credentials')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),
                  const Icon(Icons.check_circle_outline,
                      size: 80, color: Colors.indigoAccent),
                  const SizedBox(height: 20),
                  Text(
                    'Welcome Back',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Log in to your account',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                  ),
                  const SizedBox(height: 40),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(labelText: 'Username'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your username';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty ||
                          !value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty || value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _login,
                    child: const Text('Login'),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/register');
                    },
                    child: const Text("Don't have an account? Register"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _register() {
    if (_formKey.currentState!.validate()) {
      _performRegister();
    }
  }

  Future<void> _performRegister() async {
    final String username = _usernameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;

    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes).toString();

    final api = ApiClient();
    try {
      final created = await api.register(username: username, email: email, hash: digest);
      if (created) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registered successfully')));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration failed')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Register error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Create Account',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Get started by filling out the form',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                  ),
                  const SizedBox(height: 40),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(labelText: 'Username'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a username';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty ||
                          !value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty || value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _register,
                    child: const Text('Create Account'),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("Already have an account? Login"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- Home Page and Task-Related Widgets ---

// Enum for task priority
enum Priority { high, medium, low }

// Simple class to hold task data
class Task {
  final String id;
  String title;
  bool isDone;
  final Priority priority;
  DateTime dueDate;
  bool isAllDay;
  TimeOfDay? startTime;
  TimeOfDay? endTime;

  Task({
    required this.id,
    required this.title,
    this.isDone = false,
    required this.priority,
    required this.dueDate,
    this.isAllDay = false,
    this.startTime,
    this.endTime,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Get current date, ignoring time
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());

  // Mock data for tasks
  final List<Task> _tasks = [
    Task(
      id: '1',
      title: 'Finish Flutter UI',
      priority: Priority.high,
      dueDate: DateUtils.dateOnly(DateTime.now()),
      isAllDay: false,
      startTime: const TimeOfDay(hour: 14, minute: 0),
      endTime: const TimeOfDay(hour: 16, minute: 0),
    ),
    Task(
        id: '2',
        title: 'Buy groceries',
        priority: Priority.medium,
        dueDate: DateUtils.dateOnly(DateTime.now().add(const Duration(days: 1)))),
    Task(
        id: '3',
        title: 'Go for a run',
        isDone: true,
        priority: Priority.low,
        dueDate: DateUtils.dateOnly(DateTime.now().subtract(const Duration(days: 2)))),
    Task(
      id: '4',
      title: 'Call mom',
      priority: Priority.medium,
      dueDate: DateUtils.dateOnly(DateTime.now()),
      isAllDay: true,
    ),
    Task(
        id: '5',
        title: 'Prepare presentation',
        priority: Priority.high,
        dueDate: DateUtils.dateOnly(DateTime.now().add(const Duration(days: 5)))),
    Task(
        id: '6',
        title: 'Read a book',
        priority: Priority.low,
        dueDate: DateUtils.dateOnly(DateTime.now().add(const Duration(days: 10)))),
  ];

  // --- Task Management Methods ---

  void _showTaskSheet(Task? taskToEdit) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      isScrollControlled: true,
      builder: (ctx) => TaskEditSheet(
        task: taskToEdit,
        // Pass the selected date as the default for new tasks
        defaultDate: _selectedDate,
        onSave: (Task task) {
          setState(() {
            if (taskToEdit == null) {
              // Add new task
              _tasks.add(task);
            } else {
              // Update existing task
              final index =
                  _tasks.indexWhere((t) => t.id == taskToEdit.id);
              if (index != -1) {
                _tasks[index] = task;
              }
            }
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _toggleTaskStatus(Task task) {
    setState(() {
      task.isDone = !task.isDone;
    });
  }

  // Helper to sort tasks by priority
  int _compareTasksByPriority(Task a, Task b) {
    return a.priority.index.compareTo(b.priority.index);
  }

  String _formatAppBarTitle(DateTime date) {
    final DateTime now = DateUtils.dateOnly(DateTime.now());
    if (date == now) return 'Today';
    if (date == now.add(const Duration(days: 1))) return 'Tomorrow';
    if (date == now.subtract(const Duration(days: 1))) return 'Yesterday';
    // Simple format for other dates
    return "${date.month}/${date.day}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    // Filter and sort tasks for the selected day
    final List<Task> tasksForSelectedDay = _tasks
        .where((task) => DateUtils.isSameDay(task.dueDate, _selectedDate))
        .toList();
    tasksForSelectedDay.sort(_compareTasksByPriority);

    return Scaffold(
      appBar: AppBar(
        title: Text(_formatAppBarTitle(_selectedDate)),
        actions: [
          // --- Theme Toggle Button ---
          ValueListenableBuilder(
            valueListenable: ThemeManager.themeNotifier,
            builder: (_, themeMode, __) {
              return IconButton(
                icon: Icon(themeMode == ThemeMode.light
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined),
                onPressed: () {
                  ThemeManager.themeNotifier.value =
                      themeMode == ThemeMode.light
                          ? ThemeMode.dark
                          : ThemeMode.light;
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: () {
              // Log out and return to login screen
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      // --- Navigation Drawer ---
      drawer: AppDrawer(),
      body: Column(
        children: [
          // --- Horizontal Date Picker ---
          HorizontalDatePicker(
            selectedDate: _selectedDate,
            onDateSelected: (newDate) {
              setState(() {
                _selectedDate = newDate;
              });
            },
          ),
          // --- Task List ---
          Expanded(
            child: tasksForSelectedDay.isEmpty
                ? const Center(
                    child: Text("No tasks for this day."),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: tasksForSelectedDay.length,
                    itemBuilder: (context, index) {
                      final task = tasksForSelectedDay[index];
                      return TaskCard(
                        task: task,
                        onToggle: () => _toggleTaskStatus(task),
                        onTap: () => _showTaskSheet(task), // Open edit sheet
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTaskSheet(null), // Open sheet for new task
        tooltip: 'Add Task',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// --- Horizontal Date Picker Widget ---
class HorizontalDatePicker extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;

  const HorizontalDatePicker({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  String _formatDateHeader(DateTime date) {
    final DateTime now = DateUtils.dateOnly(DateTime.now());
    if (DateUtils.isSameDay(date, now)) return 'Today';
    // Use 3-letter day abbreviation
    return "${['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1]}";
  }

  @override
  Widget build(BuildContext context) {
    // Show 14 days: 7 past, 1 today, 6 future
    final DateTime firstDate =
        DateUtils.dateOnly(DateTime.now()).subtract(const Duration(days: 7));

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).appBarTheme.backgroundColor,
        border: Border(
            bottom: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1)),
      ),
      child: ListView.builder(
        // We'll show 14 days total
        itemCount: 14,
        // Start the list at the first date
        controller:
            ScrollController(initialScrollOffset: 80.0 * 7), // Start near "Today"
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final DateTime date = firstDate.add(Duration(days: index));
          final bool isSelected = DateUtils.isSameDay(date, selectedDate);
          final bool isToday =
              DateUtils.isSameDay(date, DateUtils.dateOnly(DateTime.now()));

          return GestureDetector(
            onTap: () => onDateSelected(date),
            child: Container(
              width: 70, // Width for each date item
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _formatDateHeader(date), // e.g., "Mon", "Today"
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? Colors.white
                          : (isToday
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).colorScheme.onSurface),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date.day.toString(), // e.g., "12"
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : (isToday
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).colorScheme.onSurface),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// --- Navigation Drawer (Simplified) ---
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Text(
              'Task Manager',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(color: Colors.white),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () {
              // TODO: Navigate to settings page
              Navigator.pop(context);
            },
          ),
          // Add more items here like "Projects", "Tags" etc.
        ],
      ),
    );
  }
}

// A reusable card widget to display a single task
class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onTap; // For editing

  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onTap,
  });

  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.high:
        return Colors.redAccent;
      case Priority.medium:
        return Colors.orangeAccent;
      case Priority.low:
        return Colors.greenAccent;
    }
  }

  String _formatTime(BuildContext context) {
    if (task.isAllDay) return 'All Day';
    if (task.startTime != null) {
      final String start = task.startTime!.format(context);
      if (task.endTime != null) {
        final String end = task.endTime!.format(context);
        return '$start - $end';
      }
      return start;
    }
    return ''; // No time specified
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = _getPriorityColor(task.priority);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Use a faint border color in light mode, or the priority color in dark mode
    final Color borderColor = isDark ? priorityColor : Colors.grey.shade300;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color: borderColor,
          width: 1.5,
        ),
      ),
      child: ListTile(
        onTap: onTap, // <-- onTap now on the ListTile
        leading: Checkbox(
          value: task.isDone,
          onChanged: (bool? value) {
            onToggle(); // <-- onChanged now on the Checkbox
          },
          activeColor: priorityColor,
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isDone ? TextDecoration.lineThrough : null,
            color: task.isDone
                ? Colors.grey
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          _formatTime(context),
          style: TextStyle(
            color: task.isDone
                ? Colors.grey
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ),
    );
  }
}

// A modal sheet for ADDING or EDITING a task
class TaskEditSheet extends StatefulWidget {
  final Task? task; // If task is null, it's a new task
  final DateTime defaultDate;
  final Function(Task) onSave;

  const TaskEditSheet({
    super.key,
    this.task,
    required this.defaultDate,
    required this.onSave,
  });

  @override
  State<TaskEditSheet> createState() => _TaskEditSheetState();
}

class _TaskEditSheetState extends State<TaskEditSheet> {
  final _titleController = TextEditingController();
  Priority _selectedPriority = Priority.medium;
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  bool _isAllDay = false;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      // Editing existing task
      _titleController.text = widget.task!.title;
      _selectedPriority = widget.task!.priority;
      _selectedDate = widget.task!.dueDate;
      _isAllDay = widget.task!.isAllDay;
      _startTime = widget.task!.startTime;
      _endTime = widget.task!.endTime;
    } else {
      // Creating new task
      _selectedDate = widget.defaultDate;
    }
  }

  void _submit() {
    if (_titleController.text.isEmpty) {
      return; // Don't add empty tasks
    }
    final String id = widget.task?.id ?? DateTime.now().toString();

    widget.onSave(
      Task(
        id: id,
        title: _titleController.text,
        priority: _selectedPriority,
        dueDate: _selectedDate,
        isAllDay: _isAllDay,
        startTime: _isAllDay ? null : _startTime,
        endTime: _isAllDay ? null : _endTime,
        isDone: widget.task?.isDone ?? false,
      ),
    );
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = DateUtils.dateOnly(picked);
      });
    }
  }

  Future<void> _pickTime(bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime
          ? (_startTime ?? TimeOfDay.now())
          : (_endTime ?? _startTime ?? TimeOfDay.now()),
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
          // Optional: Auto-set end time if it's before start time
          if (_endTime != null &&
              (_endTime!.hour < picked.hour ||
                  (_endTime!.hour == picked.hour &&
                      _endTime!.minute < picked.minute))) {
            _endTime =
                TimeOfDay(hour: picked.hour + 1, minute: picked.minute);
          }
        } else {
          _endTime = picked;
        }
      });
    }
  }

  String _formatDate(DateTime date) {
    final DateTime now = DateUtils.dateOnly(DateTime.now());
    if (date == now) return 'Today';
    if (date == now.add(const Duration(days: 1))) return 'Tomorrow';
    return "${date.month}/${date.day}/${date.year}";
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return 'Select';
    return time.format(context);
  }

  @override
  Widget build(BuildContext context) {
    // Use padding to avoid keyboard overlap
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.task == null ? 'Add New Task' : 'Edit Task',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Task Title'),
            autofocus: true,
          ),
          const SizedBox(height: 20),
          Text('Select Priority', style: Theme.of(context).textTheme.bodyLarge),
          DropdownButton<Priority>(
            value: _selectedPriority,
            onChanged: (Priority? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedPriority = newValue;
                });
              }
            },
            items: Priority.values
                .map((priority) => DropdownMenuItem(
                      value: priority,
                      child: Text(priority.name.substring(0, 1).toUpperCase() +
                          priority.name.substring(1)),
                    ))
                .toList(),
            isExpanded: true,
          ),
          const SizedBox(height: 10),
          // --- Date Picker Button ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Due Date', style: Theme.of(context).textTheme.bodyLarge),
              TextButton(
                onPressed: _pickDate,
                child: Text(_formatDate(_selectedDate)),
              ),
            ],
          ),
          // --- All Day Switch ---
          SwitchListTile(
            title: const Text('All Day'),
            value: _isAllDay,
            onChanged: (bool value) {
              setState(() {
                _isAllDay = value;
              });
            },
          ),
          // --- Time Pickers (if not all day) ---
          if (!_isAllDay)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Start Time',
                    style: Theme.of(context).textTheme.bodyLarge),
                TextButton(
                  onPressed: () => _pickTime(true),
                  child: Text(_formatTime(_startTime)),
                ),
                Text('End Time',
                    style: Theme.of(context).textTheme.bodyLarge),
                TextButton(
                  onPressed: () => _pickTime(false),
                  child: Text(_formatTime(_endTime)),
                ),
              ],
            ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _submit,
            child: Text(widget.task == null ? 'Add Task' : 'Update Task'),
          ),
        ],
      ),
    );
  }
}