import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/news_provider.dart';

class StateFilterSheet extends StatelessWidget {
  const StateFilterSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NewsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final statesList = ['All States', ...provider.states.keys.where((s) => s != 'National / Pan-India')];
    final discomsList = ['All DISCOMs', ...provider.discoms.keys];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Regional & Utility Filters',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    provider.clearFilters();
                    Navigator.pop(context);
                  },
                  child: const Text('Reset All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Select State / Region',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0284C7)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: statesList.map((state) {
                final isSelected = provider.selectedState == state;
                return ChoiceChip(
                  label: Text(state),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      provider.setStateFilter(state);
                      Navigator.pop(context);
                    }
                  },
                );
              }).toList(),
            ),
            if (discomsList.length > 1) ...[
              const SizedBox(height: 20),
              const Text(
                'Select Specific DISCOM / Utility',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF8B5CF6)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: discomsList.map((discom) {
                  final isSelected = provider.selectedDiscom == discom;
                  return ChoiceChip(
                    label: Text(discom),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        provider.setDiscomFilter(discom);
                        Navigator.pop(context);
                      }
                    },
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
