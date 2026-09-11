import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/news_provider.dart';
import '../widgets/news_card.dart';

class RegionsView extends StatefulWidget {
  const RegionsView({super.key});

  @override
  State<RegionsView> createState() => _RegionsViewState();
}

class _RegionsViewState extends State<RegionsView> {
  final ScrollController _scrollController = ScrollController();

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

  static const List<Map<String, String>> allStatesList = [
    {'name': 'All States', 'code': 'ALL', 'badge': '🇮🇳'},
    {'name': 'Uttar Pradesh', 'code': 'UP', 'badge': 'UP'},
    {'name': 'Delhi', 'code': 'DL', 'badge': 'DL'},
    {'name': 'Maharashtra', 'code': 'MH', 'badge': 'MH'},
    {'name': 'Gujarat', 'code': 'GJ', 'badge': 'GJ'},
    {'name': 'Karnataka', 'code': 'KA', 'badge': 'KA'},
    {'name': 'Tamil Nadu', 'code': 'TN', 'badge': 'TN'},
    {'name': 'Telangana', 'code': 'TS', 'badge': 'TS'},
    {'name': 'Andhra Pradesh', 'code': 'AP', 'badge': 'AP'},
    {'name': 'Rajasthan', 'code': 'RJ', 'badge': 'RJ'},
    {'name': 'Madhya Pradesh', 'code': 'MP', 'badge': 'MP'},
    {'name': 'Punjab', 'code': 'PB', 'badge': 'PB'},
    {'name': 'Haryana', 'code': 'HR', 'badge': 'HR'},
    {'name': 'West Bengal', 'code': 'WB', 'badge': 'WB'},
    {'name': 'Bihar', 'code': 'BR', 'badge': 'BR'},
    {'name': 'Odisha', 'code': 'OD', 'badge': 'OD'},
    {'name': 'Kerala', 'code': 'KL', 'badge': 'KL'},
    {'name': 'Assam', 'code': 'AS', 'badge': 'AS'},
    {'name': 'Uttarakhand', 'code': 'UK', 'badge': 'UK'},
    {'name': 'Himachal Pradesh', 'code': 'HP', 'badge': 'HP'},
    {'name': 'Jharkhand', 'code': 'JH', 'badge': 'JH'},
    {'name': 'Chhattisgarh', 'code': 'CG', 'badge': 'CG'},
    {'name': 'Jammu & Kashmir', 'code': 'JK', 'badge': 'JK'},
    {'name': 'Goa', 'code': 'GA', 'badge': 'GA'},
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      final provider = context.read<NewsProvider>();
      if (!provider.isLoadingMore && provider.hasMore && !provider.isLoading) {
        provider.fetchMoreNews();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NewsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selectedState = provider.selectedState;
    final selectedDiscom = provider.selectedDiscom;
    final hasActiveFilter = selectedState != 'All States' || selectedDiscom != 'All DISCOMs';

    // Get relevant DISCOMs for selected state
    final relevantDiscoms = selectedState != 'All States'
        ? (stateDiscomDirectory[selectedState] ?? [])
        : [];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B101E) : const Color(0xFFF8FAFC),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Sleek Regional Intelligence Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF111827) : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.25 : 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Title & Active Status Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.map_rounded,
                            size: 15,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'State & DISCOM Intelligence',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                    if (hasActiveFilter)
                      InkWell(
                        onTap: () {
                          provider.setStateFilter('All States');
                          provider.setDiscomFilter('All DISCOMs');
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(isDark ? 0.18 : 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.close_rounded, size: 12, color: Colors.redAccent),
                              SizedBox(width: 3),
                              Text(
                                'Clear',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 10),

                // 2. States Horizontal Carousel
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: allStatesList.map((st) {
                      final stateName = st['name']!;
                      final badge = st['badge']!;
                      final isSelected = selectedState == stateName;
                      final count = stateName == 'All States'
                          ? provider.totalStateNewsCount
                          : (provider.states[stateName] ?? 0);

                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () {
                              provider.setStateFilter(stateName);
                              provider.setDiscomFilter('All DISCOMs');
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF2563EB)
                                    : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF2563EB)
                                      : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white.withOpacity(0.2)
                                          : (isDark ? Colors.black26 : Colors.white),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      badge,
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: isSelected
                                            ? Colors.white
                                            : (isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    stateName,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B)),
                                    ),
                                  ),
                                  if (count > 0 && stateName != 'All States') ...[
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0.5),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.white.withOpacity(0.25)
                                            : (isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0)),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '$count',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: isSelected
                                              ? Colors.white
                                              : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
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
                    }).toList(),
                  ),
                ),

                // 3. State-Specific DISCOMs Row (when a state is active)
                if (relevantDiscoms.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.bolt_rounded,
                        size: 13,
                        color: isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'DISCOMs in $selectedState',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        // "All State DISCOMs" Pill
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            showCheckmark: false,
                            label: Text(
                              'All $selectedState',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: selectedDiscom == 'All DISCOMs' ? FontWeight.w800 : FontWeight.w600,
                                color: selectedDiscom == 'All DISCOMs'
                                    ? Colors.white
                                    : (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
                              ),
                            ),
                            selected: selectedDiscom == 'All DISCOMs',
                            selectedColor: const Color(0xFF7C3AED),
                            backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            visualDensity: VisualDensity.compact,
                            onSelected: (selected) {
                              if (selected) provider.setDiscomFilter('All DISCOMs');
                            },
                          ),
                        ),
                        // Individual DISCOM Pills
                        ...relevantDiscoms.map((disc) {
                          final code = disc['code']!;
                          final name = disc['name']!;
                          final isDiscSelected = selectedDiscom == code;
                          final count = provider.discoms[code] ?? 0;

                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              showCheckmark: false,
                              avatar: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: isDiscSelected ? Colors.white24 : const Color(0xFF7C3AED).withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.electric_meter_rounded,
                                  size: 11,
                                  color: isDiscSelected ? Colors.white : const Color(0xFF7C3AED),
                                ),
                              ),
                              label: Text(
                                count > 0 ? '$code ($count)' : code,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isDiscSelected ? FontWeight.w800 : FontWeight.w600,
                                  color: isDiscSelected
                                      ? Colors.white
                                      : (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
                                ),
                              ),
                              tooltip: name,
                              selected: isDiscSelected,
                              selectedColor: const Color(0xFF7C3AED),
                              backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                              visualDensity: VisualDensity.compact,
                              onSelected: (selected) {
                                if (selected) {
                                  provider.setDiscomFilter(code);
                                } else {
                                  provider.setDiscomFilter('All DISCOMs');
                                }
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 4. Active Filter Breadcrumb / Result Count Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.filter_list_rounded,
                      size: 12,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      selectedState == 'All States'
                          ? 'Showing All State & Regional News'
                          : (selectedDiscom == 'All DISCOMs'
                              ? 'State: $selectedState'
                              : '$selectedState > $selectedDiscom'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${provider.articles.length} updates',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
          ),

          // 5. News Articles List with Infinite Scroll
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => provider.triggerFullRefresh(),
              child: ((provider.isLoading && provider.articles.isEmpty) || provider.isFilterLoading)
                  ? ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 24),
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      itemCount: 3,
                      itemBuilder: (context, index) => _buildShimmerSkeletonCard(isDark),
                    )
                  : provider.articles.isEmpty
                      ? Center(
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: (isDark ? Colors.white : Colors.black).withOpacity(0.04),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.location_off_rounded,
                                size: 40,
                                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              selectedDiscom != 'All DISCOMs'
                                  ? 'No specific updates for $selectedDiscom'
                                  : 'No specific news indexed for $selectedState',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Try checking other DISCOMs or view all state updates.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.refresh_rounded, size: 15),
                              label: const Text('Show All State News', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                              onPressed: () {
                                provider.setStateFilter('All States');
                                provider.setDiscomFilter('All DISCOMs');
                              },
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(top: 8, bottom: 24),
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      itemCount: provider.articles.length + (provider.isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == provider.articles.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ),
                          );
                        }

                        return NewsCard(
                          article: provider.articles[index],
                          allArticles: provider.articles,
                          itemIndex: index,
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerSkeletonCard(bool isDark) {
    final baseColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final cardBg = isDark ? const Color(0xFF111827) : Colors.white;
    final borderColor = isDark ? const Color(0xFF1F2D47) : const Color(0xFFE2E8F0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 70,
                height: 18,
                decoration: BoxDecoration(
                  color: baseColor.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 50,
                height: 18,
                decoration: BoxDecoration(
                  color: baseColor.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Spacer(),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: baseColor.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 16,
            decoration: BoxDecoration(
              color: baseColor.withOpacity(0.8),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 220,
            height: 16,
            decoration: BoxDecoration(
              color: baseColor.withOpacity(0.7),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            height: 12,
            decoration: BoxDecoration(
              color: baseColor.withOpacity(0.4),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            height: 12,
            decoration: BoxDecoration(
              color: baseColor.withOpacity(0.4),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 160,
            height: 12,
            decoration: BoxDecoration(
              color: baseColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 90,
                height: 12,
                decoration: BoxDecoration(
                  color: baseColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Spacer(),
              Container(
                width: 100,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

