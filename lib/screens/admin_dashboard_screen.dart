import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';

class AdminDashboardScreen extends StatefulWidget {
  final int initialTabIndex;

  const AdminDashboardScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _auth = AuthService();

  // Tab 1: Live Flutter Feed State
  List<dynamic> _flutterFeed = [];
  bool _isLoadingFeed = false;
  String _feedFilterQuery = '';

  // Tab 2: Keywords State
  List<String> _baseKeywords = [];
  List<String> _dynamicKeywords = [];
  bool _isLoadingKeywords = false;
  bool _isAutoDiscovering = false;
  String? _keywordDuplicateAlert;
  final TextEditingController _keywordInputController = TextEditingController();

  // Tab 3: ML Training State
  List<dynamic> _mlData = [];
  bool _isLoadingMl = false;
  String _mlFilter = 'all';

  // Tab 4: System Health & Storage State
  Map<String, dynamic>? _healthData;
  Map<String, dynamic>? _memoryData;
  Map<String, dynamic>? _storageData;
  bool _isLoadingHealth = false;
  bool _isLoadingStorage = false;
  bool _isTriggeringSync = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 4),
    );
    _loadAllTabs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _keywordInputController.dispose();
    super.dispose();
  }

  Map<String, String> _getHeaders() {
    final token = _auth.currentUser?.idToken;
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'x-api-key': AppConfig.clientSecret,
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  String get _baseUrl => ApiService.renderCloudHost;

  Future<void> _loadAllTabs() async {
    _fetchFlutterFeed();
    _fetchKeywords();
    _fetchMlData();
    _fetchHealth();
    _fetchStorageStatus();
  }

  Future<void> _fetchStorageStatus() async {
    setState(() => _isLoadingStorage = true);
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/api/admin/storage-status'),
        headers: _getHeaders(),
      );
      if (res.statusCode == 200) {
        setState(() {
          _storageData = jsonDecode(res.body);
        });
      }
    } catch (e) {
      debugPrint('[Admin] Error fetching storage status: $e');
    } finally {
      if (mounted) setState(() => _isLoadingStorage = false);
    }
  }

  // ===========================================================================
  // 1. LIVE FLUTTER FEED API
  // ===========================================================================
  Future<void> _fetchFlutterFeed() async {
    setState(() => _isLoadingFeed = true);
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/api/admin/flutter-feed'),
        headers: _getHeaders(),
      );
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        setState(() {
          _flutterFeed = decoded['articles'] ?? [];
        });
      } else {
        // Fallback to /api/news
        final fallback = await http.get(
          Uri.parse('$_baseUrl/api/news?limit=60'),
          headers: _getHeaders(),
        );
        if (fallback.statusCode == 200) {
          final decoded = jsonDecode(fallback.body);
          setState(() {
            _flutterFeed = decoded['articles'] ?? [];
          });
        }
      }
    } catch (e) {
      debugPrint('[Admin] Error fetching feed: $e');
    } finally {
      if (mounted) setState(() => _isLoadingFeed = false);
    }
  }

  // ===========================================================================
  // 2. KEYWORDS AUTOMATION API
  // ===========================================================================
  Future<void> _fetchKeywords() async {
    setState(() => _isLoadingKeywords = true);
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/api/admin/keywords'),
        headers: _getHeaders(),
      );
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        setState(() {
          _baseKeywords = List<String>.from(decoded['baseKeywords'] ?? []);
          _dynamicKeywords = List<String>.from(decoded['dynamicKeywords'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('[Admin] Error fetching keywords: $e');
    } finally {
      if (mounted) setState(() => _isLoadingKeywords = false);
    }
  }

  Future<void> _autoDiscoverKeywords() async {
    setState(() => _isAutoDiscovering = true);
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/admin/keywords/auto-discover'),
        headers: _getHeaders(),
      );
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final discovered = (decoded['discovered'] as List<dynamic>?) ?? [];
        await _fetchKeywords();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(discovered.isEmpty
                  ? 'Active vocabulary up-to-date. No missing entities.'
                  : 'Auto-discovered and added ${discovered.length} entities!'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('[Admin] Auto-discover error: $e');
    } finally {
      if (mounted) setState(() => _isAutoDiscovering = false);
    }
  }

  Future<void> _addCustomKeyword() async {
    final text = _keywordInputController.text.trim();
    if (text.isEmpty) return;

    // Check duplicate
    final lower = text.toLowerCase();
    final isDuplicate = _baseKeywords.any((k) => k.toLowerCase() == lower) ||
        _dynamicKeywords.any((k) => k.toLowerCase() == lower);

    if (isDuplicate) {
      setState(() {
        _keywordDuplicateAlert = '"$text" already exists in active vocabulary!';
      });
      return;
    }

    setState(() => _keywordDuplicateAlert = null);

    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/admin/keywords/add'),
        headers: _getHeaders(),
        body: jsonEncode({'keyword': text}),
      );
      if (res.statusCode == 200) {
        _keywordInputController.clear();
        _fetchKeywords();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Added keyword "$text" (+50 PowerScore lift)')),
          );
        }
      }
    } catch (e) {
      debugPrint('[Admin] Add keyword error: $e');
    }
  }

  Future<void> _deleteKeyword(String kw) async {
    try {
      final res = await http.delete(
        Uri.parse('$_baseUrl/api/admin/keywords/${Uri.encodeComponent(kw)}'),
        headers: _getHeaders(),
      );
      if (res.statusCode == 200) {
        _fetchKeywords();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Removed dynamic entity "$kw"')),
          );
        }
      }
    } catch (e) {
      debugPrint('[Admin] Delete keyword error: $e');
    }
  }

  // ===========================================================================
  // 3. ML TRAINING API
  // ===========================================================================
  Future<void> _fetchMlData() async {
    setState(() => _isLoadingMl = true);
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/api/admin/training-data?limit=50'),
        headers: _getHeaders(),
      );
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        setState(() {
          _mlData = decoded['data'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('[Admin] Error fetching ML data: $e');
    } finally {
      if (mounted) setState(() => _isLoadingMl = false);
    }
  }

  Future<void> _updateMlStatus(String id, String status) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/admin/training-data/$id/status'),
        headers: _getHeaders(),
        body: jsonEncode({'status': status}),
      );
      if (res.statusCode == 200) {
        setState(() {
          final idx = _mlData.indexWhere((item) => item['id'] == id);
          if (idx != -1) {
            _mlData[idx]['mlStatus'] = status;
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Updated status to "$status"'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('[Admin] Error updating status: $e');
    }
  }

  Future<void> _exportDataset() async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/api/admin/export-dataset'),
        headers: _getHeaders(),
      );
      if (res.statusCode == 200 && res.body.isNotEmpty) {
        await Share.share(
          res.body,
          subject: 'power60_finetuning_dataset.jsonl',
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No approved training pairs ready for export.')),
          );
        }
      }
    } catch (e) {
      debugPrint('[Admin] Export dataset error: $e');
    }
  }

  // ===========================================================================
  // 4. SYSTEM HEALTH & CRAWLER PIPELINE SYNC
  // ===========================================================================
  Future<void> _fetchHealth() async {
    setState(() => _isLoadingHealth = true);
    try {
      final healthRes = await http.get(Uri.parse('$_baseUrl/api/health'), headers: _getHeaders());
      final memRes = await http.get(Uri.parse('$_baseUrl/api/memory'), headers: _getHeaders());
      if (healthRes.statusCode == 200) {
        _healthData = jsonDecode(healthRes.body);
      }
      if (memRes.statusCode == 200) {
        _memoryData = jsonDecode(memRes.body);
      }
    } catch (e) {
      debugPrint('[Admin] Error fetching health: $e');
    } finally {
      if (mounted) setState(() => _isLoadingHealth = false);
    }
  }

  Future<void> _triggerPipelineSync() async {
    setState(() => _isTriggeringSync = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
              SizedBox(width: 12),
              Text('Triggering RSS feed crawl & power pipeline sync...'),
            ],
          ),
          duration: Duration(seconds: 4),
        ),
      );
    }
    try {
      final res = await http.get(Uri.parse('$_baseUrl/api/refresh'), headers: _getHeaders());
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final count = decoded['count'] ?? 0;
        await _loadAllTabs();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Pipeline sync complete! $count live power articles cached.'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('[Admin] Trigger sync error: $e');
    } finally {
      if (mounted) setState(() => _isTriggeringSync = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (!_auth.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'Admin privileges required. Please sign in with arunbsssbars@gmail.com.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF0284C7)]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shield_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PowerNews HQ',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
                ),
                Text(
                  'Executive Admin Portal',
                  style: TextStyle(fontSize: 10.5, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Pipeline Crawler Scraper Trigger Button (Replaces the broken webview button)
          IconButton(
            tooltip: 'Trigger Pipeline Crawler & RSS Sync',
            icon: _isTriggeringSync
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.bolt_rounded, color: Color(0xFFF59E0B)),
            onPressed: _isTriggeringSync ? null : _triggerPipelineSync,
          ),
          IconButton(
            tooltip: 'Refresh All Tabs',
            icon: const Icon(Icons.sync_rounded),
            onPressed: _loadAllTabs,
          ),
          const SizedBox(width: 4),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: const Color(0xFF2563EB),
          labelColor: const Color(0xFF2563EB),
          unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          tabs: const [
            Tab(text: 'Live Feed', icon: Icon(Icons.newspaper_rounded, size: 16)),
            Tab(text: 'Keywords', icon: Icon(Icons.auto_awesome_rounded, size: 16)),
            Tab(text: 'ML Data', icon: Icon(Icons.model_training_rounded, size: 16)),
            Tab(text: 'Health', icon: Icon(Icons.monitor_heart_rounded, size: 16)),
            Tab(text: 'Data Playbook', icon: Icon(Icons.menu_book_rounded, size: 16)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLiveFeedTab(isDark),
          _buildKeywordsTab(isDark),
          _buildMlQueueTab(isDark),
          _buildHealthTab(isDark),
          _buildDataPlaybookTab(isDark),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1: LIVE FLUTTER FEED (Clean Operational Inspector)
  // ===========================================================================
  Widget _buildLiveFeedTab(bool isDark) {
    final bgCard = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final filteredArticles = _flutterFeed.where((a) {
      if (_feedFilterQuery.isEmpty) return true;
      final query = _feedFilterQuery.toLowerCase();
      final title = (a['title'] ?? '').toString().toLowerCase();
      final source = (a['source'] ?? '').toString().toLowerCase();
      final state = (a['state'] ?? '').toString().toLowerCase();
      final summary = (a['summary'] ?? '').toString().toLowerCase();
      return title.contains(query) || source.contains(query) || state.contains(query) || summary.contains(query);
    }).toList();

    return Column(
      children: [
        // Header Bar: Search input and Live Count
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bgCard,
            border: Border(bottom: BorderSide(color: borderColor)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Filter live feed by title, state, entity...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    isDense: true,
                  ),
                  onChanged: (val) => setState(() => _feedFilterQuery = val),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                ),
                child: Text(
                  '${_flutterFeed.length} Live',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                ),
              ),
            ],
          ),
        ),

        // Articles List
        Expanded(
          child: _isLoadingFeed
              ? const Center(child: CircularProgressIndicator())
              : filteredArticles.isEmpty
                  ? Center(
                      child: Text(
                        _feedFilterQuery.isEmpty ? 'No live articles in retention window.' : 'No articles match filter.',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: filteredArticles.length,
                      itemBuilder: (context, idx) {
                        final a = filteredArticles[idx];
                        final score = a['_calculatedScore'] ?? a['calculatedScore'] ?? 40.0;
                        final wordCount = (a['summary'] ?? '').toString().trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
                        final url = a['url'] ?? '';

                        return Card(
                          elevation: 0,
                          color: bgCard,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: borderColor),
                          ),
                          margin: const EdgeInsets.only(bottom: 10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _showArticleJsonBottomSheet(context, a),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2563EB).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          a['source'] ?? 'PowerNews',
                                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF59E0B).withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '⚡ ${(score is num) ? score.toStringAsFixed(1) : score} pts',
                                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '$wordCount words',
                                        style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    a['title'] ?? 'Untitled Headline',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    a['summary'] ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      if (a['state'] != null && a['state'].toString().isNotEmpty)
                                        Container(
                                          margin: const EdgeInsets.only(right: 6),
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(a['state'].toString(), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                        ),
                                      const Spacer(),
                                      if (url.isNotEmpty)
                                        InkWell(
                                          onTap: () async {
                                            final uri = Uri.parse(url);
                                            if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
                                          },
                                          child: const Row(
                                            children: [
                                              Icon(Icons.open_in_new_rounded, size: 13, color: Color(0xFF2563EB)),
                                              SizedBox(width: 4),
                                              Text('Publisher Source', style: TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontWeight: FontWeight.w600)),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  void _showArticleJsonBottomSheet(BuildContext context, dynamic article) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.data_object_rounded, color: Color(0xFF2563EB)),
                const SizedBox(width: 8),
                const Text('Firestore Article Telemetry', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  tooltip: 'Copy JSON',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: const JsonEncoder.withIndent('  ').convert(article)));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Article JSON copied!')));
                  },
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(
                  const JsonEncoder.withIndent('  ').convert(article),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11.5,
                    color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0F172A),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 2: KEYWORDS AUTOMATION
  // ===========================================================================
  Widget _buildKeywordsTab(bool isDark) {
    final bgCard = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    if (_isLoadingKeywords) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Cron Schedule & Tip Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.schedule_rounded, size: 18, color: Color(0xFF10B981)),
                  SizedBox(width: 8),
                  Text('Background Cron Schedule', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Automatically extracts missing power entities twice daily at 04:00 AM & 04:00 PM IST and saves to Firestore.',
                style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.35),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Text('💡', style: TextStyle(fontSize: 13)),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Discovered terms take immediate effect with zero server restarts.',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF2563EB), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Auto-Discover Action Button
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton.icon(
            onPressed: _isAutoDiscovering ? null : _autoDiscoverKeywords,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: _isAutoDiscovering
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.auto_awesome_rounded, size: 18),
            label: Text(
              _isAutoDiscovering ? 'Discovering from recent articles...' : 'Auto-Discover & Add Missing Entities',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Add Custom Keyword Form
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Custom Keyword (+50 Score)', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _keywordInputController,
                      decoration: InputDecoration(
                        hintText: 'e.g. BESS, STATCOM, Green Ammonia...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _addCustomKeyword(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addCustomKeyword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Add'),
                  ),
                ],
              ),
              if (_keywordDuplicateAlert != null) ...[
                const SizedBox(height: 8),
                Text(
                  _keywordDuplicateAlert!,
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Dynamic Keywords Section
        Text(
          'Dynamic Discovered Keywords (${_dynamicKeywords.length})',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _dynamicKeywords.isEmpty
            ? const Text('No dynamic keywords added yet.', style: TextStyle(fontSize: 12, color: Colors.grey))
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _dynamicKeywords.map((kw) {
                  return Chip(
                    backgroundColor: const Color(0xFF2563EB).withOpacity(0.12),
                    side: const BorderSide(color: Color(0xFF2563EB), width: 0.8),
                    label: Text(kw, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2563EB))),
                    deleteIcon: const Icon(Icons.close_rounded, size: 14),
                    onDeleted: () => _deleteKeyword(kw),
                  );
                }).toList(),
              ),

        const SizedBox(height: 20),

        // Base Keywords Section (Read Only Defaults)
        Text(
          'Base System Keywords (${_baseKeywords.length})',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _baseKeywords.map((kw) {
            return Chip(
              backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              side: BorderSide(color: borderColor),
              label: Text(kw, style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ===========================================================================
  // TAB 3: ML TRAINING QUEUE
  // ===========================================================================
  Widget _buildMlQueueTab(bool isDark) {
    final bgCard = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final filteredData = _mlData.where((item) {
      if (_mlFilter == 'all') return true;
      return (item['mlStatus'] ?? 'pending').toString().toLowerCase() == _mlFilter;
    }).toList();

    return Column(
      children: [
        // Controls Row: Filter and Export Button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bgCard,
            border: Border(bottom: BorderSide(color: borderColor)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Wrap(
                  spacing: 6,
                  children: ['all', 'pending', 'approved', 'rejected'].map((f) {
                    final isSelected = _mlFilter == f;
                    return ChoiceChip(
                      label: Text(f.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : null)),
                      selected: isSelected,
                      selectedColor: const Color(0xFF2563EB),
                      onSelected: (_) => setState(() => _mlFilter = f),
                    );
                  }).toList(),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _exportDataset,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: const Text('Export .jsonl', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),

        // List of Training Pairs
        Expanded(
          child: _isLoadingMl
              ? const Center(child: CircularProgressIndicator())
              : filteredData.isEmpty
                  ? const Center(child: Text('No ML training items match filter.', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: filteredData.length,
                      itemBuilder: (context, idx) {
                        final item = filteredData[idx];
                        final id = item['id'] ?? '';
                        final title = item['title'] ?? 'Article Headline';
                        final original = item['originalText'] ?? item['fullText'] ?? 'Original scraped news text...';
                        final summary = item['summary'] ?? item['completion'] ?? 'AI 60-word summary...';
                        final status = (item['mlStatus'] ?? 'pending').toString().toLowerCase();

                        Color badgeColor = const Color(0xFFF59E0B);
                        if (status == 'approved') badgeColor = const Color(0xFF10B981);
                        if (status == 'rejected') badgeColor = const Color(0xFFEF4444);

                        return Card(
                          elevation: 0,
                          color: bgCard,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: borderColor),
                          ),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: badgeColor.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: badgeColor),
                                      ),
                                      child: Text(
                                        status.toUpperCase(),
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                const Text('ORIGINAL EXTRACT:', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.grey)),
                                const SizedBox(height: 2),
                                Text(original, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                const SizedBox(height: 8),
                                const Text('60-WORD COMPLETION:', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                                const SizedBox(height: 2),
                                Text(summary, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton(
                                      onPressed: () => _updateMlStatus(id, 'rejected'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFFEF4444),
                                        side: const BorderSide(color: Color(0xFFEF4444)),
                                      ),
                                      child: const Text('Reject'),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () => _updateMlStatus(id, 'approved'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF10B981),
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Approve'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  // ===========================================================================
  // TAB 4: SYSTEM HEALTH & TELEMETRY
  // ===========================================================================
  Widget _buildHealthTab(bool isDark) {
    final bgCard = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final uptime = _healthData?['uptime'] ?? 0;
    final articlesCount = _healthData?['articlesCount'] ?? _flutterFeed.length;
    final summariesCount = _healthData?['totalAiSummaries'] ?? 0;
    final heapUsed = _memoryData?['heapUsed'] ?? 'N/A';
    final rss = _memoryData?['rss'] ?? 'N/A';

    return _isLoadingHealth
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 4 Metrics Grid
              Row(
                children: [
                  Expanded(
                    child: _buildTelemetryCard(
                      icon: Icons.timer_outlined,
                      label: 'System Uptime',
                      value: _formatUptime(uptime),
                      color: const Color(0xFF2563EB),
                      isDark: isDark,
                      borderColor: borderColor,
                      bgCard: bgCard,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTelemetryCard(
                      icon: Icons.newspaper_rounded,
                      label: 'Live Flutter Pool',
                      value: '$articlesCount Articles',
                      color: const Color(0xFF10B981),
                      isDark: isDark,
                      borderColor: borderColor,
                      bgCard: bgCard,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildTelemetryCard(
                      icon: Icons.auto_awesome_rounded,
                      label: 'AI Summaries',
                      value: '$summariesCount Cached',
                      color: const Color(0xFF818CF8),
                      isDark: isDark,
                      borderColor: borderColor,
                      bgCard: bgCard,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTelemetryCard(
                      icon: Icons.memory_rounded,
                      label: 'Process Memory',
                      value: heapUsed != 'N/A' ? '$heapUsed MB Heap' : '$rss MB RSS',
                      color: const Color(0xFFF59E0B),
                      isDark: isDark,
                      borderColor: borderColor,
                      bgCard: bgCard,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Firebase Cloud Storage & Firestore Telemetry Card
              _buildFirebaseStorageCard(isDark, bgCard, borderColor),

              const SizedBox(height: 16),

              // Manual Scraper Trigger Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.sync_problem_rounded, color: Color(0xFF2563EB), size: 20),
                        SizedBox(width: 8),
                        Text('Pipeline Crawler & Scraper', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Manually run RSS aggregation across 15+ power sources, discard non-power articles, generate 60-word AI summaries and refresh Cloud Firestore.',
                      style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.35),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isTriggeringSync ? null : _triggerPipelineSync,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: _isTriggeringSync
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.bolt_rounded, size: 18),
                        label: const Text('Trigger Pipeline Sync Now', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Raw JSON Telemetry Viewer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.terminal_rounded, size: 18, color: Colors.grey),
                        const SizedBox(width: 8),
                        const Text('Raw Process Telemetry', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          tooltip: 'Copy JSON',
                          onPressed: () {
                            final raw = {
                              'health': _healthData,
                              'memory': _memoryData,
                              'storage': _storageData,
                            };
                            Clipboard.setData(ClipboardData(text: const JsonEncoder.withIndent('  ').convert(raw)));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Telemetry JSON copied!')));
                          },
                        ),
                      ],
                    ),
                    const Divider(),
                    SelectableText(
                      const JsonEncoder.withIndent('  ').convert({
                        'health': _healthData,
                        'memory': _memoryData,
                        'storage': _storageData,
                      }),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
  }

  Widget _buildFirebaseStorageCard(bool isDark, Color bgCard, Color borderColor) {
    if (_isLoadingStorage && _storageData == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    final firestore = _storageData?['firestore'] as Map<String, dynamic>?;
    final cloudStorage = _storageData?['cloudStorage'] as Map<String, dynamic>?;

    final isConnected = firestore?['connected'] == true;
    final totalDocs = firestore?['totalDocuments'] ?? 0;
    final estimatedMb = (firestore?['estimatedSizeMb'] as num?)?.toDouble() ?? 0.0;
    final quotaMb = (firestore?['freeTierQuotaMb'] as num?)?.toDouble() ?? 1024.0;
    final quotaUsedPercent = (firestore?['quotaUsedPercent'] as num?)?.toDouble() ?? 0.0;
    final purgeThreshold = (firestore?['purgeThresholdMb'] as num?)?.toDouble() ?? 850.0;

    final collections = firestore?['collections'] as Map<String, dynamic>? ?? {};
    final aiDocs = collections['ai_summaries']?['count'] ?? 0;
    final aiMb = collections['ai_summaries']?['estimatedMb'] ?? 0.0;
    final mlDocs = collections['power60_training_data']?['count'] ?? 0;
    final mlMb = collections['power60_training_data']?['estimatedMb'] ?? 0.0;

    final storageMessage = cloudStorage?['message'] ?? 'Zero-Storage Policy: Images served from publisher CDNs.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.cloud_sync_rounded, color: Color(0xFFF59E0B), size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Firestore & Firebase Storage',
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'Free tier usage quota & persistence health',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isConnected
                      ? const Color(0xFF10B981).withOpacity(0.14)
                      : const Color(0xFFEF4444).withOpacity(0.14),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isConnected ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isConnected ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                      size: 11,
                      color: isConnected ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isConnected ? 'ONLINE' : 'OFFLINE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isConnected ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 18),
                tooltip: 'Refresh Storage Telemetry',
                onPressed: _fetchStorageStatus,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Quota Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$estimatedMb MB of ${quotaMb.toInt()} MB Free Tier',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Text(
                '$quotaUsedPercent% Used',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: quotaUsedPercent > 80 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (quotaUsedPercent / 100).clamp(0.005, 1.0),
              minHeight: 7,
              backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                quotaUsedPercent > 80 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Auto-purge safety trigger: ${purgeThreshold.toInt()} MB limit (FIFO eviction)',
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),

          const SizedBox(height: 14),
          Divider(color: borderColor, height: 1),
          const SizedBox(height: 12),

          // 3-Column Metrics Breakdown
          Row(
            children: [
              Expanded(
                child: _buildStorageMetricTile(
                  label: 'TOTAL DOCS',
                  value: '$totalDocs',
                  sub: 'Across all collections',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStorageMetricTile(
                  label: 'AI SUMMARIES',
                  value: '$aiDocs',
                  sub: '~$aiMb MB',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStorageMetricTile(
                  label: 'ML DATASET',
                  value: '$mlDocs',
                  sub: '~$mlMb MB',
                  isDark: isDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Binary Cloud Storage Policy Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF2563EB)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    storageMessage,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
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

  Widget _buildStorageMetricTile({
    required String label,
    required String value,
    required String sub,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
          ),
          Text(
            sub,
            style: const TextStyle(fontSize: 9.5, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
    required Color borderColor,
    required Color bgCard,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  String _formatUptime(dynamic uptimeSeconds) {
    if (uptimeSeconds == null) return '0s';
    final sec = (uptimeSeconds is num) ? uptimeSeconds.toInt() : 0;
    final hours = sec ~/ 3600;
    final mins = (sec % 3600) ~/ 60;
    if (hours > 0) return '${hours}h ${mins}m';
    return '${mins}m ${sec % 60}s';
  }

  // ===========================================================================
  // TAB 5: DATA PLAYBOOK (Full 6 Chapters System Manual)
  // ===========================================================================
  Widget _buildDataPlaybookTab(bool isDark) {
    final bgCard = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildPlaybookChapter(
          number: '1',
          title: 'End-to-End Pipeline Architecture',
          subtitle: 'From Web Crawler to Flutter Mobile Rendering',
          isDark: isDark,
          bgCard: bgCard,
          borderColor: borderColor,
          content: '''
• Crawling & RSS Aggregation: 15+ curated Indian power feeds (CEA, Mercom, ET Energy, PowerLine) polled on a 20-minute cron cycle.
• Data Cleaning & Sanitization: Strips HTML entities, publisher tracking parameters, and wire duplications.
• Non-Power Discarding (PowerFilter): Discards non-power articles using a strict keyword gate.
• Gemini 60-Word AI Summarization: Produces high-density, quantitative executive briefs (MW, GW, capex, Discoms).
• Cloud Firestore Storage: 14 typed fields per document, 850 MB auto-purge retention cron.
• Dual-Layer Flutter Mobile Display: SQLite offline cache + background REST API synchronization.
''',
        ),
        _buildPlaybookChapter(
          number: '2',
          title: 'Power60 Ranking Algorithm',
          subtitle: 'Gravity Scoring with Time Decay and Keyword Lift',
          isDark: isDark,
          bgCard: bgCard,
          borderColor: borderColor,
          content: '''
Score Formula:
Score = [Base + (Keywords * 50) + SourceWeight - SolarPenalty] / (AgeHours + 2)^1.5

• Base Score: Starts at 10.0 for all vetted articles.
• Keyword Multiplier (+50 pts): Critical vertical terms (STATCOM, BESS, Green Ammonia, RDSS).
• Source Authority: Tier-1 agencies (PIB, CEA) receive a +20 point weight.
• Anti-Clumping Penalty: Restricts solar articles to maximum 2 consecutive cards.
• Time Decay Gravity: 1.5 power exponent prevents stale articles from lingering.
''',
        ),
        _buildPlaybookChapter(
          number: '3',
          title: 'Fine-Tuning Guide (Zero API Cost)',
          subtitle: 'Exporting .jsonl to Self-Host Llama-3 / Mistral-7B',
          isDark: isDark,
          bgCard: bgCard,
          borderColor: borderColor,
          content: '''
Step 1: Curate & approve 500+ training pairs in Tab 3 (ML Data).
Step 2: Export dataset via one-click "Export .jsonl" button.
Step 3: Run QLoRA fine-tuning script on Google Colab or Kaggle (Free T4 GPU).
Step 4: Convert adapter weights to GGUF format.
Step 5: Host locally with Ollama or vLLM for \$0 monthly API cost!
''',
        ),
        _buildPlaybookChapter(
          number: '4',
          title: 'Commercial & B2B Use Cases',
          subtitle: 'Monetization & Industry Intelligence Verticals',
          isDark: isDark,
          bgCard: bgCard,
          borderColor: borderColor,
          content: '''
• State DISCOM Health Tracker: Real-time tariff revisions, AT&C losses, and payment security monitoring.
• Regulatory Alert Desk: Automatic alerts on CERC and SERC tariff petitions and draft regulations.
• Domain-Specific RAG: Enterprise search for EPC contractors, transmission developers, and energy analysts.
''',
        ),
        _buildPlaybookChapter(
          number: '5',
          title: 'System Flaws & Engineering Roadmap',
          subtitle: 'Addressing Technical Debt & Scalability',
          isDark: isDark,
          bgCard: bgCard,
          borderColor: borderColor,
          content: '''
• Render Free-Tier Sleep: Solved via UptimeRobot continuous ping on /health.
• Rate Limits: Gemini API rate limit addressed with batch queue throttling.
• Future Roadmap: Semantic vector deduplication, Redis BullMQ queues, and FCM push notifications.
''',
        ),
        _buildPlaybookChapter(
          number: '6',
          title: 'Operations Guide for Each Tab',
          subtitle: 'Quick Reference for Platform Administration',
          isDark: isDark,
          bgCard: bgCard,
          borderColor: borderColor,
          content: '''
• 📱 Live Feed: Inspect articles currently visible on mobile devices and verify 60-word briefs.
• ⚡ Keywords: Add custom terms and run auto-discovery to boost critical vertical visibility.
• 🤖 ML Data: Review and approve training data to build your proprietary LLM dataset.
• 🩺 Health: Monitor uptime, memory consumption, and trigger manual crawler sync.
• 📖 Playbook: System architecture manual and mathematical reference.
''',
        ),
      ],
    );
  }

  Widget _buildPlaybookChapter({
    required String number,
    required String title,
    required String subtitle,
    required String content,
    required bool isDark,
    required Color bgCard,
    required Color borderColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: ExpansionTile(
        initiallyExpanded: number == '1',
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF2563EB), fontSize: 14),
            ),
          ),
        ),
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              content.trim(),
              style: TextStyle(
                fontSize: 12.5,
                height: 1.5,
                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
