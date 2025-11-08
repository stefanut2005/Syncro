import 'dart:convert';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// --- Simple API client ---
class ApiClient {
  static const String baseUrl = 'https://ff5ae32c379e.ngrok-free.app';
  final Duration _timeout = const Duration(seconds: 10);

  Future<bool> login({String? username, String? email, required String hash}) async {
    final uri = Uri.parse('$baseUrl/login');
    // --- MODIFIED: Changed body back to Map<String, dynamic> ---
    final body = <String, dynamic>{'hash': hash};
    if (username != null && username.isNotEmpty) {
      body['username'] = username;
    } else if (email != null && email.isNotEmpty) {
      body['email'] = email;
    }
    
    // --- MODIFIED: Using http.Request with 'POST' method explicitly ---
    final request = http.Request('POST', uri);
    // --- MODIFIED: Change Content-Type back to application/json ---
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode(body);
    // --- END MODIFICATION ---
    
    final streamedResponse = await request.send().timeout(_timeout);
    final resp = await http.Response.fromStream(streamedResponse);
    // --- END MODIFICATION ---

    return resp.statusCode == 200;
  }

  Future<bool> register({required String username, required String email, required String hash}) async {
    final uri = Uri.parse('$baseUrl/register');
    final body = {'username': username, 'email': email, 'hash': hash};

    // --- MODIFIED: Using http.Request with 'POST' method explicitly ---
    final request = http.Request('POST', uri);
    // --- MODIFIED: Change Content-Type back to application/json ---
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode(body);
    // --- END MODIFICATION ---
    
    final streamedResponse = await request.send().timeout(_timeout);
    final resp = await http.Response.fromStream(streamedResponse);
    // --- END MODIFICATION ---
    
    return resp.statusCode == 201;
  }
}

// --- Theme Management ---
class AppThemes {
  static const defaultBlue = 'defaultBlue';
  static const purple = 'purple';
  static const green = 'green';
  static const orange = 'orange';
  static const pink = 'pink';
  static const teal = 'teal';

  static final Map<String, Map<String, Color>> themes = {
    defaultBlue: {
      'primary': const Color(0xFF5E81F4),
      'secondary': const Color(0xFF7B68EE),
      'accent': const Color(0xFF4169E1),
    },
    purple: {
      'primary': const Color(0xFF9D8FF7),
      'secondary': const Color(0xFFB8A4F5),
      'accent': const Color(0xFF7B68EE),
    },
    green: {
      'primary': const Color(0xFF4CAF50),
      'secondary': const Color(0xFF66BB6A),
      'accent': const Color(0xFF388E3C),
    },
    orange: {
      'primary': const Color(0xFFFF9800),
      'secondary': const Color(0xFFFFB74D),
      'accent': const Color(0xFFF57C00),
    },
    pink: {
      'primary': const Color(0xFFE91E63),
      'secondary': const Color(0xFFF06292),
      'accent': const Color(0xFFC2185B),
    },
    teal: {
      'primary': const Color(0xFF009688),
      'secondary': const Color(0xFF4DB6AC),
      'accent': const Color(0xFF00796B),
    },
  };
}

class ThemeManager {
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);
  static final ValueNotifier<String> colorThemeNotifier = ValueNotifier(AppThemes.defaultBlue);
}

