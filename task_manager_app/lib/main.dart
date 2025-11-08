import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// --- Simple API client ---
class ApiClient {
  static const String baseUrl = 'https://ff5ae32c379e.ngrok-free.app';
  final Duration _timeout = const Duration(seconds: 10);

  /// Attempt login. Returns decoded JSON map on success (contains at least
  /// 'username' and 'email'), or null on failure.
  Future<Map<String, dynamic>?> login(
      {String? username, String? email, required String hash}) async {
    final uri = Uri.parse('$baseUrl/login');
    final body = <String, dynamic>{'hash': hash};
    if (username != null && username.isNotEmpty) {
      body['username'] = username;
    } else if (email != null && email.isNotEmpty) {
      body['email'] = email;
    }

    final request = http.Request('POST', uri);
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode(body);

    final streamedResponse = await request.send().timeout(_timeout);
    final resp = await http.Response.fromStream(streamedResponse);
    if (resp.statusCode == 200) {
      try {
        final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
        return decoded;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<bool> register(
      {required String username,
      required String email,
      required String hash}) async {
    final uri = Uri.parse('$baseUrl/register');
    final body = {'username': username, 'email': email, 'hash': hash};

    final request = http.Request('POST', uri);
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode(body);

    final streamedResponse = await request.send().timeout(_timeout);
    final resp = await http.Response.fromStream(streamedResponse);

    return resp.statusCode == 201;
  }

  /// Create a task on the server. Expects a map with keys matching the server
  /// fields (owner_id, title, start_dt (ISO), end_dt (ISO), priority, notes).
  /// Returns the created task map on success, or null on failure.
  Future<Map<String, dynamic>?> createTask(Map<String, dynamic> task) async {
    final uri = Uri.parse('$baseUrl/create_task');
    final request = http.Request('POST', uri);
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode(task);

    try {
      final streamedResponse = await request.send().timeout(_timeout);
      final resp = await http.Response.fromStream(streamedResponse);
      if (resp.statusCode == 201) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Update an existing task on the server. Expects JSON with 'id' and fields to update.
  /// Returns updated task map on success, or null on failure.
  Future<Map<String, dynamic>?> updateTask(Map<String, dynamic> task) async {
    final uri = Uri.parse('$baseUrl/update_task');
    final request = http.Request('PUT', uri);
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode(task);

    try {
      final streamedResponse = await request.send().timeout(_timeout);
      final resp = await http.Response.fromStream(streamedResponse);
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
      // treat 202 or other codes as null for now
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Delete a task on the server. Provide a payload with at least 'id'.
  /// Returns true if server accepted/confirmed deletion (200 or 202), false otherwise.
  Future<bool> deleteTask(Map<String, dynamic> payload) async {
    final uri = Uri.parse('$baseUrl/delete_task');
    final request = http.Request('DELETE', uri);
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode(payload);

    try {
      final streamedResponse = await request.send().timeout(_timeout);
      final resp = await http.Response.fromStream(streamedResponse);
      if (resp.statusCode == 200 || resp.statusCode == 202) {
        return true;
      }
    } catch (e) {
      // ignore network errors for now
    }
    return false;
  }

  /// Ask the server to read its local per-user JSON file and apply changes to the DB.
  /// Provide either `username` or `userId` (string). Returns decoded JSON summary or null on failure.
  Future<Map<String, dynamic>?> updateDbWithLocal({String? username, String? userId}) async {
    final uri = Uri.parse('$baseUrl/update_db_with_local');
    final body = <String, dynamic>{};
    if (username != null && username.isNotEmpty) body['username'] = username;
    if (userId != null && userId.isNotEmpty) {
      // try to send numeric id if possible
      final n = int.tryParse(userId);
      body['user_id'] = n ?? userId;
    }

    final request = http.Request('POST', uri);
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode(body);

    try {
      final streamed = await request.send().timeout(_timeout);
      final resp = await http.Response.fromStream(streamed);
      if (resp.statusCode == 200 || resp.statusCode == 202) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
    } catch (e) {
      // ignore for now
    }
    return null;
  }
}

// Theme palette container used across the app
class AppThemes {
  static const defaultBlue = 'defaultBlue';
  static const sunrise = 'sunrise';
  static const forest = 'forest';
  static const ocean = 'ocean';
  static const purple = 'purple';
  static const pink = 'pink';

  static final Map<String, Map<String, Color>> themes = {
    defaultBlue: {
      'primary': const Color(0xFF5E81F4),
      'secondary': const Color(0xFF7B68EE),
      'accent': const Color(0xFF4169E1),
      'gradientEnd': const Color(0xFF4169E1),
    },
    sunrise: {
      'primary': const Color(0xFFFF8C00),
      'secondary': const Color(0xFFFFB347),
      'accent': const Color(0xFFFF6347),
      'gradientEnd': const Color(0xFFFF6347),
    },
    forest: {
      'primary': const Color(0xFF2E7D32),
      'secondary': const Color(0xFF66BB6A),
      'accent': const Color(0xFFA1887F),
      'gradientEnd': const Color(0xFF4CAF50),
    },
    ocean: {
      'primary': const Color(0xFF0277BD),
      'secondary': const Color(0xFF4FC3F7),
      'accent': const Color(0xFF009688),
      'gradientEnd': const Color(0xFF009688),
    },
    purple: {
      'primary': const Color(0xFF9D8FF7),
      'secondary': const Color(0xFFB8A4F5),
      'accent': const Color(0xFF7B68EE),
      'gradientEnd': const Color(0xFF7B68EE),
    },
    pink: {
      'primary': const Color(0xFFE91E63),
      'secondary': const Color(0xFFF06292),
      'accent': const Color(0xFFC2185B),
      'gradientEnd': const Color(0xFFC2185B),
    },
  };
}

class ThemeManager {
  static final ValueNotifier<ThemeMode> themeNotifier =
      ValueNotifier(ThemeMode.dark);
  static final ValueNotifier<String> colorThemeNotifier =
      ValueNotifier(AppThemes.defaultBlue);
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
        background: const Color(0xFFF5F7FA),
        surface: Colors.white,
        onBackground: const Color(0xFF1A1A1A),
        onSurface: const Color(0xFF1A1A1A),
        error: const Color(0xFFFF6B6B),
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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
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
        background: const Color(0xFF0D0D0D),
        surface: const Color(0xFF1A1A1A),
        onBackground: const Color(0xFFE8E8E8),
        onSurface: const Color(0xFFE8E8E8),
        error: const Color(0xFFFF6B6B),
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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
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
  static String userId = '';
}

// --- Global Data Storage ---
class AppData {
  static final List<Group> groups = [];
  static final List<GroupInvitation> groupInvitations = [];
  static final List<ActivityLog> activityLogs = [];
  
  static void addLog(String action, String taskTitle, {String? details}) {
    final log = ActivityLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      action: action,
      taskTitle: taskTitle,
      details: details,
    );
    activityLogs.insert(0, log); // Add to beginning for newest first
    
    // Keep only last 500 logs to avoid memory issues
    if (activityLogs.length > 500) {
      activityLogs.removeRange(500, activityLogs.length);
    }
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
    final String credential = _credentialController.text.trim();
    final String password = _passwordController.text;
    final bool isEmail = credential.contains('@');

    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes).toString();

    final api = ApiClient();
    try {
      final resp = await api.login(
        username: isEmail ? null : credential,
        email: isEmail ? credential : null,
        hash: digest,
      );
      if (resp != null) {
        UserData.username = (resp['username'] as String?) ?? '';
        UserData.email = (resp['email'] as String?) ?? '';
        UserData.userId = (resp['user_id']?.toString()) ?? '';
        try {
          final uid = resp['user_id']?.toString();
          final tasks = resp['tasks'] as List<dynamic>?;
          if (uid != null && tasks != null) {
            await _saveTasksLocally(uid, tasks);
          }
        } catch (e) {
          // ignore local save errors for now
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

  Future<void> _saveTasksLocally(String userId, List<dynamic> tasks) async {
    try {
      // Web-compatible: Store in memory instead of file system
      // In production, use localStorage or backend API
      // ignore: avoid_print
      print('Tasks loaded for user $userId: ${tasks.length} tasks');
    } catch (e) {
      // ignore write errors for now
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
                    Icon(Icons.task_alt_rounded,
                        size: 80, color: Theme.of(context).primaryColor),
                    const SizedBox(height: 24),
                    Text('Welcome Back',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Sign in to continue',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color:
                                Theme.of(context).textTheme.bodySmall?.color)),
                    const SizedBox(height: 48),
                    TextFormField(
                      controller: _credentialController,
                      decoration: const InputDecoration(
                          labelText: 'Username or Email',
                          prefixIcon: Icon(Icons.person_outline_rounded)),
                      validator: (value) =>
                          (value == null || value.isEmpty)
                              ? 'Please enter your username or email'
                              : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (value) =>
                          (value == null || value.isEmpty || value.length < 6)
                              ? 'Password must be at least 6 characters'
                              : null,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                        onPressed: _login,
                        child: const Text('Sign In',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600))),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/register'),
                      child: Text("Don't have an account? Sign Up",
                          style:
                              TextStyle(color: Theme.of(context).primaryColor)),
                    ),
                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Forgot Password flow not implemented.')),
                        );
                      },
                      child: Text("Forgot Password?",
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6))),
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
      final created =
          await api.register(username: username, email: email, hash: digest);
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
                    Text('Create Account',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Sign up to get started',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color:
                                Theme.of(context).textTheme.bodySmall?.color)),
                    const SizedBox(height: 40),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                          labelText: 'Username',
                          prefixIcon: Icon(Icons.person_outline)),
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Please enter a username'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined)),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) =>
                          (value == null || value.isEmpty || !value.contains('@'))
                              ? 'Please enter a valid email'
                              : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (value) =>
                          (value == null || value.isEmpty || value.length < 6)
                              ? 'Password must be at least 6 characters'
                              : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () => setState(() =>
                              _obscureConfirmPassword = !_obscureConfirmPassword),
                        ),
                      ),
                      validator: (value) => (value != _passwordController.text)
                          ? 'Passwords do not match'
                          : null,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                        onPressed: _register,
                        child: const Text('Create Account',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600))),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Already have an account? Sign In',
                          style:
                              TextStyle(color: Theme.of(context).primaryColor)),
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

