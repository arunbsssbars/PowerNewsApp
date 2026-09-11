import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/news_provider.dart';

class CityFilterSheet extends StatefulWidget {
  const CityFilterSheet({super.key});

  @override
  State<CityFilterSheet> createState() => _CityFilterSheetState();
}

class _CityFilterSheetState extends State<CityFilterSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _filterQuery = '';

  final List<String> allCities = const [
    'Delhi / NCR',
    'Mumbai',
    'Bengaluru',
    'Hyderabad',
    'Chennai',
    'Kolkata',
    'Jaipur',
    'Lucknow',
    'Ahmedabad',
    'Patna',
    'Chandigarh',
    'Bhopal',
    'Bhubaneswar',
    'Pune',
    'Kochi',
    'Guwahati',
    'Varanasi',
    'Kanpur',
    'Meerut',
    'Agra',
    'Noida',
    'Indore',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NewsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final detectedCity = provider.detectedCity ?? 'Delhi / NCR';

    final filteredCities = allCities.where((c) {
      return c.toLowerCase().contains(_filterQuery.toLowerCase().trim());
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151D2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
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
          const SizedBox(height: 14),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.location_city_rounded, color: Color(0xFF2563EB), size: 20),
                ),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Select Power News City',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Local power cuts, tariffs & DISCOM updates',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                if (provider.selectedCity != 'All Cities')
                  TextButton(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: () {
                      provider.setCityFilter('All Cities');
                      Navigator.pop(context);
                    },
                    child: const Text('Reset', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0B0F19) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF2E3D59) : const Color(0xFFE2E8F0),
                ),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (val) {
                  setState(() {
                    _filterQuery = val;
                  });
                },
                style: const TextStyle(fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'Search city (e.g. Lucknow, Delhi, Mumbai)...',
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Colors.grey),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 16),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {
                              _filterQuery = '';
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Auto-Detected City Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                provider.setUserCity(detectedCity);
                provider.setCityFilter(detectedCity);
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: provider.selectedCity == detectedCity
                      ? const Color(0xFF2563EB).withOpacity(isDark ? 0.25 : 0.1)
                      : (isDark ? const Color(0xFF0B0F19) : const Color(0xFFF8FAFC)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: provider.selectedCity == detectedCity
                        ? const Color(0xFF2563EB)
                        : (isDark ? const Color(0xFF2E3D59) : const Color(0xFFE2E8F0)),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.my_location_rounded, size: 18, color: Color(0xFF2563EB)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Current Location: $detectedCity',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const Text(
                            'Auto-detected via GPS & network',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    if (provider.selectedCity == detectedCity)
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF2563EB), size: 20),
                  ],
                ),
              ),
            ),
          ),

          const Divider(height: 16),

          // City List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: filteredCities.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  final isAll = provider.selectedCity == 'All Cities';
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0B0F19) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.public_rounded, size: 18),
                    ),
                    title: const Text(
                      'All Cities (Pan-India News)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                    trailing: isAll ? const Icon(Icons.check_rounded, color: Color(0xFF2563EB)) : null,
                    onTap: () {
                      provider.setCityFilter('All Cities');
                      Navigator.pop(context);
                    },
                  );
                }

                final city = filteredCities[index - 1];
                final isSelected = provider.selectedCity == city;
                final count = provider.cities[city] ?? 0;

                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF2563EB).withOpacity(0.15)
                          : (isDark ? const Color(0xFF0B0F19) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: isSelected ? const Color(0xFF2563EB) : null,
                    ),
                  ),
                  title: Text(
                    city,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? const Color(0xFF2563EB) : null,
                      fontSize: 13.5,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (count > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2E3D59) : const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count news',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.check_rounded, color: Color(0xFF2563EB), size: 18),
                      ],
                    ],
                  ),
                  onTap: () {
                    provider.setUserCity(city);
                    provider.setCityFilter(city);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
