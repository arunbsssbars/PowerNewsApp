import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../providers/news_provider.dart';
import '../widgets/about_sheet.dart';
import '../widgets/ask_gemini_sheet.dart';
import 'admin_dashboard_screen.dart';
import 'login_signup_screen.dart';
import 'onboarding_screen.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (mounted) {
        setState(() {
          _scrollOffset = _scrollController.offset;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showEditProfileDialog(BuildContext context, AuthService auth) {
    final user = auth.currentUser;
    if (user == null) return;
    final nameCtrl = TextEditingController(text: user.displayName);
    final photoCtrl = TextEditingController(text: user.photoUrl ?? '');

    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.badge_rounded, color: Color(0xFF2563EB), size: 22),
            SizedBox(width: 8),
            Text('Edit Basic Details', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'Full Name / Title',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: photoCtrl,
              decoration: InputDecoration(
                labelText: 'Profile Photo URL (optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameCtrl.text.trim();
              final newPhoto = photoCtrl.text.trim().isEmpty ? null : photoCtrl.text.trim();
              if (newName.isNotEmpty) {
                await auth.updateProfileDetails(displayName: newName, photoUrl: newPhoto);
                if (ctx.mounted) Navigator.of(ctx).pop();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Profile details updated!')),
                );
              }
            },
            child: const Text('Save Details'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final newsProvider = context.watch<NewsProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = auth.currentUser;
    final isAdmin = auth.isAdmin;

    final bgCard = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    // Dynamic scale motion factor based on scrolling
    final avatarScale = (1.0 - (_scrollOffset / 300).clamp(0.0, 0.25));

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // 1. Subtle Motion Sliver App Bar with Stretch Parallax
          SliverAppBar(
            expandedHeight: 140.0,
            floating: false,
            pinned: true,
            stretch: true,
            backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
            elevation: _scrollOffset > 20 ? 3 : 0,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: avatarScale,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF0284C7)],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          user != null && user.displayName.isNotEmpty
                              ? user.displayName[0].toUpperCase()
                              : 'P',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    user != null ? (isAdmin ? 'Admin HQ & Profile' : 'Executive Profile') : 'Identity & Auth',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E293B), const Color(0xFF0B1120)]
                        : [const Color(0xFFE0F2FE), const Color(0xFFF8FAFC)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Opacity(
                  opacity: 0.15,
                  child: Center(
                    child: Icon(
                      Icons.bolt_rounded,
                      size: 140,
                      color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 2. Profile Content Body with Scroll Motion
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- A. User Identity Hero Card ---
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: bgCard,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: user == null
                        ? Column(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF2563EB), Color(0xFF0284C7)],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF2563EB).withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.shield_rounded, color: Colors.white, size: 30),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'PowerNews Executive Access',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Sign in or create an account to access administrative telemetry, saved briefings, and sector monitoring.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12.5, color: textSecondary, height: 1.4),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 44,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const LoginSignUpScreen(isModal: true)),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text('Sign In / Create Account', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Avatar with live indicator ring
                                  Container(
                                    width: 58,
                                    height: 58,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isAdmin ? const Color(0xFF10B981) : const Color(0xFF2563EB),
                                        width: 2.2,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(29),
                                      child: user.photoUrl != null && user.photoUrl!.isNotEmpty
                                          ? Image.network(
                                              user.photoUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => _buildInitialsAvatar(user.displayName),
                                            )
                                          : _buildInitialsAvatar(user.displayName),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                user.displayName,
                                                style: TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w800,
                                                  color: textPrimary,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.edit_outlined, size: 18),
                                              tooltip: 'Edit basic details',
                                              onPressed: () => _showEditProfileDialog(context, auth),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          user.email,
                                          style: TextStyle(fontSize: 12.5, color: textSecondary),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        // Badges Row (Role + Verification)
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                              decoration: BoxDecoration(
                                                color: isAdmin
                                                    ? const Color(0xFF10B981).withOpacity(0.15)
                                                    : const Color(0xFF2563EB).withOpacity(0.12),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: isAdmin ? const Color(0xFF10B981) : const Color(0xFF2563EB),
                                                  width: 0.8,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    isAdmin ? Icons.shield_rounded : Icons.verified_user_rounded,
                                                    size: 11,
                                                    color: isAdmin ? const Color(0xFF10B981) : const Color(0xFF2563EB),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    isAdmin ? 'VERIFIED ADMIN' : 'EXECUTIVE READER',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w800,
                                                      color: isAdmin ? const Color(0xFF10B981) : const Color(0xFF2563EB),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Email Verification Status Badge
                                            InkWell(
                                              borderRadius: BorderRadius.circular(6),
                                              onTap: user.isEmailVerified
                                                  ? null
                                                  : () async {
                                                      final sent = await auth.sendEmailVerification();
                                                      if (context.mounted) {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          SnackBar(
                                                            content: Text(sent
                                                                ? 'Verification email with button sent to ${user.email}!'
                                                                : 'Could not send verification email.'),
                                                          ),
                                                        );
                                                      }
                                                    },
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                                decoration: BoxDecoration(
                                                  color: user.isEmailVerified
                                                      ? const Color(0xFF10B981).withOpacity(0.12)
                                                      : const Color(0xFFF59E0B).withOpacity(0.15),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: user.isEmailVerified
                                                        ? const Color(0xFF10B981)
                                                        : const Color(0xFFF59E0B),
                                                    width: 0.8,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      user.isEmailVerified ? Icons.check_circle_rounded : Icons.mail_outline_rounded,
                                                      size: 11,
                                                      color: user.isEmailVerified ? const Color(0xFF10B981) : const Color(0xFFD97706),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      user.isEmailVerified ? 'EMAIL VERIFIED' : 'UNVERIFIED (TAP TO VERIFY)',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w800,
                                                        color: user.isEmailVerified ? const Color(0xFF10B981) : const Color(0xFFD97706),
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
                              ),

                              const SizedBox(height: 16),
                              Divider(color: borderColor),
                              const SizedBox(height: 12),

                              // Basic Metadata Details Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Auth Provider', style: TextStyle(fontSize: 12, color: textSecondary)),
                                  Text(user.authProvider.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Account ID', style: TextStyle(fontSize: 12, color: textSecondary)),
                                  Text(
                                    user.id.length > 14 ? '${user.id.substring(0, 14)}...' : user.id,
                                    style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: textSecondary),
                                  ),
                                ],
                              ),

                              // Placeholder for sector preferences (completed later on)
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.tune_rounded, size: 18, color: Color(0xFF2563EB)),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Sector Intelligence Preferences',
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'State DISCOM tracking, grid alerts & custom threshold settings will be completed in next phase.',
                                            style: TextStyle(fontSize: 11, color: textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),

                  // --- B. Admin HQ Launcher Button (if admin) ---
                  if (isAdmin) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [const Color(0xFF064E3B), const Color(0xFF065F46)]
                              : [const Color(0xFFD1FAE5), const Color(0xFFA7F3D0)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 18),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Executive Admin Control',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : const Color(0xFF065F46),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Access full administrative features: Live Flutter Feed inspection, keyword automation, ML dataset curation, system telemetry & Data Playbook.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? const Color(0xFFA7F3D0) : const Color(0xFF047857),
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.space_dashboard_rounded, size: 18),
                              label: const Text('Open Admin Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // --- C. Reading Statistics Card ---
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: bgCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Reading & Offline Cache', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary)),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricTile(
                                icon: Icons.bookmark_added_rounded,
                                color: const Color(0xFFD97706),
                                label: 'Saved Briefings',
                                value: '${newsProvider.bookmarks.length}',
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildMetricTile(
                                icon: Icons.offline_bolt_rounded,
                                color: const Color(0xFF2563EB),
                                label: 'Feed Cache',
                                value: '${newsProvider.articles.length} Loaded',
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // --- D. Preferences & Actions List ---
                  const SizedBox(height: 14),
                  Container(
                    decoration: BoxDecoration(
                      color: bgCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: Text('Dark Theme', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: textPrimary)),
                          subtitle: Text('Optimize contrast for night reading', style: TextStyle(fontSize: 11.5, color: textSecondary)),
                          value: isDark,
                          activeColor: const Color(0xFF2563EB),
                          onChanged: (_) => newsProvider.toggleTheme(),
                        ),
                        Divider(height: 1, color: borderColor),
                        ListTile(
                          leading: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF818CF8), size: 20),
                          title: Text('Ask AI Desk', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: textPrimary)),
                          subtitle: Text('Interact with Gemini power intelligence model', style: TextStyle(fontSize: 11.5, color: textSecondary)),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => AskGeminiSheet.show(context),
                        ),
                        Divider(height: 1, color: borderColor),
                        ListTile(
                          leading: const Icon(Icons.menu_book_rounded, color: Color(0xFF0284C7), size: 20),
                          title: Text('Onboarding Guide', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: textPrimary)),
                          subtitle: Text('Review gesture navigation and power categories', style: TextStyle(fontSize: 11.5, color: textSecondary)),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                            );
                          },
                        ),
                        Divider(height: 1, color: borderColor),
                        ListTile(
                          leading: const Icon(Icons.verified_user_outlined, color: Color(0xFF10B981), size: 20),
                          title: Text('Editorial Desk & Methodology', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: textPrimary)),
                          subtitle: Text('60-word summarization ethics & zero-storage policy', style: TextStyle(fontSize: 11.5, color: textSecondary)),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => AboutSheet.show(context),
                        ),
                      ],
                    ),
                  ),

                  // --- E. Sign Out Button ---
                  if (user != null) ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await auth.signOut();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Signed out successfully')),
                          );
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: BorderSide(color: const Color(0xFFEF4444).withOpacity(0.4)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Sign Out of PowerNews', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialsAvatar(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'P';
    return Container(
      color: const Color(0xFF2563EB),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}