enum GroupMemberRole { editor, viewer }

enum GroupInvitationStatus { pending, accepted, rejected }

class GroupMember {
  final String userId;
  final String username;
  final String email;
  final GroupMemberRole role;

  GroupMember({
    required this.userId,
    required this.username,
    required this.email,
    required this.role,
  });
}

class Group {
  final String id;
  String name;
  final String creatorId;
  final List<GroupMember> members;

  Group({
    required this.id,
    required this.name,
    required this.creatorId,
    required this.members,
  });
}

class GroupInvitation {
  final String id;
  final String groupId;
  final String groupName;
  final String invitedByUsername;
  final String invitedByUserId;
  final GroupMemberRole role;
  GroupInvitationStatus status;

  GroupInvitation({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.invitedByUsername,
    required this.invitedByUserId,
    required this.role,
    required this.status,
  });
}

class ActivityLog {
  final String id;
  final DateTime timestamp;
  final String action;
  final String taskTitle;
  final String? details;

  ActivityLog({
    required this.id,
    required this.timestamp,
    required this.action,
    required this.taskTitle,
    this.details,
  });
}

class Task {
  final String id;
  String title;
  bool isDone;
  Priority priority;
  DateTime startDate;
  DateTime endDate;
  String? notes;
  bool isAllDay;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  final List<String> sharedWithUserIds;

  Task({
    required this.id,
    required this.title,
    this.isDone = false,
    required this.priority,
    required this.startDate,
    DateTime? endDate,
    this.notes,
    this.isAllDay = true,
    this.startTime,
    this.endTime,
    List<String>? sharedWithUserIds,
  }) : endDate = endDate ?? startDate,
       sharedWithUserIds = sharedWithUserIds ?? [];

