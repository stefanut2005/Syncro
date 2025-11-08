import 'package:flutter/material.dart';

void main() {
  runApp(const TaskManagerApp());
}

class TaskManagerApp extends StatelessWidget {
  const TaskManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.dark,
        // Define a modern, clean text theme
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 32.0, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w600),
          bodyMedium: TextStyle(fontSize: 14.0),
        ),
        // Style for input fields
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          filled: true,
          fillColor: Colors.grey.shade800.withOpacity(0.5),
        ),
        // Style for buttons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      // Use named routes for navigation
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
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
      // TODO: Add actual login logic here
      print('Logging in...');
      // Navigate to home page on successful login
      // We use pushReplacementNamed to prevent user from going back to login screen
      Navigator.pushReplacementNamed(context, '/home');
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
                          color: Colors.grey.shade400,
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
      // TODO: Add actual registration logic here
      print('Registering user...');
      // After registration, pop back to the login screen
      Navigator.pop(context);
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
                          color: Colors.grey.shade400,
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

  Task({
    required this.id,
    required this.title,
    this.isDone = false,
    required this.priority,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Mock data for tasks
  final List<Task> _tasks = [
    Task(id: '1', title: 'Finish Flutter UI', priority: Priority.high),
    Task(id: '2', title: 'Buy groceries', priority: Priority.medium),
    Task(id: '3', title: 'Go for a run', isDone: true, priority: Priority.low),
    Task(id: '4', title: 'Call mom', priority: Priority.medium),
    Task(id: '5', title: 'Prepare presentation', priority: Priority.high),
    Task(id: '6', title: 'Read a book', priority: Priority.low),
  ];

  void _addTask() {
    // This would typically show a dialog or modal bottom sheet
    // For simplicity, we'll just add a new mock task
    showModalBottomSheet(
      context: context,
      builder: (ctx) => AddTaskSheet(onAddTask: (title, priority) {
        setState(() {
          _tasks.add(Task(
            id: DateTime.now().toString(),
            title: title,
            priority: priority,
          ));
        });
        Navigator.pop(context);
      }),
      isScrollControlled: true,
    );
    print("Add task button pressed");
  }

  void _toggleTaskStatus(Task task) {
    setState(() {
      task.isDone = !task.isDone;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use DefaultTabController to manage the two tabs
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Task Manager'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                // Log out and return to login screen
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Daily Tasks', icon: Icon(Icons.today)),
              Tab(text: 'Priority Overview', icon: Icon(Icons.flag)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // --- Tab 1: Daily Tasks ---
            _buildDailyTasksView(),
            // --- Tab 2: Priority Overview ---
            _buildPriorityOverviewView(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addTask,
          tooltip: 'Add Task',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  // Widget for the "Daily Tasks" tab (a simple list of all tasks)
  Widget _buildDailyTasksView() {
    if (_tasks.isEmpty) {
      return const Center(
        child: Text("No tasks yet. Add one!"),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _tasks.length,
      itemBuilder: (context, index) {
        final task = _tasks[index];
        return TaskCard(
          task: task,
          onToggle: () => _toggleTaskStatus(task),
        );
      },
    );
  }

  // Widget for the "Priority Overview" tab (tasks grouped by priority)
  Widget _buildPriorityOverviewView() {
    final highPriorityTasks =
        _tasks.where((t) => t.priority == Priority.high).toList();
    final mediumPriorityTasks =
        _tasks.where((t) => t.priority == Priority.medium).toList();
    final lowPriorityTasks =
        _tasks.where((t) => t.priority == Priority.low).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPrioritySection('High', highPriorityTasks, Colors.redAccent),
          const SizedBox(height: 24),
          _buildPrioritySection(
              'Medium', mediumPriorityTasks, Colors.orangeAccent),
          const SizedBox(height: 24),
          _buildPrioritySection(
              'Low', lowPriorityTasks, Colors.greenAccent),
        ],
      ),
    );
  }

  // Helper widget to build a section for the priority view
  Widget _buildPrioritySection(
      String title, List<Task> tasks, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.flag, color: color),
            const SizedBox(width: 8),
            Text(
              '$title Priority',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (tasks.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
            child: Text('No tasks in this priority.'),
          )
        else
          ...tasks.map((task) => TaskCard(
                task: task,
                onToggle: () => _toggleTaskStatus(task),
              )).toList(),
      ],
    );
  }
}

// A reusable card widget to display a single task
class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;

  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color: _getPriorityColor(task.priority),
          width: 1.5,
        ),
      ),
      child: CheckboxListTile(
        value: task.isDone,
        onChanged: (bool? value) {
          onToggle();
        },
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isDone ? TextDecoration.lineThrough : null,
            color: task.isDone ? Colors.grey : null,
          ),
        ),
        secondary: Icon(
          Icons.flag,
          color: _getPriorityColor(task.priority),
        ),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }
}

// A modal sheet for adding a new task
class AddTaskSheet extends StatefulWidget {
  final Function(String title, Priority priority) onAddTask;

  const AddTaskSheet({super.key, required this.onAddTask});

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final _titleController = TextEditingController();
  Priority _selectedPriority = Priority.medium;

  void _submit() {
    if (_titleController.text.isEmpty) {
      return; // Don't add empty tasks
    }
    widget.onAddTask(_titleController.text, _selectedPriority);
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
          Text('Add New Task', style: Theme.of(context).textTheme.titleLarge),
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
                      child: Text(priority.name
                          .substring(0, 1)
                          .toUpperCase() + 
                          priority.name.substring(1)
                      ),
                    ))
                .toList(),
            isExpanded: true,
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _submit,
            child: const Text('Add Task'),
          ),
        ],
      ),
    );
  }
}