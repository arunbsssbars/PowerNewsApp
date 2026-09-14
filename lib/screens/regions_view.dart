import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/news_provider.dart';
import '../theme/app_theme.dart';

class RegionsView extends StatefulWidget {
  final Function(int tabIndex)? onNavigateTab;

  const RegionsView({super.key, this.onNavigateTab});

  @override
  State<RegionsView> createState() => _RegionsViewState();
}

class _RegionsViewState extends State<RegionsView> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedGrid = 'All Grids';
  String _searchQuery = '';

  // 5 Indian National Regional Grids Mapping (POSOCO / Grid-India standard)
  static const Map<String, List<String>> regionalGridMapping = {
    'Northern Grid (NR)': [
      'Uttar Pradesh',
      'Delhi',
      'Rajasthan',
      'Punjab',
      'Haryana',
      'Uttarakhand',
      'Himachal Pradesh',
      'Jammu & Kashmir',
    ],
    'Western Grid (WR)': [
      'Maharashtra',
      'Gujarat',
      'Madhya Pradesh',
      'Chhattisgarh',
      'Goa',
    ],
    'Southern Grid (SR)': [
      'Karnataka',
      'Tamil Nadu',
      'Telangana',
      'Andhra Pradesh',
      'Kerala',
    ],
    'Eastern Grid (ER)': [
      'West Bengal',
      'Bihar',
      'Odisha',
      'Jharkhand',
    ],
    'North-Eastern Grid (NER)': [
      'Assam',
    ],
  };

  // Comprehensive Indian States & DISCOMs Directory
  static const Map<String, List<Map<String, String>>> stateDiscomDirectory = {
    'Uttar Pradesh': [
      {'code': 'PUVVNL', 'name': 'Purvanchal Vidyut (Varanasi / Prayagraj)', 'region': 'East UP'},
      {'code': 'MVVNL', 'name': 'Madhyanchal Vidyut (Lucknow / Ayodhya)', 'region': 'Central UP'},
      {'code': 'PVVNL', 'name': 'Paschimanchal Vidyut (Meerut / Noida)', 'region': 'West UP'},
      {'code': 'DVVNL', 'name': 'Dakshinanchal Vidyut (Agra / Aligarh)', 'region': 'South UP'},
      {'code': 'KESCO', 'name': 'Kanpur Electricity Supply Co.', 'region': 'Kanpur Urban'},
      {'code': 'NPCL', 'name': 'Noida Power Company Limited', 'region': 'Greater Noida'},
      {'code': 'UPPCL', 'name': 'UP Power Corp (State Grid)', 'region': 'HQ Lucknow'},
    ],
    'Delhi': [
      {'code': 'BRPL', 'name': 'BSES Rajdhani Power Limited', 'region': 'South & West Delhi'},
      {'code': 'BYPL', 'name': 'BSES Yamuna Power Limited', 'region': 'Central & East Delhi'},
      {'code': 'TPDDL', 'name': 'Tata Power Delhi Distribution', 'region': 'North Delhi'},
      {'code': 'NDMC', 'name': 'New Delhi Municipal Council', 'region': 'Lutyens Delhi'},
    ],
    'Maharashtra': [
      {'code': 'MSEDCL', 'name': 'Mahavitaran (MSEDCL)', 'region': 'State-wide'},
      {'code': 'Adani Electricity', 'name': 'Adani Electricity Mumbai (AEML)', 'region': 'Mumbai Suburbs'},
      {'code': 'Tata Power Mumbai', 'name': 'Tata Power Distribution Mumbai', 'region': 'Mumbai City'},
      {'code': 'BEST', 'name': 'BEST Undertaking Mumbai', 'region': 'Island City'},
    ],
    'Gujarat': [
      {'code': 'UGVCL', 'name': 'Uttar Gujarat Vij Company', 'region': 'North Gujarat'},
      {'code': 'DGVCL', 'name': 'Dakshin Gujarat Vij Company', 'region': 'South Gujarat / Surat'},
      {'code': 'MGVCL', 'name': 'Madhya Gujarat Vij Company', 'region': 'Central Gujarat / Vadodara'},
      {'code': 'PGVCL', 'name': 'Paschim Gujarat Vij Company', 'region': 'Saurashtra / Rajkot'},
      {'code': 'Torrent Power', 'name': 'Torrent Power (Ahmedabad / Surat)', 'region': 'Urban Franchises'},
      {'code': 'GUVNL', 'name': 'Gujarat Urja Vikas Nigam', 'region': 'State Holding'},
    ],
    'Karnataka': [
      {'code': 'BESCOM', 'name': 'Bangalore Electricity Supply', 'region': 'Bengaluru Metro'},
      {'code': 'MESCOM', 'name': 'Mangalore Electricity Supply', 'region': 'Coastal Karnataka'},
      {'code': 'HESCOM', 'name': 'Hubli Electricity Supply', 'region': 'North-West Karnataka'},
      {'code': 'GESCOM', 'name': 'Gulbarga Electricity Supply', 'region': 'North-East Karnataka'},
      {'code': 'CHESCOM', 'name': 'Chamundeshwari Electricity (CESC)', 'region': 'Mysuru / South'},
    ],
    'Tamil Nadu': [
      {'code': 'TANGEDCO', 'name': 'Tamil Nadu Gen & Dist Corp', 'region': 'State-wide'},
    ],
    'Telangana': [
      {'code': 'TSSPDCL', 'name': 'Southern Power Distribution', 'region': 'Hyderabad Metro & South'},
      {'code': 'TSNPDCL', 'name': 'Northern Power Distribution', 'region': 'Warangal & North'},
    ],
    'Andhra Pradesh': [
      {'code': 'APSPDCL', 'name': 'Southern Power Distribution AP', 'region': 'Tirupati & South'},
      {'code': 'APEPDCL', 'name': 'Eastern Power Distribution AP', 'region': 'Visakhapatnam & Coastal'},
      {'code': 'APCPDCL', 'name': 'Central Power Distribution AP', 'region': 'Vijayawada / Amaravati'},
    ],
    'Rajasthan': [
      {'code': 'JVVNL', 'name': 'Jaipur Vidyut Vitran Nigam', 'region': 'Jaipur & East'},
      {'code': 'AVVNL', 'name': 'Ajmer Vidyut Vitran Nigam', 'region': 'Ajmer & Central'},
      {'code': 'JdVVNL', 'name': 'Jodhpur Vidyut Vitran Nigam', 'region': 'Jodhpur & West'},
    ],
    'Madhya Pradesh': [
      {'code': 'MPMKVVCL', 'name': 'Madhya Kshetra (Bhopal / Gwalior)', 'region': 'Central MP'},
      {'code': 'MPPKVVCL-West', 'name': 'Paschim Kshetra (Indore / Ujjain)', 'region': 'West MP'},
      {'code': 'MPPKVVCL-East', 'name': 'Poorv Kshetra (Jabalpur / Rewa)', 'region': 'East MP'},
    ],
    'Punjab': [
      {'code': 'PSPCL', 'name': 'Punjab State Power Corporation', 'region': 'State-wide'},
    ],
    'Haryana': [
      {'code': 'DHBVN', 'name': 'Dakshin Haryana Bijli Vitran', 'region': 'Gurugram / Faridabad'},
      {'code': 'UHBVN', 'name': 'Uttar Haryana Bijli Vitran', 'region': 'Panchkula / Karnal'},
    ],
    'West Bengal': [
      {'code': 'WBSEDCL', 'name': 'West Bengal State Electricity Dist.', 'region': 'State-wide'},
      {'code': 'CESC', 'name': 'CESC Limited (Kolkata & Howrah)', 'region': 'Kolkata Metro'},
    ],
    'Bihar': [
      {'code': 'NBPDCL', 'name': 'North Bihar Power Distribution', 'region': 'North Bihar / Muzaffarpur'},
      {'code': 'SBPDCL', 'name': 'South Bihar Power Distribution', 'region': 'South Bihar / Patna'},
    ],
    'Odisha': [
      {'code': 'TPCODL', 'name': 'Tata Power Central Odisha', 'region': 'Bhubaneswar / Cuttack'},
      {'code': 'TPWODL', 'name': 'Tata Power Western Odisha', 'region': 'Sambalpur / Rourkela'},
      {'code': 'TPNODL', 'name': 'Tata Power Northern Odisha', 'region': 'Balasore / North'},
      {'code': 'TPSODL', 'name': 'Tata Power Southern Odisha', 'region': 'Berhampur / South'},
    ],
    'Kerala': [
      {'code': 'KSEB', 'name': 'Kerala State Electricity Board (KSEBL)', 'region': 'State-wide'},
    ],
    'Assam': [
      {'code': 'APDCL', 'name': 'Assam Power Distribution Company', 'region': 'Assam State-wide'},
    ],
    'Uttarakhand': [
      {'code': 'UPCL', 'name': 'Uttarakhand Power Corporation', 'region': 'State-wide / Dehradun'},
    ],
    'Himachal Pradesh': [
      {'code': 'HPSEBL', 'name': 'Himachal Pradesh State Electricity Board', 'region': 'State-wide / Shimla'},
    ],
    'Jharkhand': [
      {'code': 'JBVNL', 'name': 'Jharkhand Bijli Vitran Nigam', 'region': 'State-wide / Ranchi'},
    ],
    'Chhattisgarh': [
      {'code': 'CSPDCL', 'name': 'Chhattisgarh State Power Distribution', 'region': 'State-wide / Raipur'},
    ],
    'Jammu & Kashmir': [
      {'code': 'JPDCL', 'name': 'Jammu Power Distribution Corporation', 'region': 'Jammu Division'},
      {'code': 'KPDCL', 'name': 'Kashmir Power Distribution Corporation', 'region': 'Kashmir Division'},
    ],
    'Goa': [
      {'code': 'GED', 'name': 'Goa Electricity Department', 'region': 'Goa State-wide'},
    ],
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectStateOrDiscom(String stateName, String discomCode) {
    HapticFeedback.selectionClick();
    final provider = context.read<NewsProvider>();
    provider.setStateFilter(stateName);
    provider.setDiscomFilter(discomCode);

    // If callback is provided, invoke it
    if (widget.onNavigateTab != null) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      widget.onNavigateTab!(0);
    } else {
      provider.setNavIndex(0);
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  String _getGridForState(String state) {
    for (final entry in regionalGridMapping.entries) {
      if (entry.value.contains(state)) {
        return entry.key.split(' ').first; // NR, WR, SR, ER, NER
      }
    }
    return 'Grid';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NewsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeState = provider.selectedState;
    final activeDiscom = provider.selectedDiscom;
    final bool hasFilter = activeState != 'All States' || activeDiscom != 'All DISCOMs';

    // 1. Filter states based on Regional Grid tab and search query
    final allStates = stateDiscomDirectory.keys.toList();
    final filteredStates = allStates.where((state) {
      // Grid filter
      if (_selectedGrid != 'All Grids') {
        final allowed = regionalGridMapping[_selectedGrid] ?? [];
        if (!allowed.contains(state)) return false;
      }

      // Search query filter
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final stateMatches = state.toLowerCase().contains(q);
        final discoms = stateDiscomDirectory[state] ?? [];
        final discomMatches = discoms.any((d) =>
            (d['code'] ?? '').toLowerCase().contains(q) ||
            (d['name'] ?? '').toLowerCase().contains(q) ||
            (d['region'] ?? '').toLowerCase().contains(q));
        return stateMatches || discomMatches;
      }

      return true;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      body: Column(
        children: [
          // Top Search & Status Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0x14FFFFFF) : const Color(0x0F000000),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Input
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0D1117) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF263040) : const Color(0xFFCBD5E1),
                      width: 0.8,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search State (UP, Delhi) or DISCOM (PUVVNL, BESCOM)...',
                      hintStyle: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Regional Grid Tabs (NR, WR, SR, ER, NER)
                SizedBox(
                  height: 32,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildGridTab('All Grids', 'All (${allStates.length})', isDark),
                      _buildGridTab('Northern Grid (NR)', 'NR • North (8)', isDark),
                      _buildGridTab('Western Grid (WR)', 'WR • West (5)', isDark),
                      _buildGridTab('Southern Grid (SR)', 'SR • South (5)', isDark),
                      _buildGridTab('Eastern Grid (ER)', 'ER • East (4)', isDark),
                      _buildGridTab('North-Eastern Grid (NER)', 'NER • North East (1)', isDark),
                    ],
                  ),
                ),

                if (hasFilter) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(isDark ? 0.2 : 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFF10B981).withOpacity(0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF10B981)),
                            const SizedBox(width: 4),
                            Text(
                              activeDiscom != 'All DISCOMs'
                                  ? 'Active: $activeState > $activeDiscom'
                                  : 'Active: $activeState',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          provider.setStateFilter('All States');
                          provider.setDiscomFilter('All DISCOMs');
                        },
                        child: Text(
                          'Reset Filter',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.redAccent.shade100,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Directory States & DISCOMs List
          Expanded(
            child: filteredStates.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_off_rounded, size: 40, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                        const SizedBox(height: 12),
                        Text(
                          'No state or DISCOM matches "$_searchQuery"',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Try searching for UP, MSEDCL, Tata, or BESCOM',
                          style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    physics: const BouncingScrollPhysics(),
                    itemCount: filteredStates.length,
                    itemBuilder: (context, index) {
                      final state = filteredStates[index];
                      final discoms = stateDiscomDirectory[state] ?? [];
                      final gridTag = _getGridForState(state);
                      final stateCount = provider.states[state] ?? 0;
                      final isCurrentState = activeState == state && activeDiscom == 'All DISCOMs';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isCurrentState
                                ? const Color(0xFF2563EB)
                                : (isDark ? const Color(0x14FFFFFF) : const Color(0x0F000000)),
                            width: isCurrentState ? 1.4 : 0.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // State Header Row
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0284C7).withOpacity(isDark ? 0.25 : 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      gridTag,
                                      style: const TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0284C7),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      state,
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                      ),
                                    ),
                                  ),
                                  // "All State" button
                                  InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () => _selectStateOrDiscom(state, 'All DISCOMs'),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isCurrentState
                                            ? const Color(0xFF2563EB)
                                            : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            stateCount > 0 ? '$stateCount Briefs ➔' : 'View Feed ➔',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: isCurrentState
                                                  ? Colors.white
                                                  : (isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),

                              // DISCOMs Chips Wrap
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: discoms.map((d) {
                                  final code = d['code'] ?? '';
                                  final region = d['region'] ?? '';
                                  final isThisDiscom = activeState == state && activeDiscom == code;
                                  final discomCount = provider.discoms[code] ?? 0;

                                  return InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () => _selectStateOrDiscom(state, code),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: isThisDiscom
                                            ? const Color(0xFF7C3AED).withOpacity(isDark ? 0.3 : 0.15)
                                            : (isDark ? const Color(0xFF161E2E) : const Color(0xFFF8FAFC)),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isThisDiscom
                                              ? const Color(0xFF7C3AED)
                                              : (isDark ? const Color(0xFF263040) : const Color(0xFFE2E8F0)),
                                          width: isThisDiscom ? 1.2 : 0.8,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.electric_meter_rounded,
                                            size: 12,
                                            color: isThisDiscom
                                                ? const Color(0xFF8B5CF6)
                                                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            code,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: isThisDiscom ? FontWeight.w800 : FontWeight.w700,
                                              color: isThisDiscom
                                                  ? const Color(0xFF8B5CF6)
                                                  : (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                                            ),
                                          ),
                                          if (region.isNotEmpty) ...[
                                            const SizedBox(width: 3),
                                            Text(
                                              '($region)',
                                              style: TextStyle(
                                                fontSize: 9.5,
                                                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                              ),
                                            ),
                                          ],
                                          if (discomCount > 0) ...[
                                            const SizedBox(width: 5),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF7C3AED).withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                '$discomCount',
                                                style: const TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w800,
                                                  color: Color(0xFF8B5CF6),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridTab(String key, String label, bool isDark) {
    final isSelected = _selectedGrid == key;
    final activeColor = isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB);

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _selectedGrid = key;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withOpacity(isDark ? 0.25 : 0.12)
                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? activeColor : Colors.transparent,
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? activeColor
                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