  int get durationInDays {
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

  final List<Task> _tasks = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedDate(isAnimated: false);
    });
    _startPeriodicServerSync();
    _loadLocalTasks();
  }

  Timer? _syncTimer;

  void _startPeriodicServerSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      await _callUpdateDbWithLocal();
    });
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _dateScrollController.dispose();
    super.dispose();
  }

  Future<void> _callUpdateDbWithLocal() async {
    try {
      final api = ApiClient();
      final resp = await api.updateDbWithLocal(username: UserData.username, userId: UserData.userId);
      if (resp != null) {
        try {
          // ignore: avoid_print
          print('update_db_with_local: ${resp}');
        } catch (_) {}
      }
    } catch (e) {
      // ignore network errors for now
    }
  }

  Future<void> _loadLocalTasks() async {
    try {
      // Web-compatible: Tasks loaded from server on login
      // Local file system not available on web
      // ignore: avoid_print
      print('Tasks will be loaded from server on login');
    } catch (e) {
      // ignore errors for now
    }
  }

  void _scrollToSelectedDate({bool isAnimated = true}) {
    const itemWidth = 70.0 + 12.0;
    const dateRange = 30;
    final now = DateUtils.dateOnly(DateTime.now());
    final daysDifference = _selectedDate.difference(now).inDays;

    final targetOffset = (daysDifference + dateRange) * itemWidth -
        (MediaQuery.of(context).size.width / 2) +
        (itemWidth / 2);

    if (_dateScrollController.hasClients) {
      if (isAnimated) {
        _dateScrollController.animateTo(
          targetOffset.clamp(
              0.0, _dateScrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _dateScrollController.jumpTo(
          targetOffset.clamp(
              0.0, _dateScrollController.position.maxScrollExtent),
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
        onSave: (Task task) async {
          if (taskToEdit == null) {
            // Adding new task
            setState(() {
              _tasks.add(task);
            });
            AppData.addLog('Created', task.title);
            await _createOrPersistTask(task);
          } else {
            // Updating existing task - track changes
            String changes = '';
            if (taskToEdit.title != task.title) {
              changes += 'Title: "${taskToEdit.title}" → "${task.title}"; ';
            }
            if (taskToEdit.priority != task.priority) {
              changes += 'Priority: ${taskToEdit.priority.name} → ${task.priority.name}; ';
            }
            if (!DateUtils.isSameDay(taskToEdit.startDate, task.startDate)) {
              changes += 'Start: ${taskToEdit.startDate.day}/${taskToEdit.startDate.month} → ${task.startDate.day}/${task.startDate.month}; ';
            }
            if (!DateUtils.isSameDay(taskToEdit.endDate, task.endDate)) {
              changes += 'End: ${taskToEdit.endDate.day}/${taskToEdit.endDate.month} → ${task.endDate.day}/${task.endDate.month}; ';
            }
            if (taskToEdit.isAllDay != task.isAllDay) {
              changes += 'All Day: ${taskToEdit.isAllDay} → ${task.isAllDay}; ';
            }
            
            setState(() {
              final index = _tasks.indexWhere((t) => t.id == taskToEdit.id);
              if (index != -1) {
                _tasks[index] = Task(
                  id: task.id,
                  title: task.title,
                  priority: task.priority,
                  startDate: task.startDate,
                  endDate: task.endDate,
                  isAllDay: task.isAllDay,
                  startTime: task.startTime,
                  endTime: task.endTime,
                  isDone: task.isDone,
                  sharedWithUserIds: taskToEdit.sharedWithUserIds,
                  notes: task.notes,
                );
              }
            });
            
            if (changes.isNotEmpty) {
              AppData.addLog('Edited', task.title, details: changes);
            }
            
            await _updateOrPersistTask(_tasks.firstWhere((t) => t.id == task.id), oldId: taskToEdit.id);
          }
          if (mounted) Navigator.pop(context);
        },
        onDelete: taskToEdit != null
            ? () async {
                setState(() {
                  _tasks.removeWhere((t) => t.id == taskToEdit.id);
                });
                
                AppData.addLog('Deleted', taskToEdit.title);
                
                if (mounted) Navigator.pop(context);

                try {
                  final api = ApiClient();
                  final uid = UserData.userId;
                  final body = <String, dynamic>{
                    'id': int.tryParse(taskToEdit.id) ?? taskToEdit.id,
                    'title': taskToEdit.title,
                    'start_dt': taskToEdit.startDate.toIso8601String(),
                    'end_dt': taskToEdit.endDate.toIso8601String(),
                    'priority': (taskToEdit.priority == Priority.low) ? 1 : (taskToEdit.priority == Priority.medium) ? 2 : 3,
                    'notes': taskToEdit.notes ?? '',
                  };
                  if (uid.isNotEmpty) {
                    final n = int.tryParse(uid);
                    if (n != null) body['user_id'] = n;
                    else body['username'] = uid;
                  }
                  await api.deleteTask(body);
                } catch (e) {
                  // ignore network errors
                }
              }
            : null,
      ),
    );
  }

  void _toggleTaskStatus(Task task) {
    setState(() {
      task.isDone = !task.isDone;
      if (task.isDone) {
        AppData.addLog('Completed', task.title);
      } else {
        AppData.addLog('Uncompleted', task.title);
      }
    });
  }

  Future<void> _createOrPersistTask(Task task) async {
    final uid = UserData.userId;
    final api = ApiClient();

    Map<String, dynamic> toSend = {
      'owner_id': int.tryParse(uid ?? '') ,
      'title': task.title,
      'start_dt': task.startDate.toIso8601String(),
      'end_dt': task.endDate.toIso8601String(),
      'priority': (task.priority == Priority.low) ? 1 : (task.priority == Priority.medium) ? 2 : 3,
      'notes': '',
    };

    Map<String, dynamic>? created;
    if (uid.isNotEmpty) {
      try {
        created = await api.createTask(toSend);
      } catch (e) {
        created = null;
      }
    }

    final entry = created ?? {
      'id': task.id,
      'owner_id': uid.isNotEmpty ? int.tryParse(uid) : null,
      'title': task.title,
      'start_dt': task.startDate.toIso8601String(),
      'end_dt': task.endDate.toIso8601String(),
      'priority': (task.priority == Priority.low) ? 1 : (task.priority == Priority.medium) ? 2 : 3,
      'notes': '',
    };

    // Web-compatible: Skip local file operations
    // ignore: avoid_print
    print('Task created: ${entry['title']}');
  }

  Future<void> _updateOrPersistTask(Task task, {required String oldId}) async {
    final uid = UserData.userId;
    final api = ApiClient();

    Map<String, dynamic> toSend = {
      'id': int.tryParse(task.id) ?? task.id,
      'title': task.title,
      'start_dt': task.startDate.toIso8601String(),
      'end_dt': task.endDate.toIso8601String(),
      'priority': (task.priority == Priority.low) ? 1 : (task.priority == Priority.medium) ? 2 : 3,
      'notes': '',
    };

    Map<String, dynamic>? updated;
    if (uid.isNotEmpty) {
      try {
        updated = await api.updateTask(toSend);
      } catch (e) {
        updated = null;
      }
    }

    final entry = updated ?? {
      'id': task.id,
      'owner_id': uid.isNotEmpty ? int.tryParse(uid) : null,
      'title': task.title,
      'start_dt': task.startDate.toIso8601String(),
      'end_dt': task.endDate.toIso8601String(),
      'priority': (task.priority == Priority.low) ? 1 : (task.priority == Priority.medium) ? 2 : 3,
      'notes': '',
    };

    // Web-compatible: Skip local file operations
    // ignore: avoid_print
    print('Task updated: ${entry['title']}');

    if (updated != null) {
      final u = updated;
      final newId = u['id']?.toString();
      if (newId != null) {
        if (mounted) {
          setState(() {
            final idx = _tasks.indexWhere((t) => t.id == oldId);
            if (idx != -1) {
              _tasks[idx] = Task(
                id: newId,
                title: (u['title'] as String?) ?? _tasks[idx].title,
                priority: ((u['priority'] ?? 1) == 3) ? Priority.high : ((u['priority'] ?? 1) == 2 ? Priority.medium : Priority.low),
                startDate: u['start_dt'] != null ? DateTime.parse(u['start_dt']) : _tasks[idx].startDate,
                endDate: u['end_dt'] != null ? DateTime.parse(u['end_dt']) : _tasks[idx].endDate,
                isAllDay: true,
              );
            }
          });
        }
      }
    }
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

  String _formatFullDate(DateTime date) {
    final now = DateUtils.dateOnly(DateTime.now());
    if (DateUtils.isSameDay(date, now)) return 'Today';
    
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final tasksForSelectedDay = _tasks.where((task) {
      final startDateOnly = DateUtils.dateOnly(task.startDate);
      final endDateOnly = DateUtils.dateOnly(task.endDate);
      return (_selectedDate
              .isAfter(startDateOnly.subtract(const Duration(days: 1))) &&
          _selectedDate.isBefore(endDateOnly.add(const Duration(days: 1))));
    }).toList()
      ..sort(_compareTasksByPriority);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Forecast',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor)),
             Text(_formatFullDate(_selectedDate),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)
                )),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded, size: 24),
            onPressed: _showCalendar,
            tooltip: 'Calendar',
          ),
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
                        Icon(Icons.event_available_rounded,
                            size: 80,
                            color: Theme.of(context)
                                .colorScheme
                                .onBackground
                                .withOpacity(0.3)),
                        const SizedBox(height: 16),
                        Text('No tasks for this day',
                            style: TextStyle(
                                fontSize: 18,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onBackground
                                    .withOpacity(0.6))),
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
    final firstDate = now.subtract(const Duration(days: 30));
    final colors = AppThemes.themes[ThemeManager.colorThemeNotifier.value]!;

    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Theme.of(context).appBarTheme.backgroundColor,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: ListView.builder(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        itemCount: 90,
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
                gradient: isSelected
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colors['primary']!,
                          colors['gradientEnd']!.withOpacity(0.8),
                        ],
                      )
                    : null,
                color: isSelected
                    ? null
                    : (isToday
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
                  Text(_formatDay(date),
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : (isToday
                                  ? Theme.of(context).primaryColor
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.6)))),
                  const SizedBox(height: 8),
                  Text(date.day.toString(),
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : (isToday
                                  ? Theme.of(context).primaryColor
                                  : Theme.of(context).colorScheme.onSurface))),
                  const SizedBox(height: 4),
                  if (taskCount > 0)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        math.min(taskCount, 3),
                        (i) => Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  if (taskCount == 0) const SizedBox(height: 5),
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
    final colors = AppThemes.themes[ThemeManager.colorThemeNotifier.value]!;
    final pendingInvitationsCount = AppData.groupInvitations
        .where((inv) => inv.status == GroupInvitationStatus.pending)
        .length;

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
                  colors['primary']!,
                  colors['gradientEnd']!.withOpacity(0.8),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.task_alt_rounded,
                    size: 48, color: Colors.white),
                const SizedBox(height: 12),
                const Text('Task Manager',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_rounded),
            title: const Text('Account'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
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
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => GanttChartScreen(tasks: tasks)));
            },
          ),
          const Divider(),
          ListTile(
            leading: Stack(
              children: [
                const Icon(Icons.group_rounded),
                if (pendingInvitationsCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$pendingInvitationsCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            title: const Text('Groups'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const GroupsScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.history_rounded),
            title: const Text('Log'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ActivityLogScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.palette_rounded),
            title: const Text('Themes'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ThemesScreen()));
            },
          ),
        ],
      ),
    );
  }
}