class AppTheme {
  static ThemeData getLightTheme(String colorTheme) {
    final colors = AppThemes.themes[colorTheme]!;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: colors['primary'],
      colorScheme: ColorScheme.light(
        primary: colors['primary']!,
        secondary: colors['secondary']!,
        background: const Color(0xFFF5F7FA), // Very light grey background
        surface: Colors.white, // White surfaces
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
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
          borderSide: BorderSide(color: colors['primary']!, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors['primary'],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          elevation: 0,
        ),
      ),
    );
  }

  static ThemeData getDarkTheme(String colorTheme) {
    final colors = AppThemes.themes[colorTheme]!;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: colors['primary'],
      colorScheme: ColorScheme.dark(
        primary: colors['primary']!,
        secondary: colors['secondary']!,
        background: const Color(0xFF0D0D0D), // Darker background
        surface: const Color(0xFF1A1A1A), // Dark surface
        onBackground: const Color(0xFFE8E8E8),
        onSurface: const Color(0xFFE8E8E8),
      ),
      scaffoldBackgroundColor: const Color(0xFF0D0D0D),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1A1A1A),
        foregroundColor: Color(0xFFE8E8E8),
        elevation: 0,
        centerTitle: false,
      ),
      drawerTheme: const DrawerThemeData(backgroundColor: Color(0xFF1A1A1A)),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
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
          borderSide: BorderSide(color: colors['primary']!, width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFF1F1F1F),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors['primary'],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          elevation: 0,
        ),
      ),
    );
  }
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
        return ValueListenableBuilder<String>(
          valueListenable: ThemeManager.colorThemeNotifier,
          builder: (_, colorTheme, __) {
            return MaterialApp(
              title: 'Task Manager',
              theme: AppTheme.getLightTheme(colorTheme),
              darkTheme: AppTheme.getDarkTheme(colorTheme),
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
      },
    );
  }
}

// --- User Data ---
class UserData {
  static String username = 'User';
  static String email = 'user@example.com';
}

