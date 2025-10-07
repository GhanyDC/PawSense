import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/utils/constants.dart';
import 'package:pawsense/core/services/clinic/clinic_list_service.dart';

class FAQsPage extends StatefulWidget {
  const FAQsPage({super.key});

  @override
  State<FAQsPage> createState() => _FAQsPageState();
}

class _FAQsPageState extends State<FAQsPage> {
  List<Map<String, dynamic>> _clinics = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadClinics();
  }

  Future<void> _loadClinics() async {
    try {
      final clinics = await ClinicListService.getAllActiveClinics();
      setState(() {
        _clinics = clinics;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        automaticallyImplyLeading: true,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.textPrimary,
            size: 24,
          ),
        ),
        title: const Text(
          'Help Center',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _clinics.isEmpty
              ? _buildEmptyState()
              : _buildContent(),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(kMobileMarginHorizontal),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated empty state illustration
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.textSecondary.withOpacity(0.1),
                  AppColors.primary.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.medical_services_outlined,
              size: 60,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: kSpacingLarge),
          Text(
            'No Clinics Available',
            style: kTextStyleTitle.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: kSpacingSmall),
          Text(
            'We\'re working on adding more veterinary clinics to provide you with comprehensive FAQ support.',
            style: kTextStyleRegular.copyWith(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: kSpacingLarge),
          Container(
            padding: const EdgeInsets.all(kSpacingMedium),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(kSpacingMedium),
              border: Border.all(
                color: AppColors.info.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.info,
                  size: 20,
                ),
                const SizedBox(width: kSpacingSmall),
                Expanded(
                  child: Text(
                    'Check back soon for updates!',
                    style: TextStyle(
                      color: AppColors.info,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeroSection(),
          _buildStatsSection(),
          _buildClinicsList(),
          _buildFooterSection(),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.success.withOpacity(0.05),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(kMobileMarginHorizontal),
        child: Column(
          children: [
            const SizedBox(height: kSpacingMedium),
            // Hero Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.success,
                  ],
                ),
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.help_center,
                color: AppColors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: kSpacingMedium),
            // Title
            Text(
              'Help & Support Center',
              style: kTextStyleTitle.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: kSpacingSmall),
            // Subtitle
            Text(
              'Find answers to your questions from our trusted veterinary clinics',
              style: kTextStyleRegular.copyWith(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: kSpacingLarge),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.all(kMobileMarginHorizontal),
      padding: const EdgeInsets.all(kSpacingMedium),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kSpacingMedium),
        boxShadow: [
          BoxShadow(
            color: AppColors.textSecondary.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              icon: Icons.local_hospital,
              title: '${_clinics.length}',
              subtitle: 'Clinics Available',
              color: AppColors.primary,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.border.withOpacity(0.3),
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.quiz,
              title: 'Expert',
              subtitle: 'Answers',
              color: AppColors.success,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.border.withOpacity(0.3),
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.support_agent,
              title: '24/7',
              subtitle: 'Support',
              color: AppColors.info,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: kSpacingSmall),
        Text(
          title,
          style: kTextStyleLarge.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFooterSection() {
    return Container(
      margin: const EdgeInsets.all(kMobileMarginHorizontal),
      padding: const EdgeInsets.all(kSpacingMedium),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.05),
            AppColors.success.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(kSpacingMedium),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.success,
                ],
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Icon(
              Icons.contact_support,
              color: AppColors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: kSpacingMedium),
          Text(
            'Need More Help?',
            style: kTextStyleLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: kSpacingSmall),
          Text(
            'If you can\'t find what you\'re looking for, don\'t hesitate to contact your preferred clinic directly through our messaging system.',
            style: kTextStyleRegular.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: kSpacingMedium),
          // Contact Support Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                context.push('/messaging');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: AppColors.primary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  vertical: kSpacingMedium,
                  horizontal: kSpacingLarge,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(kSpacingMedium),
                ),
              ).copyWith(
                backgroundColor: WidgetStateProperty.resolveWith<Color>(
                  (Set<WidgetState> states) {
                    if (states.contains(WidgetState.pressed)) {
                      return AppColors.primary.withOpacity(0.1);
                    }
                    return Colors.transparent;
                  },
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.success,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(kSpacingMedium),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: kSpacingMedium,
                  horizontal: kSpacingLarge,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.message,
                      color: AppColors.white,
                      size: 20,
                    ),
                    const SizedBox(width: kSpacingSmall),
                    Text(
                      'Contact Support',
                      style: kTextStyleRegular.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClinicsList() {
    return Column(
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.all(kMobileMarginHorizontal),
          child: Row(
            children: [
              Icon(
                Icons.location_city,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: kSpacingSmall),
              Text(
                'Choose Your Clinic',
                style: kTextStyleLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${_clinics.length} available',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        // Clinic Cards
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: kMobileMarginHorizontal),
          itemCount: _clinics.length,
          itemBuilder: (context, index) {
            final clinic = _clinics[index];
            return _buildClinicCard(clinic, index);
          },
        ),
      ],
    );
  }

  Widget _buildClinicCard(Map<String, dynamic> clinic, int index) {
    final clinicName = clinic['name'] ?? 'Unknown Clinic';
    final clinicAddress = clinic['address'] ?? '';
    final clinicPhone = clinic['phone'] ?? '';
    final clinicId = clinic['id'] ?? '';

    // Different gradient colors using app palette only
    final gradients = [
      [AppColors.primary, AppColors.info],
      [AppColors.success, AppColors.primary],
      [AppColors.info, AppColors.success],
      [AppColors.primary, AppColors.success],
    ];
    final gradient = gradients[index % gradients.length];

    return Container(
      margin: const EdgeInsets.only(bottom: kSpacingMedium),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kSpacingMedium),
        border: Border.all(
          color: AppColors.border.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textSecondary.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.push('/clinic-faqs?clinicId=$clinicId&clinicName=${Uri.encodeComponent(clinicName)}');
          },
          borderRadius: BorderRadius.circular(kSpacingMedium),
          child: Padding(
            padding: const EdgeInsets.all(kSpacingMedium),
            child: Row(
              children: [
                // Enhanced Clinic Icon with gradient
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        gradient[0].withOpacity(0.8),
                        gradient[1].withOpacity(0.6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(kSpacingMedium),
                    boxShadow: [
                      BoxShadow(
                        color: gradient[0].withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.local_hospital,
                    color: AppColors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: kSpacingMedium),
                // Enhanced Clinic Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clinicName,
                        style: kTextStyleLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (clinicAddress.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: gradient[0],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                clinicAddress,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                      if (clinicPhone.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.phone,
                              size: 14,
                              color: gradient[1],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              clinicPhone,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: kSpacingSmall),
                      ],
                      // Enhanced CTA Button
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: kSpacingMedium,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              gradient[0].withOpacity(0.1),
                              gradient[1].withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(kSpacingSmall),
                          border: Border.all(
                            color: gradient[0].withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.quiz,
                              size: 14,
                              color: gradient[0],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'View FAQs & Support',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: gradient[0],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Enhanced Arrow with gradient background
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        gradient[0].withOpacity(0.1),
                        gradient[1].withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: gradient[0],
                    size: 16,
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