// --- Groups Screen ---
class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  @override
  Widget build(BuildContext context) {
    final pendingInvitations = AppData.groupInvitations
        .where((inv) => inv.status == GroupInvitationStatus.pending)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Groups'),
        actions: [
          if (pendingInvitations.isNotEmpty)
            IconButton(
              icon: Stack(
                children: [
                  const Icon(Icons.mail_outline_rounded),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${pendingInvitations.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GroupInvitationsScreen(),
                  ),
                ).then((_) => setState(() {}));
              },
              tooltip: 'Invitations',
            ),
        ],
      ),
      body: AppData.groups.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group_outlined,
                      size: 80,
                      color: Theme.of(context)
                          .colorScheme
                          .onBackground
                          .withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text('No groups yet',
                      style: TextStyle(
                          fontSize: 18,
                          color: Theme.of(context)
                              .colorScheme
                              .onBackground
                              .withOpacity(0.6))),
                  const SizedBox(height: 8),
                  Text('Create a group to collaborate',
                      style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context)
                              .colorScheme
                              .onBackground
                              .withOpacity(0.5))),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: AppData.groups.length,
              itemBuilder: (context, index) {
                final group = AppData.groups[index];
                final isCreator = group.creatorId == UserData.userId;
                final memberCount = group.members.length;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      child: Icon(Icons.group_rounded,
                          color: Theme.of(context).primaryColor),
                    ),
                    title: Text(group.name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('$memberCount member${memberCount != 1 ? 's' : ''}' +
                        (isCreator ? ' • Creator' : '')),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GroupDetailScreen(group: group),
                        ),
                      ).then((_) => setState(() {}));
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const CreateGroupDialog(),
          ).then((_) => setState(() {}));
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create Group'),
      ),
    );
  }
}

// --- Create Group Dialog ---
class CreateGroupDialog extends StatefulWidget {
  final Group? groupToEdit;

  const CreateGroupDialog({super.key, this.groupToEdit});

  @override
  State<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<CreateGroupDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.groupToEdit != null) {
      _nameController.text = widget.groupToEdit!.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (widget.groupToEdit != null) {
        // Edit existing group
        widget.groupToEdit!.name = _nameController.text.trim();
      } else {
        // Create new group
        final newGroup = Group(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text.trim(),
          creatorId: UserData.userId,
          members: [
            GroupMember(
              userId: UserData.userId,
              username: UserData.username,
              email: UserData.email,
              role: GroupMemberRole.editor,
            ),
          ],
        );
        AppData.groups.add(newGroup);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.groupToEdit == null ? 'Create Group' : 'Edit Group'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Group Name',
            prefixIcon: Icon(Icons.group_rounded),
          ),
          validator: (value) =>
              (value == null || value.trim().isEmpty)
                  ? 'Please enter a group name'
                  : null,
          autofocus: true,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(widget.groupToEdit == null ? 'Create' : 'Save'),
        ),
      ],
    );
  }
}