// --- Authentication Pages ---
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  // --- MODIFIED: Single controller for username or email ---
  final _credentialController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _credentialController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      _performLogin();
    }
  }

  Future<void> _performLogin() async {
    // --- MODIFIED: Logic to handle single credential field ---
    final String credential = _credentialController.text.trim();
    final String password = _passwordController.text;
    final bool isEmail = credential.contains('@');

    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes).toString();

    final api = ApiClient();
    try {
      final success = await api.login(
        username: isEmail ? null : credential,
        email: isEmail ? credential : null,
        hash: digest,
      );
      if (success) {
        // Update UserData based on what was provided
        if (isEmail) {
          UserData.email = credential;
        } else {
          UserData.username = credential;
        }
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
                    Icon(Icons.task_alt_rounded, size: 80, color: Theme.of(context).primaryColor),
                    const SizedBox(height: 24),
                    Text('Welcome Back', textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Sign in to continue', textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color)),
                    const SizedBox(height: 48),
                    // --- MODIFIED: Single TextFormField for Username or Email ---
                    TextFormField(
                      controller: _credentialController,
                      decoration: const InputDecoration(labelText: 'Username or Email', prefixIcon: Icon(Icons.person_outline_rounded)),
                      validator: (value) => (value == null || value.isEmpty) ? 'Please enter your username or email' : null,
                    ),
                    const SizedBox(height: 20),
                    // --- END MODIFICATION ---
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (value) => (value == null || value.isEmpty || value.length < 6)
                          ? 'Password must be at least 6 characters' : null,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(onPressed: _login,
                        child: const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/register'),
                      child: Text("Don't have an account? Sign Up",
                          style: TextStyle(color: Theme.of(context).primaryColor)),
                    ),
                    // --- ADDED: Forgot Password Button ---
                    TextButton(
                      onPressed: () {
                        // TODO: Implement forgot password logic
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Forgot Password flow not implemented.')),
                        );
                      },
                      child: Text("Forgot Password?",
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                    ),
                    // --- END ADDITION ---
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
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
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
                    Text('Create Account', textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Sign up to get started', textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color)),
                    const SizedBox(height: 40),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.person_outline)),
                      validator: (value) => (value == null || value.isEmpty) ? 'Please enter a username' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) => (value == null || value.isEmpty || !value.contains('@'))
                          ? 'Please enter a valid email' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (value) => (value == null || value.isEmpty || value.length < 6)
                          ? 'Password must be at least 6 characters' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        ),
                      ),
                      validator: (value) => (value != _passwordController.text) ? 'Passwords do not match' : null,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(onPressed: _register,
                        child: const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Already have an account? Sign In',
                          style: TextStyle(color: Theme.of(context).primaryColor)),
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
  DateTime startDate;
  DateTime endDate;
  bool isAllDay;
  TimeOfDay? startTime;
  TimeOfDay? endTime;

  Task({
    required this.id,
    required this.title,
    this.isDone = false,
    required this.priority,
    required this.startDate,
    DateTime? endDate,
    this.isAllDay = true,
    this.startTime,
    this.endTime,
  }) : endDate = endDate ?? startDate; // Ensures endDate is at least startDate

  // Helper to get duration in days (minimum 1)
  int get durationInDays {
    // Ensure we use dateOnly for correct day calculation
    final start = DateUtils.dateOnly(startDate);
    final end = DateUtils.dateOnly(endDate);
    return end.difference(start).inDays + 1;
  }
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

  // Mock data for tasks
  final List<Task> _tasks = [
    Task(
      id: '1',
      title: 'Team Meeting',
      priority: Priority.high,
      startDate: DateUtils.dateOnly(DateTime.now()),
      isAllDay: false,
      startTime: const TimeOfDay(hour: 10, minute: 0),
      endTime: const TimeOfDay(hour: 11, minute: 0),
    ),
    Task(
      id: '2',
      title: 'Project Sprint (Daily)',
      priority: Priority.high,
      startDate: DateUtils.dateOnly(DateTime.now().subtract(const Duration(days: 2))),
      endDate: DateUtils.dateOnly(DateTime.now().add(const Duration(days: 3))),
      isAllDay: true,
    ),
    Task(
      id: '3',
      title: 'Gym Workout',
      priority: Priority.medium,
      startDate: DateUtils.dateOnly(DateTime.now()),
      isAllDay: false,
      startTime: const TimeOfDay(hour: 18, minute: 0),
      endTime: const TimeOfDay(hour: 19, minute: 30),
    ),
    Task(
      id: '4',
      title: 'Buy Groceries',
      priority: Priority.low,
      startDate: DateUtils.dateOnly(DateTime.now()),
      isAllDay: true,
    ),
    Task(
      id: '5',
      title: 'Vacation (Monthly)',
      priority: Priority.medium,
      startDate: DateUtils.dateOnly(DateTime.now().add(const Duration(days: 5))),
      endDate: DateUtils.dateOnly(DateTime.now().add(const Duration(days: 35))),
      isAllDay: true,
    ),
     Task(
      id: '6',
      title: 'Phase 2 Planning (Weekly)',
      priority: Priority.high,
      startDate: DateUtils.dateOnly(DateTime.now().add(const Duration(days: 4))),
      endDate: DateUtils.dateOnly(DateTime.now().add(const Duration(days: 18))),
      isAllDay: true,
    ),
    Task(
      id: '7',
      title: 'Dentist Appointment',
      priority: Priority.medium,
      startDate: DateUtils.dateOnly(DateTime.now().add(const Duration(days: 2))),
      isAllDay: false,
      startTime: const TimeOfDay(hour: 14, minute: 30),
      endTime: const TimeOfDay(hour: 15, minute: 0),
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedDate(isAnimated: false); // Jump without animation on init
    });
  }

  @override
  void dispose() {
    _dateScrollController.dispose();
    super.dispose();
  }

  // --- MODIFIED: Added isAnimated parameter and improved logic ---
  void _scrollToSelectedDate({bool isAnimated = true}) {
    const itemWidth = 70.0 + 12.0; // 70 for item, 12 for margin
    const dateRange = 30; // Days shown before today
    final now = DateUtils.dateOnly(DateTime.now());
    final daysDifference = _selectedDate.difference(now).inDays;
    
    // Target offset to center the selected date
    final targetOffset = (daysDifference + dateRange) * itemWidth -
        (MediaQuery.of(context).size.width / 2) + (itemWidth / 2);

    if (_dateScrollController.hasClients) {
      if (isAnimated) {
        _dateScrollController.animateTo(
          targetOffset.clamp(0.0, _dateScrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _dateScrollController.jumpTo(
           targetOffset.clamp(0.0, _dateScrollController.position.maxScrollExtent),
        );
      }
    }
  }

  void _showCalendar() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CalendarScreen(
          tasks: _tasks,
          selectedDate: _selectedDate,
          onDateSelected: (date) {
            setState(() => _selectedDate = date);
            _scrollToSelectedDate();
          },
        ),
      ),
    );
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
              if (index != -1) _tasks[index] = task;
            }
          });
          Navigator.pop(context);
        },
        onDelete: taskToEdit != null ? () {
          setState(() => _tasks.removeWhere((t) => t.id == taskToEdit.id));
          Navigator.pop(context);
        } : null,
      ),
    );
  }

  void _toggleTaskStatus(Task task) {
    setState(() => task.isDone = !task.isDone);
  }

  // Sorts by Priority (High > Low), then by Time (Time < All Day)
  int _compareTasksByPriority(Task a, Task b) {
    if (a.priority.index != b.priority.index) {
      return a.priority.index.compareTo(b.priority.index);
    }
    if (a.isAllDay && !b.isAllDay) return 1; // All day tasks come after timed tasks
    if (!a.isAllDay && b.isAllDay) return -1;
    if (a.startTime != null && b.startTime != null) {
      final aMinutes = a.startTime!.hour * 60 + a.startTime!.minute;
      final bMinutes = b.startTime!.hour * 60 + b.startTime!.minute;
      return aMinutes.compareTo(bMinutes);
    }
    return 0;
  }

  Map<DateTime, int> _getTaskCountsByDate() {
    final Map<DateTime, int> counts = {};
    for (var task in _tasks) {
      for (var i = 0; i < task.durationInDays; i++) {
        final date = DateUtils.dateOnly(task.startDate.add(Duration(days: i)));
        counts[date] = (counts[date] ?? 0) + 1;
      }
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    // Filter tasks that are active on the selected date
    final tasksForSelectedDay = _tasks.where((task) {
      final startDateOnly = DateUtils.dateOnly(task.startDate);
      final endDateOnly = DateUtils.dateOnly(task.endDate);
      return (_selectedDate.isAfter(startDateOnly.subtract(const Duration(days: 1))) &&
          _selectedDate.isBefore(endDateOnly.add(const Duration(days: 1))));
    }).toList()..sort(_compareTasksByPriority);

    return Scaffold(
      appBar: AppBar(
        title: Text('Forecast', style: TextStyle(
          fontSize: 28, fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor)),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded, size: 24),
            onPressed: _showCalendar,
            tooltip: 'Calendar',
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: AppDrawer(tasks: _tasks, onCalendarTap: _showCalendar),
      body: Column(
        children: [
          HorizontalDatePicker(
            selectedDate: _selectedDate,
            scrollController: _dateScrollController,
            taskCounts: _getTaskCountsByDate(),
            onDateSelected: (newDate) {
              setState(() => _selectedDate = newDate);
              _scrollToSelectedDate();
            },
          ),
          Expanded(
            child: tasksForSelectedDay.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_available_rounded, size: 80,
                            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        Text('No tasks for this day', style: TextStyle(fontSize: 18,
                            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6))),
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
  final Map<DateTime, int> taskCounts;
  final Function(DateTime) onDateSelected;

  const HorizontalDatePicker({
    super.key,
    required this.selectedDate,
    required this.scrollController,
    required this.taskCounts,
    required this.onDateSelected,
  });

  String _formatDay(DateTime date) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final now = DateUtils.dateOnly(DateTime.now());
    // --- MODIFIED: Show 30 days past, 60 days future ---
    final firstDate = now.subtract(const Duration(days: 30));

    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Theme.of(context).appBarTheme.backgroundColor,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: ListView.builder(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        itemCount: 90, // 30 past + 60 future
        itemBuilder: (context, index) {
          final date = firstDate.add(Duration(days: index));
          final isSelected = DateUtils.isSameDay(date, selectedDate);
          final isToday = DateUtils.isSameDay(date, now);
          final taskCount = taskCounts[date] ?? 0;

          return GestureDetector(
            onTap: () => onDateSelected(date),
            child: Container(
              width: 70,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                gradient: isSelected ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.8),
                  ],
                ) : null,
                color: isSelected ? null : (isToday
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : Colors.transparent),
                borderRadius: BorderRadius.circular(20),
                border: isToday && !isSelected
                    ? Border.all(color: Theme.of(context).primaryColor, width: 2)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_formatDay(date), style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : (isToday
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.6)))),
                  const SizedBox(height: 8),
                  Text(date.day.toString(), style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : (isToday
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).colorScheme.onSurface))),
                  const SizedBox(height: 4),
                  // Task counter dots
                  if (taskCount > 0)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        math.min(taskCount, 3), // Show max 3 dots
                        (i) => Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  if (taskCount == 0) // Keep spacing consistent
                     const SizedBox(height: 5),
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
  final List<Task> tasks;
  final VoidCallback onCalendarTap;

  const AppDrawer({super.key, required this.tasks, required this.onCalendarTap});

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
                const Icon(Icons.task_alt_rounded, size: 48, color: Colors.white),
                const SizedBox(height: 12),
                const Text('Task Manager',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_rounded),
            title: const Text('Account'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => const AccountSettingsScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today_rounded),
            title: const Text('Calendar'),
            onTap: () {
              Navigator.pop(context);
              onCalendarTap();
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart_rounded),
            title: const Text('Gantt Chart'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => GanttChartScreen(tasks: tasks)));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.palette_rounded),
            title: const Text('Themes'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => const ThemesScreen()));
            },
          ),
        ],
      ),
    );
  }
}

