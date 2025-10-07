import 'package:flutter/material.dart';
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
  String? _selectedClinicId;
  int? _expandedFAQIndex;

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
        // Select first clinic by default if available
        if (_clinics.isNotEmpty) {
          _selectedClinicId = _clinics.first['id'];
        }
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getSampleFAQs(String clinicId) {
    // Sample FAQs for different clinics - you can customize these per clinic
    final baseFAQs = [
      {
        'question': 'What are your operating hours?',
        'answer': 'We are open Monday to Friday from 8:00 AM to 6:00 PM, and Saturday from 9:00 AM to 4:00 PM. We are closed on Sundays and major holidays.'
      },
      {
        'question': 'Do I need an appointment?',
        'answer': 'Yes, we highly recommend scheduling an appointment to ensure we can provide the best care for your pet. Emergency cases are always welcome and will be prioritized.'
      },
      {
        'question': 'What should I bring for my pet\'s first visit?',
        'answer': 'Please bring any previous medical records, vaccination certificates, current medications, and a list of any concerns or symptoms you\'ve noticed in your pet.'
      },
      {
        'question': 'Do you offer emergency services?',
        'answer': 'Yes, we provide emergency veterinary services. Please call us immediately if you have a pet emergency, and we will guide you on the next steps.'
      },
      {
        'question': 'What payment methods do you accept?',
        'answer': 'We accept cash, credit cards (Visa, MasterCard), debit cards, and some pet insurance plans. Payment is due at the time of service.'
      },
      {
        'question': 'How often should my pet visit the vet?',
        'answer': 'Generally, healthy adult pets should visit annually for check-ups and vaccinations. Senior pets (7+ years) may benefit from twice-yearly visits.'
      },
      {
        'question': 'Do you provide grooming services?',
        'answer': 'Yes, we offer professional pet grooming services including bathing, nail trimming, ear cleaning, and coat maintenance. Please schedule in advance.'
      },
      {
        'question': 'Can I get my pet\'s medications here?',
        'answer': 'Yes, we maintain a full pharmacy with commonly prescribed pet medications. We can also order special medications if needed.'
      },
      {
        'question': 'What if my pet is anxious about vet visits?',
        'answer': 'We understand pet anxiety and use gentle handling techniques. You can also discuss anti-anxiety options with our veterinarians before the visit.'
      },
      {
        'question': 'Do you offer vaccination packages?',
        'answer': 'Yes, we offer comprehensive vaccination packages for puppies, kittens, and adult pets. These packages are cost-effective and ensure complete protection.'
      }
    ];

    // You can customize FAQs per clinic by clinic ID here
    return baseFAQs;
  }

  Widget _buildClinicSelector() {
    if (_clinics.isEmpty) return const SizedBox();

    return Container(
      margin: const EdgeInsets.all(kSpacingMedium),
      padding: const EdgeInsets.symmetric(horizontal: kMobilePaddingMedium, vertical: kMobilePaddingSmall),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kBorderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedClinicId,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
          hint: const Text('Select a clinic'),
          items: _clinics.map((clinic) => DropdownMenuItem<String>(
            value: clinic['id'],
            child: Row(
              children: [
                Icon(Icons.local_hospital, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        clinic['name'] ?? 'Unknown Clinic',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        clinic['address'] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )).toList(),
          onChanged: (value) {
            setState(() {
              _selectedClinicId = value;
              _expandedFAQIndex = null; // Reset expanded FAQ when changing clinic
            });
          },
        ),
      ),
    );
  }

  Widget _buildFAQItem(Map<String, dynamic> faq, int index) {
    final isExpanded = _expandedFAQIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: kSpacingMedium, vertical: kSpacingSmall),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kBorderRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _expandedFAQIndex = isExpanded ? null : index;
              });
            },
            borderRadius: BorderRadius.circular(kBorderRadius),
            child: Padding(
              padding: const EdgeInsets.all(kSpacingMedium),
              child: Row(
                children: [
                  Icon(
                    Icons.help_outline,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: kSpacingSmall),
                  Expanded(
                    child: Text(
                      faq['question'],
                      style: kMobileTextStyleSubtitle.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                kSpacingMedium + 20 + kSpacingSmall,
                0,
                kSpacingMedium,
                kSpacingMedium,
              ),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(kBorderRadius),
                  bottomRight: Radius.circular(kBorderRadius),
                ),
              ),
              child: Text(
                faq['answer'],
                style: kMobileTextStyleSubtitle.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectedClinicInfo() {
    if (_selectedClinicId == null) return const SizedBox();

    final selectedClinic = _clinics.firstWhere(
      (clinic) => clinic['id'] == _selectedClinicId,
      orElse: () => {},
    );

    if (selectedClinic.isEmpty) return const SizedBox();

    return Container(
      margin: const EdgeInsets.all(kSpacingMedium),
      padding: const EdgeInsets.all(kSpacingMedium),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(kBorderRadius),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_hospital, color: AppColors.primary, size: 20),
              const SizedBox(width: kSpacingSmall),
              Expanded(
                child: Text(
                  selectedClinic['name'] ?? 'Unknown Clinic',
                  style: kMobileTextStyleSubtitle.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              if (selectedClinic['isVerified'] == true)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'VERIFIED',
                    style: kMobileTextStyleLegend.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: kSpacingSmall),
          Row(
            children: [
              Icon(Icons.location_on, color: AppColors.textSecondary, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  selectedClinic['address'] ?? '',
                  style: kMobileTextStyleLegend.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          if (selectedClinic['phone'] != null && selectedClinic['phone'].isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.phone, color: AppColors.textSecondary, size: 16),
                const SizedBox(width: 4),
                Text(
                  selectedClinic['phone'],
                  style: kMobileTextStyleLegend.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
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
          'FAQs',
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
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.local_hospital_outlined,
                        size: 64,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: kSpacingMedium),
                      Text(
                        'No clinics available',
                        style: kMobileTextStyleTitle.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: kSpacingSmall),
                      Text(
                        'Please check back later for clinic FAQs',
                        style: kMobileTextStyleSubtitle.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(kSpacingMedium),
                      color: AppColors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Frequently Asked Questions',
                            style: kMobileTextStyleTitle.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: kSpacingSmall),
                          Text(
                            'Find answers to common questions about our veterinary services',
                            style: kMobileTextStyleSubtitle.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          children: [
                            const SizedBox(height: kSpacingMedium),
                            
                            // Clinic selector
                            _buildClinicSelector(),
                            
                            // Selected clinic info
                            _buildSelectedClinicInfo(),
                            
                            // FAQs list
                            if (_selectedClinicId != null) ...[
                              const SizedBox(height: kSpacingSmall),
                              ...List.generate(_getSampleFAQs(_selectedClinicId!).length, (index) {
                                final faq = _getSampleFAQs(_selectedClinicId!)[index];
                                return _buildFAQItem(faq, index);
                              }),
                            ],
                            
                            const SizedBox(height: kSpacingLarge),
                            
                            // Help section
                            Container(
                              margin: const EdgeInsets.all(kSpacingMedium),
                              padding: const EdgeInsets.all(kSpacingMedium),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(kBorderRadius),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.contact_support,
                                    size: 32,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(height: kSpacingSmall),
                                  Text(
                                    'Still have questions?',
                                    style: kMobileTextStyleSubtitle.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: kSpacingSmall),
                                  Text(
                                    'Contact the clinic directly or use our messaging feature to get personalized answers.',
                                    style: kMobileTextStyleSubtitle.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: kSpacingLarge),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}