// --- Group Detail Screen ---
class GroupDetailScreen extends StatefulWidget {
  final Group group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  bool get _isCreator => widget.group.creatorId == UserData.userId;
  bool get _isEditor => _isCreator ||
      widget.group.members
          .any((m) => m.userId == UserData.userId && m.role == GroupMemberRole.editor);

  void _addMember() {
    showDialog(
      context: context,
      builder: (context) => AddMemberDialog(group: widget.group),
    ).then((_) => setState(() {}));
  }

  void _editGroupName() {
    showDialog(
      context: context,
      builder: (context) => CreateGroupDialog(groupToEdit: widget.group),
    ).then((_) => setState(() {}));
  }

  void _deleteGroup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: const Text('Are you sure you want to delete this group? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              AppData.groups.remove(widget.group);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close detail screen
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showMemberOptions(GroupMember member) {
    if (!_isEditor || member.userId == UserData.userId) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                member.role == GroupMemberRole.editor
                    ? Icons.visibility_rounded
                    : Icons.edit_rounded,
              ),
              title: Text(member.role == GroupMemberRole.editor
                  ? 'Make Viewer'
                  : 'Make Editor'),
              onTap: () {
                setState(() {
                  final index = widget.group.members
                      .indexWhere((m) => m.userId == member.userId);
                  if (index != -1) {
                    widget.group.members[index] = GroupMember(
                      userId: member.userId,
                      username: member.username,
                      email: member.email,
                      role: member.role == GroupMemberRole.editor
                          ? GroupMemberRole.viewer
                          : GroupMemberRole.editor,
                    );
                  }
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_remove_rounded, color: Colors.red),
              title: const Text('Remove from Group',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                setState(() {
                  widget.group.members
                      .removeWhere((m) => m.userId == member.userId);
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.name),
        actions: [
          if (_isEditor)
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_rounded),
                      SizedBox(width: 12),
                      Text('Edit Name'),
                    ],
                  ),
                ),
                if (_isCreator)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_rounded, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Delete Group', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  _editGroupName();
                } else if (value == 'delete') {
                  _deleteGroup();
                }
              },
            ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: widget.group.members.length,
        itemBuilder: (context, index) {
          final member = widget.group.members[index];
          final isCurrentUser = member.userId == UserData.userId;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                child: Text(
                  member.username.isNotEmpty
                      ? member.username[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                member.username + (isCurrentUser ? ' (You)' : ''),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(member.email),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: member.role == GroupMemberRole.editor
                          ? Theme.of(context).primaryColor.withOpacity(0.1)
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: member.role == GroupMemberRole.editor
                            ? Theme.of(context).primaryColor
                            : Theme.of(context).dividerColor,
                      ),
                    ),
                    child: Text(
                      member.role == GroupMemberRole.editor ? 'Editor' : 'Viewer',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: member.role == GroupMemberRole.editor
                            ? Theme.of(context).primaryColor
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (_isEditor && !isCurrentUser)
                    IconButton(
                      icon: const Icon(Icons.more_vert_rounded),
                      onPressed: () => _showMemberOptions(member),
                    ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: _isEditor
          ? FloatingActionButton.extended(
              onPressed: _addMember,
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Add Member'),
            )
          : null,
    );
  }
}

// --- Add Member Dialog ---
class AddMemberDialog extends StatefulWidget {
  final Group group;

  const AddMemberDialog({super.key, required this.group});

