import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';

class DiseaseSearchAndFilter extends StatefulWidget {
  final String searchQuery;
  final String? detectionFilter;
  final List<String> speciesFilter;
  final String? severityFilter;
  final List<String> categoriesFilter;
  final bool? contagiousFilter;
  final String sortBy;
  final Function(String) onSearchChanged;
  final Function(String?) onDetectionChanged;
  final Function(List<String>) onSpeciesChanged;
  final Function(String?) onSeverityChanged;
  final Function(List<String>) onCategoriesChanged;
  final Function(bool?) onContagiousChanged;
  final Function(String) onSortChanged;
  final VoidCallback onClearFilters;
  final VoidCallback onExportCSV;

  const DiseaseSearchAndFilter({
    super.key,
    required this.searchQuery,
    required this.detectionFilter,
    required this.speciesFilter,
    required this.severityFilter,
    required this.categoriesFilter,
    required this.contagiousFilter,
    required this.sortBy,
    required this.onSearchChanged,
    required this.onDetectionChanged,
    required this.onSpeciesChanged,
    required this.onSeverityChanged,
    required this.onCategoriesChanged,
    required this.onContagiousChanged,
    required this.onSortChanged,
    required this.onClearFilters,
    required this.onExportCSV,
  });

  @override
  State<DiseaseSearchAndFilter> createState() =>
      _DiseaseSearchAndFilterState();
}

