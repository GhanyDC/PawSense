import 'package:flutter/material.dart';
import 'package:pawsense/core/models/user/user_model.dart';
import 'package:pawsense/core/guards/auth_guard.dart';
import 'package:pawsense/core/services/auth/auth_service_mobile.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import 'package:pawsense/core/widgets/user/home/profile_header.dart';
import 'package:pawsense/core/widgets/user/home/pet_info_card.dart';
import 'package:pawsense/core/widgets/user/home/health_snapshot.dart';
import 'package:pawsense/core/widgets/user/home/nearby_clinics.dart';
import 'package:pawsense/core/widgets/user/home/services_grid.dart';
import 'package:pawsense/core/widgets/user/navigation/custom_bottom_navigation.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  final AuthService _authService = AuthService();
  UserModel? _userModel;
  bool _loading = true;
  int _currentNavIndex = 0;

  // Sample data - in a real app, this would come from your backend
  final List<PetInfo> _pets = [
    PetInfo(name: 'Buddy', type: 'Dog', icon: Icons.pets),
    PetInfo(name: 'Milo', type: 'Cat', icon: Icons.pets),
  ];

  final List<HealthData> _healthData = [
    HealthData(condition: 'Manage', count: 1, color: Color(0xFFFF9500)),
    HealthData(condition: 'Ringworm', count: 3, color: Color(0xFF007AFF)),
    HealthData(condition: 'Flea Allergy Dermatitis', count: 5, color: Color(0xFF8E44AD)),
    HealthData(condition: 'Pyoderma', count: 1, color: Color(0xFFE74C3C)),
  ];

  final List<ClinicInfo> _nearByClinics = [
    ClinicInfo(name: 'Happy Paws Vet', distance: '0.8 km • (555) 012-3456', phone: '555-012-3456'),
    ClinicInfo(name: 'Downtown Animal Care', distance: '1.3 km • (555) 555-1234', phone: '555-555-1234'),
    ClinicInfo(name: 'City Vet Clinic', distance: '2.1 km • (555) 987-6543', phone: '555-987-6543'),
  ];

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    try {
      final userModel = await AuthGuard.getCurrentUser();
      if (userModel != null) {
        setState(() {
          _userModel = userModel;
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _logout() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/signin');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _loading 
          ? _buildLoadingState()
          : _userModel != null 
              ? _buildHomeContent()
              : _buildErrorState(),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      toolbarHeight: 80,
      automaticallyImplyLeading: false,
      flexibleSpace: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: kSpacingMedium),
          child: Row(
            children: [
              // Menu button
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(kBorderRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () {
                    // Handle menu
                  },
                  icon: Icon(
                    Icons.menu,
                    color: AppColors.textSecondary,
                    size: kIconSizeMedium,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
              
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.pets,
                          color: AppColors.primary,
                          size: kIconSizeMedium,
                        ),
                        SizedBox(width: kSpacingSmall),
                        Text(
                          'PawSense',
                          style: kTextStyleLarge.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'AI-powered pet skin care',
                      style: kTextStyleSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Profile button
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(kBorderRadius),
                ),
                child: IconButton(
                  onPressed: _logout,
                  icon: Icon(
                    Icons.person,
                    color: AppColors.primary,
                    size: kIconSizeMedium,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: kSpacingMedium),
          Text(
            'Unable to load user data',
            style: kTextStyleRegular.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return RefreshIndicator(
      onRefresh: _fetchUser,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Profile Header
            ProfileHeader(
              user: _userModel!,
              onManagePressed: () {
                // Handle manage profile
              },
            ),
            
            // Pet Info Card
            PetInfoCard(
              pets: _pets,
              nextAppointmentDate: 'Sep 28',
              nextAppointmentTime: '11:00',
            ),
            
            // Health Snapshot
            HealthSnapshot(
              healthData: _healthData,
            ),
            
            // Nearby Clinics
            NearbyClinics(
              clinics: _nearByClinics,
              onViewMapPressed: () {
                // Handle view map
              },
            ),
            
            // Services Grid
            ServicesGrid(
              services: _getServices(),
            ),
            
            SizedBox(height: kSpacingXLarge), // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return CustomBottomNavigation(
      currentIndex: _currentNavIndex,
      onCenterButtonPressed: () {
        // Handle camera/AI scan
        _showCameraDialog();
      },
      items: [
        CustomBottomNavItem(
          icon: Icons.home,
          label: 'Home',
          onTap: () {
            setState(() {
              _currentNavIndex = 0;
            });
          },
        ),
        CustomBottomNavItem(
          icon: Icons.access_time,
          label: 'Assess',
          onTap: () {
            setState(() {
              _currentNavIndex = 1;
            });
          },
        ),
        CustomBottomNavItem(
          icon: Icons.notifications,
          label: 'Alerts',
          onTap: () {
            setState(() {
              _currentNavIndex = 2;
            });
          },
        ),
        CustomBottomNavItem(
          icon: Icons.menu,
          label: 'Menu',
          onTap: () {
            setState(() {
              _currentNavIndex = 3;
            });
          },
        ),
      ],
    );
  }

  List<ServiceItem> _getServices() {
    return [
      ServiceItem(
        title: 'Book Appointment',
        subtitle: 'Quick access',
        icon: Icons.calendar_today,
        backgroundColor: Color(0xFF8E44AD).withValues(alpha: 0.1),
        onTap: () {
          // Handle book appointment
        },
      ),
      ServiceItem(
        title: 'Hotline',
        subtitle: 'Quick access',
        icon: Icons.phone,
        backgroundColor: Color(0xFF007AFF).withValues(alpha: 0.1),
        onTap: () {
          // Handle hotline
        },
      ),
      ServiceItem(
        title: 'First Aid Guide',
        subtitle: 'Quick access',
        icon: Icons.medical_services,
        backgroundColor: Color(0xFFFF9500).withValues(alpha: 0.1),
        onTap: () {
          // Handle first aid guide
        },
      ),
      ServiceItem(
        title: 'Pet Care Tips',
        subtitle: 'Quick access',
        icon: Icons.lightbulb_outline,
        backgroundColor: Color(0xFF34C759).withValues(alpha: 0.1),
        onTap: () {
          // Handle pet care tips
        },
      ),
    ];
  }

  void _showCameraDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(kSpacingLarge),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(kBorderRadiusLarge),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: kSpacingLarge),
            Text(
              'AI Skin Analysis',
              style: kTextStyleTitle.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: kSpacingMedium),
            Text(
              'Take a photo of your pet\'s skin condition for AI analysis',
              style: kTextStyleRegular.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: kSpacingLarge),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // Handle camera
                    },
                    icon: Icon(Icons.camera_alt),
                    label: Text('Camera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                    ),
                  ),
                ),
                SizedBox(width: kSpacingMedium),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // Handle gallery
                    },
                    icon: Icon(Icons.photo_library),
                    label: Text('Gallery'),
                  ),
                ),
              ],
            ),
            SizedBox(height: kSpacingMedium),
          ],
        ),
      ),
    );
  }
}