// --- Calendar Screen ---
class CalendarScreen extends StatefulWidget {
  final List<Task> tasks;
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;

  const CalendarScreen({
    super.key,
    required this.tasks,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _focusedMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
    _focusedMonth = DateTime(_selectedDate.year, _selectedDate.month);
  }

  Map<DateTime, int> _getTaskCountsByDate() {
    final Map<DateTime, int> counts = {};
    for (var task in widget.tasks) {
      for (var i = 0; i < task.durationInDays; i++) {
        final date = DateUtils.dateOnly(task.startDate.add(Duration(days: i)));
        counts[date] = (counts[date] ?? 0) + 1;
      }
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final taskCounts = _getTaskCountsByDate();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today_rounded),
            onPressed: () {
              setState(() {
                _selectedDate = DateUtils.dateOnly(DateTime.now());
                _focusedMonth = DateTime(_selectedDate.year, _selectedDate.month);
              });
            },
            tooltip: 'Today',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: () {
                    setState(() {
                      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
                    });
                  },
                ),
                Text(
                  '${_getMonthName(_focusedMonth.month)} ${_focusedMonth.year}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: () {
                    setState(() {
                      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildCalendar(taskCounts),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    widget.onDateSelected(_selectedDate);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Select Date'),
                ),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'];
    return months[month - 1];
  }

  Widget _buildCalendar(Map<DateTime, int> taskCounts) {
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    // Handle Sunday (7) as start of week (0)
    final firstWeekday = firstDayOfMonth.weekday == 7 ? 0 : firstDayOfMonth.weekday;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                  .map((day) => SizedBox(
                        width: 40,
                        child: Text(day, textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            ...List.generate((daysInMonth + firstWeekday + 6) ~/ 7, (weekIndex) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(7, (dayIndex) {
                    final dayNumber = weekIndex * 7 + dayIndex - firstWeekday + 1;
                    if (dayNumber < 1 || dayNumber > daysInMonth) {
                      return const SizedBox(width: 40, height: 50);
                    }

                    final date = DateTime(_focusedMonth.year, _focusedMonth.month, dayNumber);
                    final isSelected = DateUtils.isSameDay(date, _selectedDate);
                    final isToday = DateUtils.isSameDay(date, DateTime.now());
                    final taskCount = taskCounts[date] ?? 0;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedDate = date),
                      child: Container(
                        width: 40,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isSelected ? Theme.of(context).primaryColor : null,
                          borderRadius: BorderRadius.circular(12),
                          border: isToday && !isSelected
                              ? Border.all(color: Theme.of(context).primaryColor, width: 2)
                              : null,
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Text('$dayNumber',
                                  style: TextStyle(
                                    color: isSelected ? Colors.white :
                                      (isToday ? Theme.of(context).primaryColor : null),
                                    fontWeight: isSelected || isToday ? FontWeight.bold : null,
                                  )),
                            ),
                            if (taskCount > 0)
                              Positioned(
                                bottom: 4,
                                left: 0,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    math.min(taskCount, 3),
                                    (i) => Container(
                                      width: 4,
                                      height: 4,
                                      margin: const EdgeInsets.symmetric(horizontal: 1),
                                      decoration: BoxDecoration(
                                        color: isSelected ? Colors.white : Theme.of(context).primaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// --- Account Settings Screen ---
class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _usernameController = TextEditingController(text: UserData.username);
  final _emailController = TextEditingController(text: UserData.email);
  final _passwordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    // TODO: Add API call to update user info
    UserData.username = _usernameController.text;
    UserData.email = _emailController.text;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Account updated successfully')),
    );
    Navigator.pop(context);
  }

  void _logout() {
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                child: Icon(Icons.person_rounded, size: 50, color: Theme.of(context).primaryColor),
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password (optional)',
                prefixIcon: Icon(Icons.lock_reset),
              ),
            ),
            const SizedBox(height: 32),
            // --- ADDED: Light/Dark Mode Toggle ---
            ValueListenableBuilder<ThemeMode>(
              valueListenable: ThemeManager.themeNotifier,
              builder: (_, themeMode, __) {
                return Container(
                   decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: SwitchListTile(
                    title: const Text('Dark Mode'),
                    value: themeMode == ThemeMode.dark,
                    onChanged: (bool value) {
                      ThemeManager.themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
                    },
                    secondary: Icon(themeMode == ThemeMode.dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded),
                  ),
                );
              },
            ),
            // --- END ADDITION ---
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveChanges,
              child: const Text('Save Changes'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Logout'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Gantt Chart Screen (MODIFIED) ---
class GanttChartScreen extends StatefulWidget {
  final List<Task> tasks;

  const GanttChartScreen({super.key, required this.tasks});

  @override
  State<GanttChartScreen> createState() => _GanttChartScreenState();
}

class _GanttChartScreenState extends State<GanttChartScreen> {
  String _viewMode = 'daily'; // daily, weekly, monthly
  // --- REMOVED: _isHorizontal is not needed for this design ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gantt Chart'),
        // --- REMOVED: Rotate Button ---
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildViewModeButton('Daily', 'daily'),
                _buildViewModeButton('Weekly', 'weekly'),
                _buildViewModeButton('Monthly', 'monthly'),
              ],
            ),
          ),
          Expanded(
            // --- MODIFIED: We only need one build method ---
            child: _buildHorizontalGantt(),
          ),
        ],
      ),
    );
  }

  Widget _buildViewModeButton(String label, String mode) {
    final isSelected = _viewMode == mode;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: () => setState(() => _viewMode = mode),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected
                ? Theme.of(context).primaryColor
                : Theme.of(context).colorScheme.surface,
            foregroundColor: isSelected
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
          ),
          child: Text(label),
        ),
      ),
    );
  }

  // --- MODIFIED: Complete overhaul of Gantt chart ---
  Widget _buildHorizontalGantt() {
    final sortedTasks = List<Task>.from(widget.tasks)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    if (sortedTasks.isEmpty) {
      return const Center(child: Text('No tasks to display'));
    }

    final earliest = sortedTasks.first.startDate;
    final latest = sortedTasks.map((t) => t.endDate).reduce((a, b) => a.isAfter(b) ? a : b);
    // Add some padding to the end of the chart
    final chartEndDate = latest.add(const Duration(days: 30));
    final totalDays = chartEndDate.difference(earliest).inDays + 1;

    double dayWidth;
    int headerInterval; // How many days per header item
    String Function(DateTime) getHeaderLabel;

    switch (_viewMode) {
      case 'weekly':
        dayWidth = 20.0;
        headerInterval = 7;
        getHeaderLabel = (date) => 'W${(date.day / 7).ceil()}';
        break;
      case 'monthly':
        dayWidth = 8.0;
        headerInterval = 30; // Approx
        getHeaderLabel = (date) => _getMonthName(date.month).substring(0, 3);
        break;
      case 'daily':
      default:
        dayWidth = 60.0;
        headerInterval = 1;
        getHeaderLabel = (date) => '${date.day}';
        break;
    }

    final double barHeight = 44.0;
    final double totalWidth = totalDays * dayWidth;

    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: totalWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Timeline Header ---
                _buildTimelineHeader(earliest, totalDays, dayWidth, headerInterval, getHeaderLabel),
                const SizedBox(height: 16),
                // --- Task Bars ---
                ...sortedTasks.map((task) {
                  final startOffsetDays = task.startDate.difference(earliest).inDays;
                  final barWidth = task.durationInDays * dayWidth - 4; // -4 for padding
                  final marginLeft = startOffsetDays * dayWidth;
                  final color = _getPriorityColor(task.priority);

                  return Container(
                    margin: EdgeInsets.only(left: marginLeft, bottom: 12),
                    width: barWidth < 0 ? 0 : barWidth,
                    height: barHeight,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withOpacity(0.7)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          task.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- ADDED: New Timeline Header Widget ---
  Widget _buildTimelineHeader(
    DateTime earliest,
    int totalDays,
    double dayWidth,
    int interval,
    String Function(DateTime) getLabel,
  ) {
    List<Widget> headers = [];
    DateTime currentDate = earliest;

    for (int i = 0; i < totalDays; i += 1) {
      if (i % interval == 0 || (_viewMode == 'monthly' && currentDate.day == 1 && i > 0)) {
         if (_viewMode == 'monthly') {
          // Calculate width for the month
          final daysInMonth = DateUtils.getDaysInMonth(currentDate.year, currentDate.month);
          final daysToAdd = (i == 0) ? daysInMonth - currentDate.day + 1 : daysInMonth;
          
           headers.add(
            Container(
              width: daysToAdd * dayWidth,
              height: 40,
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: Theme.of(context).dividerColor, width: 1),
                ),
              ),
              child: Center(
                child: Text(
                  '${getLabel(currentDate)} ${currentDate.year}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          );
          i += daysToAdd -1; // Skip ahead
          currentDate = currentDate.add(Duration(days: daysToAdd));

        } else {
           // Daily and Weekly
           headers.add(
            Container(
              width: interval * dayWidth,
              height: 40,
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: Theme.of(context).dividerColor, width: 1),
                ),
              ),
              child: Center(
                child: Text(
                  _viewMode == 'daily' ? '${currentDate.day} ${_getMonthName(currentDate.month).substring(0,3)}' : getLabel(currentDate),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          );
          i += interval -1;
          currentDate = currentDate.add(Duration(days: interval));
        }

      } else if (_viewMode == 'monthly') {
         currentDate = currentDate.add(const Duration(days: 1));
      } else if (_viewMode == 'weekly') {
         currentDate = currentDate.add(const Duration(days: 1));
      } else {
         currentDate = currentDate.add(const Duration(days: 1));
      }
    }

    return Row(children: headers);
  }

  // --- REMOVED: _buildVerticalGantt() is no longer needed ---

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

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
// --- END MODIFICATION ---

// --- Themes Screen ---
class ThemesScreen extends StatelessWidget {
  const ThemesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Themes')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildThemeOption(
            context,
            'Default Blue',
            AppThemes.defaultBlue,
            const Color(0xFF5E81F4),
          ),
          _buildThemeOption(
            context,
            'Purple Dream',
            AppThemes.purple,
            const Color(0xFF9D8FF7),
          ),
          _buildThemeOption(
            context,
            'Nature Green',
            AppThemes.green,
            const Color(0xFF4CAF50),
          ),
          _buildThemeOption(
            context,
            'Sunset Orange',
            AppThemes.orange,
            const Color(0xFFFF9800),
          ),
          _buildThemeOption(
            context,
            'Cherry Pink',
            AppThemes.pink,
            const Color(0xFFE91E63),
          ),
          _buildThemeOption(
            context,
            'Ocean Teal',
            AppThemes.teal,
            const Color(0xFF009688),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    String name,
    String themeKey,
    Color color,
  ) {
    return ValueListenableBuilder<String>(
      valueListenable: ThemeManager.colorThemeNotifier,
      builder: (context, currentTheme, _) {
        final isSelected = currentTheme == themeKey;
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: isSelected
                ? Border.all(color: color, width: 3)
                : Border.all(color: Theme.of(context).dividerColor, width: 1), // Added default border
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            title: Text(
              name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: isSelected
                ? Icon(Icons.check_circle_rounded, color: color, size: 32)
                : null,
            onTap: () {
              ThemeManager.colorThemeNotifier.value = themeKey;
            },
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // For inkwell
          ),
        );
      },
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

  String _formatDuration() {
    if (task.durationInDays == 1) return '';
    return '${task.durationInDays} days';
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
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (!task.isAllDay || task.startTime != null) ...[
                            Icon(Icons.access_time_rounded, size: 14,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                            const SizedBox(width: 4),
                            Text(_formatTime(context),
                                style: TextStyle(fontSize: 13,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                          ],
                          if (_formatDuration().isNotEmpty) ...[
                            const SizedBox(width: 12),
                            Icon(Icons.calendar_today_rounded, size: 14,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                            const SizedBox(width: 4),
                            Text(_formatDuration(),
                                style: TextStyle(fontSize: 13,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                          ],
                        ],
                      ),
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
  DateTime _startDate = DateUtils.dateOnly(DateTime.now());
  DateTime _endDate = DateUtils.dateOnly(DateTime.now());
  bool _isAllDay = true;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _selectedPriority = widget.task!.priority;
      _startDate = widget.task!.startDate;
      _endDate = widget.task!.endDate;
      _isAllDay = widget.task!.isAllDay;
      _startTime = widget.task!.startTime;
      _endTime = widget.task!.endTime;
    } else {
      // New task defaults to selected date
      _startDate = widget.defaultDate;
      _endDate = widget.defaultDate;
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
        startDate: _startDate,
        endDate: _endDate,
        isAllDay: _isAllDay,
        startTime: _isAllDay ? null : _startTime,
        endTime: _isAllDay ? null : _endTime,
        isDone: widget.task?.isDone ?? false,
      ),
    );
  }

  Future<void> _pickDate(bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = DateUtils.dateOnly(picked);
          // Ensure end date is not before start date
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = DateUtils.dateOnly(picked);
          // Ensure start date is not after end date
           if (_startDate.isAfter(_endDate)) {
            _startDate = _endDate;
          }
        }
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
                Text(widget.task == null ? 'New Task' : 'Edit Task',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
                      child: Text(priority.name.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold,
                            color: isSelected ? color : Theme.of(context).colorScheme.onSurface,
                            letterSpacing: 0.5)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.background, // Use background color
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.calendar_today_rounded),
                      title: const Text('Start'),
                      subtitle: Text(
                        '${_startDate.month}/${_startDate.day}/${_startDate.year}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onTap: () => _pickDate(true),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.background, // Use background color
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.event_rounded),
                      title: const Text('End'),
                      subtitle: Text(
                        '${_endDate.month}/${_endDate.day}/${_endDate.year}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onTap: () => _pickDate(false),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.background, // Use background color
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
                        color: Theme.of(context).colorScheme.background, // Use background color
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
                        color: Theme.of(context).colorScheme.background, // Use background color
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
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18)),
              child: Text(widget.task == null ? 'Create Task' : 'Update Task',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}