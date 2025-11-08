import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// --- Simple API client ---
class ApiClient {
  static const String baseUrl = 'https://ff5ae32c379e.ngrok-free.app';
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
class ThemeManager {
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);
}

// Defines the color palettes for light and dark modes
class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: const Color(0xFF5E81F4),
    colorScheme: ColorScheme.light(
      primary: const Color(0xFF5E81F4),
      secondary: const Color(0xFF7B68EE),
      background: const Color(0xFFF5F7FA),
      surface: Colors.white,
      onBackground: const Color(0xFF1A1A1A),
      onSurface: const Color(0xFF1A1A1A),
    ),
    scaffoldBackgroundColor: const Color(0xFFF5F7FA),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF1A1A1A),
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      margin: const EdgeInsets.only(bottom: 12.0),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: const BorderSide(color: Color(0xFF5E81F4), width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF5E81F4),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        elevation: 0,
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF7B68EE),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF7B68EE),
      secondary: Color(0xFF9D8FF7),
      background: Color(0xFF0D0D0D),
      surface: Color(0xFF1A1A1A),
      onBackground: Color(0xFFE8E8E8),
      onSurface: Color(0xFFE8E8E8),
    ),
    scaffoldBackgroundColor: const Color(0xFF0D0D0D),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1A1A1A),
      foregroundColor: Color(0xFFE8E8E8),
      elevation: 0,
      centerTitle: false,
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: Color(0xFF1A1A1A),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      margin: const EdgeInsets.only(bottom: 12.0),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.0),
        borderSide: const BorderSide(color: Color(0xFF7B68EE), width: 2),
      ),
      filled: true,
      fillColor: const Color(0xFF1F1F1F),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF7B68EE),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        elevation: 0,
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

    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes).toString();

    final api = ApiClient();
    try {
      final success = await api.login(
        username: username.isNotEmpty ? username : null,
        email: username.isEmpty ? email : null,
        hash: digest,
      );
      if (success) {
        if (mounted) Navigator.pushReplacementNamed(context, '/home');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid credentials')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.task_alt_rounded,
                      size: 80,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Welcome Back',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to continue',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: 48),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your username';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty || !value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          ),
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
                      child: const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/register');
                      },
                      child: Text(
                        "Don't have an account? Sign Up",
                        style: TextStyle(color: Theme.of(context).primaryColor),
                      ),
                    ),
                  ],
                ),
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
      if (mounted) {
        if (created) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registered successfully')),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration failed')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Register error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Create Account',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign up to get started',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: 40),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a username';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty || !value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          ),
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
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                          ),
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
                      child: const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Already have an account? Sign In',
                        style: TextStyle(color: Theme.of(context).primaryColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- Enums and Models ---
enum Priority { high, medium, low }

class Task {
  final String id;
  String title;
  bool isDone;
  Priority priority;
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
    this.isAllDay = true,
    this.startTime,
    this.endTime,
  });
}

