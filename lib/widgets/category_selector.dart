import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/news_provider.dart';
import '../screens/filter_management_screen.dart';

class CategorySelector extends StatelessWidget {
  const CategorySelector({super.key});

  final List<Map<String, dynamic>> categories = const [
    {'name': 'All', 'label': 'All', 'icon': Icons.bolt_rounded},
    {'name': 'scada', 'label': 'SCADA & Comm', 'icon': Icons.settings_input_antenna_rounded},
    {'name': 'transmission', 'label': 'Grid & Transmission', 'icon': Icons.electric_bolt_rounded},
    {'name': 'renewables', 'label': 'Renewables', 'icon': Icons.solar_power_rounded},
    {'name': 'generation', 'label': 'Generation', 'icon': Icons.factory_rounded},
    {'name': 'distribution', 'label': 'DISCOMs', 'icon': Icons.power_rounded},
    {'name': 'policy', 'label': 'Policy & CERC', 'icon': Icons.gavel_rounded},
    {'name': 'tenders', 'label': 'Tenders', 'icon': Icons.assignment_turned_in_rounded},
  ];

  void _showAddCustomFilterSheet(BuildContext context, NewsProvider provider) {
    final controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final suggestions = [
      'Smart Meter',
      'Battery BESS',
      '765 kV Substation',
      'Solar Subsidy',
      'PM Surya Ghar',
      'Green Hydrogen',
      'HVDC Corridor',
      'TBCB Bidding',
      'Tariff Revision',
      'Substation GIS',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4.5,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2E3D59) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF2563EB), size: 20),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create Custom Filter',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'Filter by specific technology, tender or utility tag',
                      style: TextStyle(fontSize: 11.5, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'e.g. Smart Meter, 765kV, BESS...',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.tune_rounded, size: 18),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Quick Suggestions:',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: suggestions.map((s) {
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    provider.addCustomFilter(s);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Text(
                      '+ $s',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  final text = controller.text.trim();
                  if (text.isNotEmpty) {
                    provider.addCustomFilter(text);
                  }
                  Navigator.pop(ctx);
                },
                child: const Text('Add & Apply Filter', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.settings_rounded, size: 16),
                label: const Text('Manage Custom Filters', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FilterManagementScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NewsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final orderedCategories = List<Map<String, dynamic>>.from(categories);
    final activeCatIndex = orderedCategories.indexWhere((c) => 
        c['name'].toString().toLowerCase() == provider.selectedCategory.toLowerCase());
    
    if (activeCatIndex > 1) {
      final activeItem = orderedCategories.removeAt(activeCatIndex);
      orderedCategories.insert(1, activeItem);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Standard Category Pills
          ...orderedCategories.map((cat) {
            final isSelected = provider.selectedCategory.toLowerCase() == cat['name'].toString().toLowerCase() &&
                provider.activeCustomFilter == null;
            final count = cat['name'] == 'All'
                ? provider.totalNewsCount
                : (provider.categories[cat['name']] ?? 0);

            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    provider.setCategory(cat['name'] as String);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF2563EB)
                          : (isDark ? const Color(0xFF111827) : Colors.white),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF2563EB)
                            : (isDark ? const Color(0xFF1F2D47) : const Color(0xFFE2E8F0)),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          cat['icon'] as IconData,
                          size: 13,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB)),
                        ),
                        const SizedBox(width: 4.5),
                        Text(
                          cat['label'] as String,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E3A8A)),
                          ),
                        ),
                        if (cat['name'] != 'All') ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withOpacity(0.22)
                                  : (isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              count.toString(),
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB)),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          // User Custom Filters (with Delete option)
          ...provider.customFilters.map((customTag) {
            final isSelected = provider.activeCustomFilter == customTag;

            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    provider.setCustomFilter(customTag);
                  },
                  onLongPress: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FilterManagementScreen()),
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFD97706)
                          : (isDark ? const Color(0xFF111827) : Colors.white),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFD97706)
                            : (isDark ? const Color(0xFF1F2D47) : const Color(0xFFE2E8F0)),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.tag_rounded,
                          size: 12.5,
                          color: isSelected ? Colors.white : const Color(0xFFD97706),
                        ),
                        const SizedBox(width: 3.5),
                        Text(
                          customTag,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF334155)),
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => provider.removeCustomFilter(customTag),
                          child: Icon(
                            Icons.close_rounded,
                            size: 12,
                            color: isSelected ? Colors.white70 : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          // Plus Icon Button to Add Custom Filter
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _showAddCustomFilterSheet(context, provider),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF151D2E) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF2563EB).withOpacity(isDark ? 0.5 : 0.35),
                    width: 1,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 14, color: Color(0xFF2563EB)),
                    SizedBox(width: 3),
                    Text(
                      'Filter',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2563EB),
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
}
