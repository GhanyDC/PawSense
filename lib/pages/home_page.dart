
/// Home page of the app. Displays a welcome message and logout button.
/// Home page widget that greets the user and provides logout functionality.
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/user_services.dart';

/// Home page widget that greets the user and provides logout functionality.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

  // Handles authentication
  final AuthService _authService = AuthService();
  // Handles user data
  final UserServices _userServices = UserServices();
  // Holds the current user's data
  UserModel? _userModel;
  // Loading state for user fetch
  bool _loading = true;

  @override
  void initState() {
    // Fetch user data on widget initialization
    super.initState();
    _fetchUser();
  }

  /// Fetches the current user's data from Firestore.
  Future<void> _fetchUser() async {
    final user = _authService.currentUser;
    if (user != null) {
      final userModel = await _userServices.getUserByUid(user.uid);
      setState(() {
        _userModel = userModel;
        _loading = false;
      });
    } else {
      setState(() {
        _loading = false;
      });
    }
  }

  /// Logs out the current user and navigates to the sign in page.
  Future<void> _logout(BuildContext context) async {
    await _authService.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/signin');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Main UI for the home page
    return Scaffold(
      appBar: AppBar(
        title: Text('Home', style: Theme.of(context).textTheme.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Center(
        child: _loading
    ? const CircularProgressIndicator()
    : _userModel != null
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Welcome to Home Page,',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                _userModel!.username,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Welcome to Home Page!',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),

      ),
    );
  }
}