// --- Home Page ---
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  final ScrollController _dateScrollController = ScrollController();

  final List<Task> _tasks = [
    Task(
      id: '1',
      title: 'Team Meeting',
      priority: Priority.high,
      dueDate: DateUtils.dateOnly(DateTime.now()),
      isAllDay: false,
      startTime: const TimeOfDay(hour: 10, minute: 0),
      endTime: const TimeOfDay(hour: 11, minute: 0),
    ),
    Task(
      id: '2',
      title: 'Complete Project Report',
      priority: Priority.high,
      dueDate: DateUtils.dateOnly(DateTime.now()),
      isAllDay: false,
      startTime: const TimeOfDay(hour: 14, minute: 0),
      endTime: const TimeOfDay(hour: 16, minute: 0),
    ),
    Task(
      id: '3',
      title: 'Gym Workout',
      priority: Priority.medium,
      dueDate: DateUtils.dateOnly(DateTime.now()),
      isAllDay: false,
      startTime: const TimeOfDay(hour: 18, minute: 0),
      endTime: const TimeOfDay(hour: 19, minute: 30),
    ),
    Task(
      id: '4',
      title: 'Buy Groceries',
      priority: Priority.low,
      dueDate: DateUtils.dateOnly(DateTime.now()),
      isAllDay: true,
    ),
    Task(
      id: '5',
      title: 'Doctor Appointment',
      priority: Priority.high,
      dueDate: DateUtils.dateOnly(DateTime.now().add(const Duration(days: 1))),
      isAllDay: false,
      startTime: const TimeOfDay(hour: 15, minute: 30),
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedDate();
    });
  }

  @override
  void dispose() {
    _dateScrollController.dispose();
    super.dispose();
  }

  void _scrollToSelectedDate() {
    const itemWidth = 70.0;
    final now = DateUtils.dateOnly(DateTime.now());
    final daysDifference = _selectedDate.difference(now).inDays;
    final targetOffset = (daysDifference + 7) * itemWidth - (MediaQuery.of(context).size.width / 2) + (itemWidth / 2);
    
    if (_dateScrollController.hasClients) {
      _dateScrollController.animateTo(
        targetOffset.clamp(0.0, _dateScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showTaskSheet(Task? taskToEdit) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => TaskEditSheet(
        task: taskToEdit,
        defaultDate: _selectedDate,
        onSave: (Task task) {
          setState(() {
            if (taskToEdit == null) {
              _tasks.add(task);
            } else {
              final index = _tasks.indexWhere((t) => t.id == taskToEdit.id);
              if (index != -1) {
                _tasks[index] = task;
              }
            }
          });
          Navigator.pop(context);
        },
        onDelete: taskToEdit != null ? () {
          setState(() {
            _tasks.removeWhere((t) => t.id == taskToEdit.id);
          });
          Navigator.pop(context);
        } : null,
      ),
    );
  }

  void _toggleTaskStatus(Task task) {
    setState(() {
      task.isDone = !task.isDone;
    });
  }

  int _compareTasksByPriority(Task a, Task b) {
    if (a.priority.index != b.priority.index) {
      return a.priority.index.compareTo(b.priority.index);
    }
    if (a.isAllDay && !b.isAllDay) return 1;
    if (!a.isAllDay && b.isAllDay) return -1;
    if (a.startTime != null && b.startTime != null) {
      final aMinutes = a.startTime!.hour * 60 + a.startTime!.minute;
      final bMinutes = b.startTime!.hour * 60 + b.startTime!.minute;
      return aMinutes.compareTo(bMinutes);
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final tasksForSelectedDay = _tasks
        .where((task) => DateUtils.isSameDay(task.dueDate, _selectedDate))
        .toList()
      ..sort(_compareTasksByPriority);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Forecast',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        actions: [
          ValueListenableBuilder(
            valueListenable: ThemeManager.themeNotifier,
            builder: (_, themeMode, __) {
              return IconButton(
                icon: Icon(
                  themeMode == ThemeMode.light ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  size: 24,
                ),
                onPressed: () {
                  ThemeManager.themeNotifier.value =
                      themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
                },
                tooltip: 'Toggle theme',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 24),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
            tooltip: 'Logout',
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          HorizontalDatePicker(
            selectedDate: _selectedDate,
            scrollController: _dateScrollController,
            onDateSelected: (newDate) {
              setState(() {
                _selectedDate = newDate;
              });
              _scrollToSelectedDate();
            },
          ),
          Expanded(
            child: tasksForSelectedDay.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_available_rounded,
                          size: 80,
                          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No tasks for this day',
                          style: TextStyle(
                            fontSize: 18,
                            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20.0),
                    itemCount: tasksForSelectedDay.length,
                    itemBuilder: (context, index) {
                      final task = tasksForSelectedDay[index];
                      return TaskCard(
                        task: task,
                        onToggle: () => _toggleTaskStatus(task),
                        onTap: () => _showTaskSheet(task),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTaskSheet(null),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Task'),
        elevation: 2,
      ),
    );
  }
}

// --- Horizontal Date Picker ---
class HorizontalDatePicker extends StatelessWidget {
  final DateTime selectedDate;
  final ScrollController scrollController;
  final Function(DateTime) onDateSelected;

  const HorizontalDatePicker({
    super.key,
    required this.selectedDate,
    required this.scrollController,
    required this.onDateSelected,
  });

  String _formatDay(DateTime date) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final now = DateUtils.dateOnly(DateTime.now());
    final firstDate = now.subtract(const Duration(days: 7));

    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Theme.of(context).appBarTheme.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        itemCount: 30,
        itemBuilder: (context, index) {
          final date = firstDate.add(Duration(days: index));
          final isSelected = DateUtils.isSameDay(date, selectedDate);
          final isToday = DateUtils.isSameDay(date, now);

          return GestureDetector(
            onTap: () => onDateSelected(date),
            child: Container(
              width: 70,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withOpacity(0.8),
                        ],
                      )
                    : null,
                color: isSelected ? null : (isToday ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.transparent),
                borderRadius: BorderRadius.circular(20),
                border: isToday && !isSelected
                    ? Border.all(color: Theme.of(context).primaryColor, width: 2)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _formatDay(date),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : (isToday
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : (isToday
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).colorScheme.onSurface),
                    ),
                  ),
                  if (isToday && !isSelected) ...[
                    const SizedBox(height: 4),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// --- App Drawer ---
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
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.task_alt_rounded,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Task Manager',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today_rounded),
            title: const Text('My Tasks'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_rounded),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

// --- Task Card ---
class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onTap,
  });

  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.high:
        return const Color(0xFFFF6B6B);
      case Priority.medium:
        return const Color(0xFFFFB347);
      case Priority.low:
        return const Color(0xFF4ECDC4);
    }
  }

  String _formatTime(BuildContext context) {
    if (task.isAllDay) return 'All Day';
    if (task.startTime != null) {
      final start = task.startTime!.format(context);
      if (task.endTime != null) {
        final end = task.endTime!.format(context);
        return '$start - $end';
      }
      return start;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = _getPriorityColor(task.priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onToggle,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: task.isDone ? priorityColor : priorityColor.withOpacity(0.5),
                        width: 2.5,
                      ),
                      color: task.isDone ? priorityColor : Colors.transparent,
                    ),
                    child: task.isDone
                        ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: task.isDone
                              ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5)
                              : Theme.of(context).colorScheme.onSurface,
                          decoration: task.isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (!task.isAllDay || task.startTime != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatTime(context),
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    task.priority.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: priorityColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- Task Edit Sheet ---
class TaskEditSheet extends StatefulWidget {
  final Task? task;
  final DateTime defaultDate;
  final Function(Task) onSave;
  final VoidCallback? onDelete;

  const TaskEditSheet({
    super.key,
    this.task,
    required this.defaultDate,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<TaskEditSheet> createState() => _TaskEditSheetState();
}

class _TaskEditSheetState extends State<TaskEditSheet> {
  final _titleController = TextEditingController();
  Priority _selectedPriority = Priority.medium;
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  bool _isAllDay = true;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _selectedPriority = widget.task!.priority;
      _selectedDate = widget.task!.dueDate;
      _isAllDay = widget.task!.isAllDay;
      _startTime = widget.task!.startTime;
      _endTime = widget.task!.endTime;
    } else {
      _selectedDate = widget.defaultDate;
    }
  }

  void _submit() {
    if (_titleController.text.isEmpty) return;

    final String id = widget.task?.id ?? DateTime.now().millisecondsSinceEpoch.toString();

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
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateUtils.dateOnly(picked);
      });
    }
  }

  Future<void> _pickTime(bool isStartTime) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStartTime
          ? (_startTime ?? TimeOfDay.now())
          : (_endTime ?? _startTime ?? TimeOfDay.now()),
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.high:
        return const Color(0xFFFF6B6B);
      case Priority.medium:
        return const Color(0xFFFFB347);
      case Priority.low:
        return const Color(0xFF4ECDC4);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.task == null ? 'New Task' : 'Edit Task',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                if (widget.onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                    onPressed: widget.onDelete,
                  ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Task Title',
                prefixIcon: Icon(Icons.edit_outlined),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 24),
            const Text('Priority', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              children: Priority.values.map((priority) {
                final isSelected = priority == _selectedPriority;
                final color = _getPriorityColor(priority);

                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedPriority = priority),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? color : Theme.of(context).dividerColor,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        priority.name.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? color : Theme.of(context).colorScheme.onSurface,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: ListTile(
                leading: const Icon(Icons.calendar_today_rounded),
                title: const Text('Due Date'),
                trailing: TextButton(
                  onPressed: _pickDate,
                  child: Text(
                    _selectedDate == DateUtils.dateOnly(DateTime.now())
                        ? 'Today'
                        : '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: SwitchListTile(
                title: const Text('All Day'),
                value: _isAllDay,
                onChanged: (value) => setState(() => _isAllDay = value),
                secondary: const Icon(Icons.wb_sunny_rounded),
              ),
            ),
            if (!_isAllDay) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.access_time_rounded),
                        title: const Text('Start'),
                        trailing: TextButton(
                          onPressed: () => _pickTime(true),
                          child: Text(_startTime?.format(context) ?? 'Select'),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.access_time_filled_rounded),
                        title: const Text('End'),
                        trailing: TextButton(
                          onPressed: () => _pickTime(false),
                          child: Text(_endTime?.format(context) ?? 'Select'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
              child: Text(
                widget.task == null ? 'Create Task' : 'Update Task',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}