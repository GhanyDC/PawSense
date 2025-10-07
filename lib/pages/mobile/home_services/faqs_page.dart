import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';
import 'package:pawsense/core/utils/constants.dart';
import 'package:pawsense/core/services/clinic/clinic_list_service.dart';
import 'package:pawsense/core/services/support/faq_service.dart';
import 'package:pawsense/core/models/support/faq_item_model.dart';

class FAQsPage extends StatefulWidget {
  const FAQsPage({super.key});

  @override
  State<FAQsPage> createState() => _FAQsPageState();
}

class _FAQsPageState extends State<FAQsPage> {
  List<Map<String, dynamic>> _clinics = [];
  List<FAQItemModel> _faqs = [];
  bool _loading = true;
  bool _faqsLoading = false;
  String? _selectedClinicId;
  String _selectedCategory = 'All';
  Set<String> _expandedFAQIds = {};
  Set<String> _categories = {'All'};

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadClinics();
    await _loadFAQs();
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

  Future<void> _loadFAQs() async {
    setState(() {
      _faqsLoading = true;
    });

    try {
      final faqs = await FAQService.getPublicFAQs(clinicId: _selectedClinicId);
      
      // Extract unique categories
      final categories = {'All'};
      for (final faq in faqs) {
        if (faq.category.isNotEmpty) {
          categories.add(faq.category);
        }
      }

      setState(() {
        _faqs = faqs;
        _categories = categories;
        _faqsLoading = false;
        // Reset expanded state when FAQs change
        _expandedFAQIds.clear();
      });
    } catch (e) {
      setState(() {
        _faqsLoading = false;
      });
    }
  }

  List<FAQItemModel> get _filteredFAQs {
    if (_selectedCategory == 'All') {
      return _faqs;
    }
    return _faqs.where((faq) => faq.category == _selectedCategory).toList();
  }