class _DiseaseSearchAndFilterState extends State<DiseaseSearchAndFilter> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _showAdvancedFilters = true; // Changed to true - show filters by default

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      widget.onSearchChanged(value);
    });
  }

  bool get _hasActiveFilters {
    return widget.detectionFilter != null ||
        widget.speciesFilter.isNotEmpty ||
        widget.severityFilter != null ||
        widget.categoriesFilter.isNotEmpty ||
        widget.contagiousFilter != null ||
        widget.searchQuery.isNotEmpty;
  }

  int get _activeFilterCount {
    int count = 0;
    if (widget.detectionFilter != null) count++;
    if (widget.speciesFilter.isNotEmpty) count++;
    if (widget.severityFilter != null) count++;
    if (widget.categoriesFilter.isNotEmpty) count++;
    if (widget.contagiousFilter != null) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar, Sort, Filters Toggle, and Export
          Row(
            children: [
              Expanded(child: _buildSearchBar()),
              const SizedBox(width: 12),
              _buildSortDropdown(),
              const SizedBox(width: 8),
              _buildFiltersToggle(),
              const SizedBox(width: 8),
              _buildExportButton(),
            ],
          ),

          // Quick Filters - Always Visible
          if (_hasActiveFilters) ...[
            const SizedBox(height: 16),
            _buildActiveFiltersChips(),
          ],

          // Advanced Filters - Collapsible
          if (_showAdvancedFilters) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            _buildAdvancedFilters(),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
      decoration: InputDecoration(
        hintText: 'Search diseases...',
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
        suffixIcon: widget.searchQuery.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear, color: Colors.grey.shade400, size: 18),
                onPressed: () {
                  _searchController.clear();
                  widget.onSearchChanged('');
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        filled: true,
        fillColor: Colors.grey.shade50,
        isDense: true,
      ),
    );
  }

  Widget _buildFiltersToggle() {
    return OutlinedButton.icon(
      onPressed: () {
        setState(() {
          _showAdvancedFilters = !_showAdvancedFilters;
        });
      },
      icon: Icon(
        _showAdvancedFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
        size: 18,
      ),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Filters'),
          if (_activeFilterCount > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              child: Center(
                child: Text(
                  '$_activeFilterCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: _showAdvancedFilters ? AppColors.primary : Colors.grey.shade700,
        side: BorderSide(
          color: _showAdvancedFilters ? AppColors.primary : Colors.grey.shade300,
          width: _showAdvancedFilters ? 2 : 1,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildSortDropdown() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButton<String>(
        value: widget.sortBy,
        underline: const SizedBox(),
        icon: Icon(Icons.sort, color: Colors.grey.shade600, size: 18),
        style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
        isDense: true,
        items: const [
          DropdownMenuItem(value: 'name_asc', child: Text('A-Z')),
          DropdownMenuItem(value: 'name_desc', child: Text('Z-A')),
          DropdownMenuItem(value: 'date_added', child: Text('Newest')),
          DropdownMenuItem(value: 'date_updated', child: Text('Updated')),
          DropdownMenuItem(value: 'most_viewed', child: Text('Popular')),
          DropdownMenuItem(value: 'severity', child: Text('Severity')),
        ],
        onChanged: (value) {
          if (value != null) widget.onSortChanged(value);
        },
      ),
    );
  }

  Widget _buildExportButton() {
    return IconButton(
      onPressed: widget.onExportCSV,
      icon: const Icon(Icons.file_download_outlined),
      tooltip: 'Export to CSV',
      style: IconButton.styleFrom(
        foregroundColor: Colors.grey.shade700,
        side: BorderSide(color: Colors.grey.shade300),
        padding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildActiveFiltersChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (widget.detectionFilter != null)
          _buildActiveChip(
            label: widget.detectionFilter == 'ai' ? '✨ AI-Detectable' : 'ℹ️ Info Only',
            onRemove: () => widget.onDetectionChanged(null),
          ),
        ...widget.speciesFilter.map((species) => _buildActiveChip(
              label: species == 'cats' ? '🐱 Cats' : '🐶 Dogs',
              onRemove: () {
                final newList = List<String>.from(widget.speciesFilter);
                newList.remove(species);
                widget.onSpeciesChanged(newList);
              },
            )),
        if (widget.severityFilter != null)
          _buildActiveChip(
            label: '${widget.severityFilter![0].toUpperCase()}${widget.severityFilter!.substring(1)}',
            onRemove: () => widget.onSeverityChanged(null),
          ),
        ...widget.categoriesFilter.map((category) => _buildActiveChip(
              label: category,
              onRemove: () {
                final newList = List<String>.from(widget.categoriesFilter);
                newList.remove(category);
                widget.onCategoriesChanged(newList);
              },
            )),
        if (widget.contagiousFilter != null)
          _buildActiveChip(
            label: widget.contagiousFilter! ? '⚠️ Contagious' : '✓ Non-Contagious',
            onRemove: () => widget.onContagiousChanged(null),
          ),
        if (_activeFilterCount > 1)
          TextButton.icon(
            onPressed: widget.onClearFilters,
            icon: const Icon(Icons.clear_all, size: 16),
            label: const Text('Clear All'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade600,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: const TextStyle(fontSize: 13),
            ),
          ),
      ],
    );
  }

  Widget _buildActiveChip({
    required String label,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(10),
            child: const Icon(
              Icons.close,
              size: 16,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Detection & Species Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildCompactFilterSection(
                'Detection Method',
                _buildDetectionFilter(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildCompactFilterSection(
                'Species',
                _buildSpeciesFilter(),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Severity & Contagious Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildCompactFilterSection(
                'Severity',
                _buildSeverityFilter(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildCompactFilterSection(
                'Contagious',
                _buildContagiousFilter(),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Categories - Full Width
        _buildCompactFilterSection(
          'Categories',
          _buildCategoriesFilter(),
        ),
      ],
    );
  }

  Widget _buildCompactFilterSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildDetectionFilter() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildCompactChip(
          label: '✨ AI',
          isSelected: widget.detectionFilter == 'ai',
          onTap: () => widget.onDetectionChanged(
            widget.detectionFilter == 'ai' ? null : 'ai',
          ),
        ),
        _buildCompactChip(
          label: 'ℹ️ Info',
          isSelected: widget.detectionFilter == 'info',
          onTap: () => widget.onDetectionChanged(
            widget.detectionFilter == 'info' ? null : 'info',
          ),
        ),
      ],
    );
  }

  Widget _buildSpeciesFilter() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildCompactChip(
          label: '🐱 Cats',
          isSelected: widget.speciesFilter.contains('cats'),
          onTap: () {
            final newList = List<String>.from(widget.speciesFilter);
            if (newList.contains('cats')) {
              newList.remove('cats');
            } else {
              newList.add('cats');
            }
            widget.onSpeciesChanged(newList);
          },
        ),
        _buildCompactChip(
          label: '🐶 Dogs',
          isSelected: widget.speciesFilter.contains('dogs'),
          onTap: () {
            final newList = List<String>.from(widget.speciesFilter);
            if (newList.contains('dogs')) {
              newList.remove('dogs');
            } else {
              newList.add('dogs');
            }
            widget.onSpeciesChanged(newList);
          },
        ),
      ],
    );
  }

  Widget _buildSeverityFilter() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildCompactChip(
          label: 'Mild',
          isSelected: widget.severityFilter == 'mild',
          color: const Color(0xFF10B981),
          onTap: () => widget.onSeverityChanged(
            widget.severityFilter == 'mild' ? null : 'mild',
          ),
        ),
        _buildCompactChip(
          label: 'Moderate',
          isSelected: widget.severityFilter == 'moderate',
          color: const Color(0xFFFF9500),
          onTap: () => widget.onSeverityChanged(
            widget.severityFilter == 'moderate' ? null : 'moderate',
          ),
        ),
        _buildCompactChip(
          label: 'Severe',
          isSelected: widget.severityFilter == 'severe',
          color: const Color(0xFFEF4444),
          onTap: () => widget.onSeverityChanged(
            widget.severityFilter == 'severe' ? null : 'severe',
          ),
        ),
        _buildCompactChip(
          label: 'Varies',
          isSelected: widget.severityFilter == 'varies',
          color: Colors.grey.shade600,
          onTap: () => widget.onSeverityChanged(
            widget.severityFilter == 'varies' ? null : 'varies',
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesFilter() {
    final categories = [
      'Allergic',
      'Bacterial',
      'Fungal',
      'Parasitic',
      'Hormonal',
      'Other',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((category) {
        final isSelected = widget.categoriesFilter.contains(category);
        return _buildCompactChip(
          label: category,
          isSelected: isSelected,
          onTap: () {
            final newList = List<String>.from(widget.categoriesFilter);
            if (isSelected) {
              newList.remove(category);
            } else {
              newList.add(category);
            }
            widget.onCategoriesChanged(newList);
          },
        );
      }).toList(),
    );
  }

  Widget _buildContagiousFilter() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildCompactChip(
          label: '⚠️ Yes',
          isSelected: widget.contagiousFilter == true,
          color: const Color(0xFFEF4444),
          onTap: () => widget.onContagiousChanged(
            widget.contagiousFilter == true ? null : true,
          ),
        ),
        _buildCompactChip(
          label: '✓ No',
          isSelected: widget.contagiousFilter == false,
          color: const Color(0xFF10B981),
          onTap: () => widget.onContagiousChanged(
            widget.contagiousFilter == false ? null : false,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactChip({
    required String label,
    required bool isSelected,
    Color? color,
    required VoidCallback onTap,
  }) {
    final chipColor = color ?? AppColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? chipColor.withOpacity(0.1) : Colors.grey.shade50,
          border: Border.all(
            color: isSelected ? chipColor : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? chipColor : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}