  @override
  State<AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<AddMemberDialog> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  bool _addByEmail = false;
  GroupMemberRole _selectedRole = GroupMemberRole.viewer;

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // Create invitation
      final invitation = GroupInvitation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        groupId: widget.group.id,
        groupName: widget.group.name,
        invitedByUsername: UserData.username,
        invitedByUserId: UserData.userId,
        role: _selectedRole,
        status: GroupInvitationStatus.pending,
      );
      AppData.groupInvitations.add(invitation);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invitation sent')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Member'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Username'),
                    selected: !_addByEmail,
                    onSelected: (selected) {
                      setState(() {
                        _addByEmail = false;
                        _identifierController.clear();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Email'),
                    selected: _addByEmail,
                    onSelected: (selected) {
                      setState(() {
                        _addByEmail = true;
                        _identifierController.clear();
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _identifierController,
              decoration: InputDecoration(
                labelText: _addByEmail ? 'Email Address' : 'Username',
                prefixIcon: Icon(_addByEmail
                    ? Icons.email_outlined
                    : Icons.person_outline),
              ),
              keyboardType: _addByEmail
                  ? TextInputType.emailAddress
                  : TextInputType.text,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a ${_addByEmail ? 'email' : 'username'}';
                }
                if (_addByEmail && !value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
              autofocus: true,
            ),
            const SizedBox(height: 16),
            const Text('Role',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Viewer'),
                    selected: _selectedRole == GroupMemberRole.viewer,
                    onSelected: (selected) {
                      setState(() => _selectedRole = GroupMemberRole.viewer);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Editor'),
                    selected: _selectedRole == GroupMemberRole.editor,
                    onSelected: (selected) {
                      setState(() => _selectedRole = GroupMemberRole.editor);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Send Invitation'),
        ),
      ],
    );
  }
}

// --- Group Invitations Screen ---
class GroupInvitationsScreen extends StatefulWidget {
  const GroupInvitationsScreen({super.key});

  @override
  State<GroupInvitationsScreen> createState() => _GroupInvitationsScreenState();
}

class _GroupInvitationsScreenState extends State<GroupInvitationsScreen> {
  void _acceptInvitation(GroupInvitation invitation) {
    setState(() {
      invitation.status = GroupInvitationStatus.accepted;
      final group = AppData.groups.firstWhere(
        (g) => g.id == invitation.groupId,
        orElse: () {
          final newGroup = Group(
            id: invitation.groupId,
            name: invitation.groupName,
            creatorId: invitation.invitedByUserId,
            members: [],
          );
          AppData.groups.add(newGroup);
          return newGroup;
        },
      );
      group.members.add(GroupMember(
        userId: UserData.userId,
        username: UserData.username,
        email: UserData.email,
        role: invitation.role,
      ));
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invitation accepted')),
    );
  }

  void _rejectInvitation(GroupInvitation invitation) {
    setState(() {
      invitation.status = GroupInvitationStatus.rejected;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invitation rejected')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingInvitations = AppData.groupInvitations
        .where((inv) => inv.status == GroupInvitationStatus.pending)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Invitations'),
      ),
      body: pendingInvitations.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mail_outline_rounded,
                      size: 80,
                      color: Theme.of(context)
                          .colorScheme
                          .onBackground
                          .withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text('No pending invitations',
                      style: TextStyle(
                          fontSize: 18,
                          color: Theme.of(context)
                              .colorScheme
                              .onBackground
                              .withOpacity(0.6))),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: pendingInvitations.length,
              itemBuilder: (context, index) {
                final invitation = pendingInvitations[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(invitation.groupName,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(
                          'Invited by ${invitation.invitedByUsername}',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Role: ${invitation.role == GroupMemberRole.editor ? 'Editor' : 'Viewer'}',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => _rejectInvitation(invitation),
                              child: const Text('Reject'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => _acceptInvitation(invitation),
                              child: const Text('Accept'),
                            ),
                          ],
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

// --- Activity Log Screen ---
class ActivityLogScreen extends StatelessWidget {
  const ActivityLogScreen({super.key});

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  IconData _getActionIcon(String action) {
    switch (action.toLowerCase()) {
      case 'created':
        return Icons.add_circle_rounded;
      case 'completed':
        return Icons.check_circle_rounded;
      case 'uncompleted':
        return Icons.radio_button_unchecked_rounded;
      case 'edited':
        return Icons.edit_rounded;
      case 'deleted':
        return Icons.delete_rounded;
      case 'shared':
        return Icons.share_rounded;
      default:
        return Icons.circle_rounded;
    }
  }

  Color _getActionColor(String action, BuildContext context) {
    switch (action.toLowerCase()) {
      case 'created':
        return AppThemes.themes['forest']!['primary']!;
      case 'completed':
        return AppThemes.themes['forest']!['accent']!;
      case 'uncompleted':
        return Theme.of(context).colorScheme.onSurface.withOpacity(0.5);
      case 'edited':
        return AppThemes.themes['defaultBlue']!['primary']!;
      case 'deleted':
        return AppThemes.themes['sunrise']!['accent']!;
      case 'shared':
        return AppThemes.themes['purple']!['primary']!;
      default:
        return Theme.of(context).primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final logs = AppData.activityLogs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Log'),
        actions: [
          if (logs.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear Log'),
                    content: const Text('Are you sure you want to clear all activity logs?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          AppData.activityLogs.clear();
                          Navigator.pop(context);
                          // Force refresh by popping and pushing again
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ActivityLogScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );
              },
              tooltip: 'Clear all logs',
            ),
        ],
      ),
      body: logs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded,
                      size: 80,
                      color: Theme.of(context)
                          .colorScheme
                          .onBackground
                          .withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text('No activity yet',
                      style: TextStyle(
                          fontSize: 18,
                          color: Theme.of(context)
                              .colorScheme
                              .onBackground
                              .withOpacity(0.6))),
                  const SizedBox(height: 8),
                  Text('Your task activity will appear here',
                      style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context)
                              .colorScheme
                              .onBackground
                              .withOpacity(0.5))),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                final actionColor = _getActionColor(log.action, context);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: actionColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getActionIcon(log.action),
                        color: actionColor,
                        size: 20,
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          log.action,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: actionColor,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            log.taskTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        if (log.details != null && log.details!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              log.details!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.6),
                              ),
                            ),
                          ),
                        Text(
                          _formatTimestamp(log.timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                    isThreeLine: log.details != null && log.details!.isNotEmpty,
                  ),
                );
              },
            ),
    );
  }
}

// --- Share Task Dialog ---
class ShareTaskDialog extends StatefulWidget {
  final Task task;

  const ShareTaskDialog({super.key, required this.task});

  @override
  State<ShareTaskDialog> createState() => _ShareTaskDialogState();
}

class _ShareTaskDialogState extends State<ShareTaskDialog> {
  final List<String> _selectedUserIds = [];

  @override
  void initState() {
    super.initState();
    _selectedUserIds.addAll(widget.task.sharedWithUserIds);
  }

  List<GroupMember> _getAllGroupMembers() {
    final Set<String> addedUserIds = {};
    final List<GroupMember> allMembers = [];

    for (var group in AppData.groups) {
      for (var member in group.members) {
        if (member.userId != UserData.userId && !addedUserIds.contains(member.userId)) {
          addedUserIds.add(member.userId);
          allMembers.add(member);
        }
      }
    }

    return allMembers;
  }

  void _toggleUser(String userId) {
    setState(() {
      if (_selectedUserIds.contains(userId)) {
        _selectedUserIds.remove(userId);
      } else {
        if (_selectedUserIds.length < 3) {
          _selectedUserIds.add(userId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maximum 3 people can be shared with')),
          );
        }
      }
    });
  }

  void _submit() {
    final previousCount = widget.task.sharedWithUserIds.length;
    widget.task.sharedWithUserIds.clear();
    widget.task.sharedWithUserIds.addAll(_selectedUserIds);
    final newCount = widget.task.sharedWithUserIds.length;
    
    if (newCount > 0) {
      AppData.addLog(
        'Shared',
        widget.task.title,
        details: 'Shared with $newCount ${newCount == 1 ? 'person' : 'people'}',
      );
    } else if (previousCount > 0) {
      AppData.addLog(
        'Unshared',
        widget.task.title,
        details: 'Removed all sharing',
      );
    }
    
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task sharing updated')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allMembers = _getAllGroupMembers();

    return AlertDialog(
      title: const Text('Share Task'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select up to 3 people from your groups',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 16),
            if (allMembers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'No group members available.\nAdd people to your groups first.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.5),
                    ),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: allMembers.length,
                  itemBuilder: (context, index) {
                    final member = allMembers[index];
                    final isSelected = _selectedUserIds.contains(member.userId);

                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (value) => _toggleUser(member.userId),
                      title: Text(member.username),
                      subtitle: Text(
                        '${member.email} • ${member.role == GroupMemberRole.editor ? 'Editor' : 'Viewer'}',
                      ),
                      secondary: CircleAvatar(
                        backgroundColor:
                            Theme.of(context).primaryColor.withOpacity(0.1),
                        child: Text(
                          member.username.isNotEmpty
                              ? member.username[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
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
                      _focusedMonth =
                          DateTime(_focusedMonth.year, _focusedMonth.month - 1);
                    });
                  },
                ),
                Text(
                  '${_getMonthName(_focusedMonth.month)} ${_focusedMonth.year}',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: () {
                    setState(() {
                      _focusedMonth =
                          DateTime(_focusedMonth.year, _focusedMonth.month + 1);
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildCalendar(taskCounts),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  Widget _buildCalendar(Map<DateTime, int> taskCounts) {
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDayOfMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final firstWeekday =
        firstDayOfMonth.weekday == 7 ? 0 : firstDayOfMonth.weekday;

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
                        child: Text(day,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.6))),
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
                    final dayNumber =
                        weekIndex * 7 + dayIndex - firstWeekday + 1;
                    if (dayNumber < 1 || dayNumber > daysInMonth) {
                      return const SizedBox(width: 40, height: 50);
                    }

                    final date = DateTime(
                        _focusedMonth.year, _focusedMonth.month, dayNumber);
                    final isSelected = DateUtils.isSameDay(date, _selectedDate);
                    final isToday = DateUtils.isSameDay(date, DateTime.now());
                    final taskCount = taskCounts[date] ?? 0;

                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedDate = date);
                        widget.onDateSelected(date);
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 40,
                        height: 50,
                        decoration: BoxDecoration(
                          color:
                              isSelected ? Theme.of(context).primaryColor : null,
                          borderRadius: BorderRadius.circular(12),
                          border: isToday && !isSelected
                              ? Border.all(
                                  color: Theme.of(context).primaryColor, width: 2)
                              : null,
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Text('$dayNumber',
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : (isToday
                                            ? Theme.of(context).primaryColor
                                            : null),
                                    fontWeight: isSelected || isToday
                                        ? FontWeight.bold
                                        : null,
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
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 1),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.white
                                            : Theme.of(context).primaryColor,
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
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
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

  @override
  void initState() {
    super.initState();
    _usernameController.text = UserData.username;
    _emailController.text = UserData.email;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _usernameController.text = UserData.username;
    _emailController.text = UserData.email;
  }

  void _saveChanges() {
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
                backgroundColor:
                    Theme.of(context).primaryColor.withOpacity(0.1),
                child: Icon(Icons.person_rounded,
                    size: 50, color: Theme.of(context).primaryColor),
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

// --- Gantt Chart Screen ---
class GanttChartScreen extends StatefulWidget {
  final List<Task> tasks;

  const GanttChartScreen({super.key, required this.tasks});

  @override
  State<GanttChartScreen> createState() => _GanttChartScreenState();
}

class _GanttChartScreenState extends State<GanttChartScreen> {
  String _viewMode = 'daily';
  final ScrollController _headerScrollController = ScrollController();
  final ScrollController _bodyScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _headerScrollController.addListener(() {
      if (_headerScrollController.offset != _bodyScrollController.offset) {
        _bodyScrollController.jumpTo(_headerScrollController.offset);
      }
    });
    _bodyScrollController.addListener(() {
      if (_bodyScrollController.offset != _headerScrollController.offset) {
        _headerScrollController.jumpTo(_bodyScrollController.offset);
      }
    });
  }

  @override
  void dispose() {
    _headerScrollController.dispose();
    _bodyScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gantt Chart'),
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

  Widget _buildHorizontalGantt() {
    final sortedTasks = List<Task>.from(widget.tasks)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    if (sortedTasks.isEmpty) {
      return const Center(child: Text('No tasks to display'));
    }

    final earliest = sortedTasks.first.startDate;
    final latest = sortedTasks
        .map((t) => t.endDate)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    
    DateTime chartEndDate;
    switch (_viewMode) {
      case 'weekly':
        chartEndDate = latest.add(const Duration(days: 35));
        break;
      case 'monthly':
        chartEndDate = latest.add(const Duration(days: 90));
        break;
      case 'daily':
      default:
        chartEndDate = latest.add(const Duration(days: 7));
        break;
    }
    final totalDays = chartEndDate.difference(earliest).inDays + 1;

    double dayWidth;
    int headerInterval;
    String Function(DateTime) getHeaderLabel;
    String Function(DateTime) getSubHeaderLabel;

    switch (_viewMode) {
      case 'weekly':
        dayWidth = 25.0;
        headerInterval = 7;
        getHeaderLabel = (date) {
           final weekNum = (date.difference(earliest).inDays / 7).floor() + 1;
           return 'Week $weekNum';
        };
        getSubHeaderLabel = (date) => 'W ${ (date.day / 7).ceil()}';
        break;
      case 'monthly':
        dayWidth = 10.0;
        headerInterval = 1;
        getHeaderLabel = (date) => '${_getMonthName(date.month)} ${date.year}';
        getSubHeaderLabel = (date) => '';
        break;
      case 'daily':
      default:
        dayWidth = 70.0;
        headerInterval = 1;
        getHeaderLabel = (date) => _getMonthName(date.month).substring(0, 3);
        getSubHeaderLabel = (date) => date.day.toString();
        break;
    }

    final double barHeight = 44.0;
    final double totalWidth = totalDays * dayWidth;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTimelineHeader(
            earliest, totalDays, dayWidth, headerInterval,
            getHeaderLabel, getSubHeaderLabel
          ),
          Container(
            width: totalWidth,
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: CustomPaint(
              painter: _GridPainter(
                dayWidth: dayWidth,
                totalDays: totalDays,
                headerInterval: _viewMode == 'monthly' ? 30 : headerInterval,
                gridColor: Theme.of(context).dividerColor.withOpacity(0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: sortedTasks.map((task) {
                  final startOffsetDays =
                      task.startDate.difference(earliest).inDays;
                  final barWidth =
                      task.durationInDays * dayWidth - 4; 
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
                      boxShadow: [
                         BoxShadow(
                           color: color.withOpacity(0.2),
                           blurRadius: 8,
                           offset: const Offset(0, 4)
                         )
                      ]
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineHeader(
    DateTime earliest, int totalDays, double dayWidth, int interval,
    String Function(DateTime) getLabel, String Function(DateTime) getSubLabel,
  ) {
    List<Widget> headers = [];
    DateTime currentDate = earliest;

    if (_viewMode == 'monthly') {
      for(int i = 0; i < totalDays; i++) {
        if (i == 0 || currentDate.day == 1) {
          final daysInMonth = DateUtils.getDaysInMonth(currentDate.year, currentDate.month);
          final daysRemainingInMonth = (i == 0) ? daysInMonth - currentDate.day + 1 : daysInMonth;
          final cellWidth = daysRemainingInMonth * dayWidth;

          headers.add(
            Container(
              width: cellWidth,
              height: 50,
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: Theme.of(context).dividerColor, width: 1),
                  bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
                ),
              ),
              child: Center(
                child: Text(
                  '${_getMonthName(currentDate.month).substring(0,3)} ${currentDate.year}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          );
          i += daysRemainingInMonth - 1;
          currentDate = currentDate.add(Duration(days: daysRemainingInMonth));
        } else {
          currentDate = currentDate.add(const Duration(days: 1));
        }
      }
    } else {
       for (int i = 0; i < totalDays; i += interval) {
          final cellWidth = interval * dayWidth;
          headers.add(
            Container(
              width: cellWidth,
              height: 50,
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: Theme.of(context).dividerColor, width: 1),
                  bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
                ),
              ),
              child: Center(
                child: _viewMode == 'daily' ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     Text(
                      getSubLabel(currentDate),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      getLabel(currentDate),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ) : Text(
                  getLabel(currentDate),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          );
          currentDate = currentDate.add(Duration(days: interval));
       }
    }

    return SingleChildScrollView(
      controller: _headerScrollController,
      scrollDirection: Axis.horizontal,
      child: Row(children: headers),
    );
  }

  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.high:
        return AppThemes.themes['sunrise']!['accent']!;
      case Priority.medium:
        return AppThemes.themes['sunrise']!['primary']!;
      case Priority.low:
        return AppThemes.themes['ocean']!['accent']!;
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}

class _GridPainter extends CustomPainter {
  final double dayWidth;
  final int totalDays;
  final int headerInterval;
  final Color gridColor;

  _GridPainter({
    required this.dayWidth,
    required this.totalDays,
    required this.headerInterval,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0;

    for (int i = 0; i <= totalDays; i += headerInterval) {
      final x = i * dayWidth;
      if (x > size.width) break;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

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
            AppThemes.themes[AppThemes.defaultBlue]!['primary']!,
          ),
           _buildThemeOption(
            context,
            'Sunrise',
            AppThemes.sunrise,
            AppThemes.themes[AppThemes.sunrise]!['primary']!,
          ),
           _buildThemeOption(
            context,
            'Forest',
            AppThemes.forest,
            AppThemes.themes[AppThemes.forest]!['primary']!,
          ),
           _buildThemeOption(
            context,
            'Ocean',
            AppThemes.ocean,
            AppThemes.themes[AppThemes.ocean]!['primary']!,
          ),
          _buildThemeOption(
            context,
            'Purple Dream',
            AppThemes.purple,
            AppThemes.themes[AppThemes.purple]!['primary']!,
          ),
          _buildThemeOption(
            context,
            'Cherry Pink',
            AppThemes.pink,
            AppThemes.themes[AppThemes.pink]!['primary']!,
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
        final colors = AppThemes.themes[themeKey]!;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: isSelected
                ? Border.all(color: color, width: 3)
                : Border.all(
                    color: Theme.of(context).dividerColor, width: 1),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colors['primary']!, colors['gradientEnd']!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  ),
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
        return AppThemes.themes['sunrise']!['accent']!;
      case Priority.medium:
        return AppThemes.themes['sunrise']!['primary']!;
      case Priority.low:
        return AppThemes.themes['ocean']!['accent']!;
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
                        color: task.isDone
                            ? priorityColor
                            : priorityColor.withOpacity(0.5),
                        width: 2.5,
                      ),
                      color: task.isDone ? priorityColor : Colors.transparent,
                    ),
                    child: task.isDone
                        ? const Icon(Icons.check_rounded,
                            size: 18, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              task.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: task.isDone
                                    ? Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.5)
                                    : Theme.of(context).colorScheme.onSurface,
                                decoration:
                                    task.isDone ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ),
                          if (task.sharedWithUserIds.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Icon(
                                Icons.people_rounded,
                                size: 16,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.5),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (!task.isAllDay || task.startTime != null) ...[
                            Icon(Icons.access_time_rounded,
                                size: 14,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.5)),
                            const SizedBox(width: 4),
                            Text(_formatTime(context),
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.6))),
                          ],
                          if (_formatDuration().isNotEmpty) ...[
                            const SizedBox(width: 12),
                            Icon(Icons.calendar_today_rounded,
                                size: 14,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.5)),
                            const SizedBox(width: 4),
                            Text(_formatDuration(),
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.6))),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
  final Future<void> Function()? onDelete;

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
      _startDate = widget.defaultDate;
      _endDate = widget.defaultDate;
    }
  }

  void _submit() {
    if (_titleController.text.isEmpty) return;

    final String id =
        widget.task?.id ?? DateTime.now().millisecondsSinceEpoch.toString();

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
        sharedWithUserIds: widget.task?.sharedWithUserIds,
        notes: widget.task?.notes,
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
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = DateUtils.dateOnly(picked);
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
        return AppThemes.themes['sunrise']!['accent']!;
      case Priority.medium:
        return AppThemes.themes['sunrise']!['primary']!;
      case Priority.low:
        return AppThemes.themes['ocean']!['accent']!;
    }
  }

  void _showShareDialog() {
    if (widget.task != null) {
      showDialog(
        context: context,
        builder: (context) => ShareTaskDialog(task: widget.task!),
      ).then((_) => setState(() {}));
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
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.task != null && AppData.groups.isNotEmpty)
                      IconButton(
                        icon: Icon(
                          Icons.share_rounded,
                          color: Theme.of(context).primaryColor,
                        ),
                        onPressed: _showShareDialog,
                        tooltip: 'Share Task',
                      ),
                    if (widget.onDelete != null)
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: Colors.red),
                        onPressed: () {
                          widget.onDelete?.call();
                        },
                      ),
                  ],
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
            const Text('Priority',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
                        color: isSelected
                            ? color.withOpacity(0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? color
                              : Theme.of(context).dividerColor,
                          width: 2,
                        ),
                      ),
                      child: Text(priority.name.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? color
                                  : Theme.of(context).colorScheme.onSurface,
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
                      color: Theme.of(context).colorScheme.background,
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: Theme.of(context).dividerColor),
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
                      color: Theme.of(context).colorScheme.background,
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: Theme.of(context).dividerColor),
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
                color: Theme.of(context).colorScheme.background,
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
                        color: Theme.of(context).colorScheme.background,
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: Theme.of(context).dividerColor),
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
                        color: Theme.of(context).colorScheme.background,
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: Theme.of(context).dividerColor),
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
                  padding: const EdgeInsets.symmetric(vertical: 18)),
              child: Text(widget.task == null ? 'Create Task' : 'Update Task',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