  void _onClinicChanged(String? clinicId) {
    setState(() {
      _selectedClinicId = clinicId;
      _selectedCategory = 'All';
    });
    _loadFAQs();
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
      _expandedFAQIds.clear(); // Reset expanded state when category changes
    });
  }

  void _toggleFAQExpansion(String faqId) {
    setState(() {
      if (_expandedFAQIds.contains(faqId)) {
        _expandedFAQIds.remove(faqId);
      } else {
        _expandedFAQIds.add(faqId);
      }
    });
    
    // Increment view count when FAQ is expanded
    if (_expandedFAQIds.contains(faqId)) {
      FAQService.incrementViews(faqId);
    }
  }

  void _markAsHelpful(String faqId) {
    FAQService.incrementHelpfulVotes(faqId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Thank you for your feedback!'),
        duration: Duration(seconds: 2),
        backgroundColor: AppColors.success,
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
              ? _buildEmptyState()
              : _buildContent(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
            'Please check back later for FAQ information',
            style: kTextStyleRegular.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildHeader(),
        _buildFilters(),
        Expanded(
          child: _faqsLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildFAQsList(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(kMobileMarginHorizontal),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.help_outline,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: kSpacingSmall),
              Text(
                'Frequently Asked Questions',
                style: kMobileTextStyleTitle.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: kSpacingSmall),
          Text(
            'Find answers to common questions about our services',
            style: kTextStyleRegular.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: kSpacingMedium),
          _buildClinicSelector(),
        ],
      ),
    );
  }

  Widget _buildClinicSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(kSpacingSmall),
        border: Border.all(
          color: AppColors.border.withOpacity(0.2),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: kSpacingMedium),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedClinicId,
          hint: Text(
            'Select a clinic',
            style: kTextStyleRegular.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.textSecondary,
          ),
          isExpanded: true,
          style: kTextStyleRegular.copyWith(
            color: AppColors.textPrimary,
          ),
          onChanged: _onClinicChanged,
          items: [
            // Add "General" option for super admin FAQs
            DropdownMenuItem<String>(
              value: null,
              child: Row(
                children: [
                  Icon(
                    Icons.public,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: kSpacingSmall),
                  const Text('General FAQs'),
                ],
              ),
            ),
            ..._clinics.map((clinic) {
              return DropdownMenuItem<String>(
                value: clinic['id'],
                child: Row(
                  children: [
                    Icon(
                      Icons.local_hospital,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: kSpacingSmall),
                    Expanded(
                      child: Text(
                        clinic['name'] ?? 'Unknown Clinic',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    if (_categories.length <= 1) return const SizedBox.shrink();

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: kSpacingSmall),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: kMobileMarginHorizontal),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories.elementAt(index);
          final isSelected = category == _selectedCategory;
          
          return Container(
            margin: const EdgeInsets.only(right: kSpacingSmall),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (_) => _onCategoryChanged(category),
              backgroundColor: AppColors.white,
              selectedColor: AppColors.primary.withOpacity(0.1),
              checkmarkColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.border.withOpacity(0.2),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFAQsList() {
    final filteredFAQs = _filteredFAQs;
    
    if (filteredFAQs.isEmpty) {
      return _buildEmptyFAQsState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(kMobileMarginHorizontal),
      itemCount: filteredFAQs.length,
      itemBuilder: (context, index) {
        final faq = filteredFAQs[index];
        return _buildFAQItem(faq, index);
      },
    );
  }

  Widget _buildEmptyFAQsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.quiz_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: kSpacingMedium),
          Text(
            'No FAQs available',
            style: kMobileTextStyleTitle.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: kSpacingSmall),
          Text(
            _selectedCategory == 'All' 
                ? 'No frequently asked questions have been added yet'
                : 'No FAQs found in the "$_selectedCategory" category',
            style: kTextStyleRegular.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(FAQItemModel faq, int index) {
    final isExpanded = _expandedFAQIds.contains(faq.id);
    
    return Container(
      margin: const EdgeInsets.only(bottom: kSpacingMedium),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(kSpacingMedium),
        border: Border.all(
          color: isExpanded 
              ? AppColors.primary.withOpacity(0.3)
              : AppColors.border.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textSecondary.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _toggleFAQExpansion(faq.id),
            borderRadius: BorderRadius.circular(kSpacingMedium),
            child: Padding(
              padding: const EdgeInsets.all(kSpacingMedium),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (faq.category.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: kSpacingSmall,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: faq.isSuperAdminFAQ 
                                      ? AppColors.info.withOpacity(0.1)
                                      : AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(kSpacingXSmall),
                                ),
                                child: Text(
                                  faq.category,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: faq.isSuperAdminFAQ 
                                        ? AppColors.info
                                        : AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: kSpacingSmall),
                            ],
                            if (faq.isSuperAdminFAQ) ...[
                              Icon(
                                Icons.public,
                                size: 14,
                                color: AppColors.info,
                              ),
                              const SizedBox(width: 4),
                            ],
                          ],
                        ),
                        if (faq.category.isNotEmpty || faq.isSuperAdminFAQ)
                          const SizedBox(height: kSpacingSmall),
                        Text(
                          faq.question,
                          style: kTextStyleLarge.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (faq.views > 0 || faq.helpfulVotes > 0) ...[
                          const SizedBox(height: kSpacingSmall),
                          Row(
                            children: [
                              if (faq.views > 0) ...[
                                Icon(
                                  Icons.visibility_outlined,
                                  size: 12,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${faq.views}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: kSpacingMedium),
                              ],
                              if (faq.helpfulVotes > 0) ...[
                                Icon(
                                  Icons.thumb_up_outlined,
                                  size: 12,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${faq.helpfulVotes}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded 
                        ? Icons.keyboard_arrow_up 
                        : Icons.keyboard_arrow_down,
                    color: AppColors.textSecondary,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(kSpacingMedium),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(kSpacingMedium),
                  bottomRight: Radius.circular(kSpacingMedium),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    faq.answer,
                    style: kTextStyleRegular.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: kSpacingMedium),
                  Row(
                    children: [
                      Text(
                        'Was this helpful?',
                        style: kTextStyleRegular.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: kSpacingMedium),
                      InkWell(
                        onTap: () => _markAsHelpful(faq.id),
                        borderRadius: BorderRadius.circular(kSpacingSmall),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: kSpacingSmall,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(kSpacingSmall),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.thumb_up_outlined,
                                size: 14,
                                color: AppColors.success,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Yes',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}