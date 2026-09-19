import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          title: const Row(
            children: [
              Icon(Icons.badge_rounded, color: Color(0xFF2563EB), size: 22),
              SizedBox(width: 8),
              Text(
                'Edit Profile Details',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Full Name / Title',
                  prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: photoCtrl,
                decoration: InputDecoration(
                  labelText: 'Profile Photo URL (optional)',
                  prefixIcon: const Icon(Icons.link_rounded, size: 20),
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
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile details updated successfully!')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Save Details', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _confirmSignOut(BuildContext context, AuthService auth) {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text(
            'Are you sure you want to sign out of your PowerNews account session?',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await auth.signOut();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Signed out successfully')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
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

    final bgCard = isDark ? const Color(0xFF161B22) : Colors.white;
    final borderColor = isDark ? const Color(0xFF263040) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? const Color(0xFFF0F6FC) : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // 1. Sleek, Executive App Bar
          SliverAppBar(
            expandedHeight: 110.0,
            floating: false,
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF0D1322) : Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 14),
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user != null ? (isAdmin ? 'Admin Profile' : 'Profile') : 'PowerNews Account',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: textPrimary,
                    ),
                  ),
                  if (isAdmin) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.18),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4), width: 0.8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shield_rounded, size: 10, color: Color(0xFF10B981)),
                          SizedBox(width: 3),
                          Text(
                            'ROOT ADMIN',
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF10B981),
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              if (user != null)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 19),
                  tooltip: 'Edit Profile Details',
                  onPressed: () => _showEditProfileDialog(context, auth),
                ),
              if (user != null)
                IconButton(
                  icon: const Icon(Icons.logout_rounded, size: 19),
                  tooltip: 'Sign Out',
                  onPressed: () => _confirmSignOut(context, auth),
                ),
              const SizedBox(width: 8),
            ],
          ),

          // 2. Profile Content Body
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- A. Identity Card ---
                  _buildIdentityCard(
                    context,
                    user,
                    isAdmin,
                    auth,
                    isDark,
                    bgCard,
                    borderColor,
                    textPrimary,
                    textSecondary,
                  ),

                  // --- B. Admin Quick Command Center (Clean 2x2 Grid for Admin) ---
                  if (isAdmin) ...[
                    const SizedBox(height: 18),
                    _buildAdminCommandGrid(
                      context,
                      isDark,
                      bgCard,
                      borderColor,
                      textPrimary,
                      textSecondary,
                    ),
                  ],

                  // --- C. Platform Analytics & Storage ---
                  const SizedBox(height: 18),
                  _buildPlatformAnalyticsCard(
                    context,
                    newsProvider,
                    isDark,
                    bgCard,
                    borderColor,
                    textPrimary,
                    textSecondary,
                  ),

                  // --- D. Preferences & Controls ---
                  const SizedBox(height: 18),
                  _buildPreferencesCard(
                    context,
                    newsProvider,
                    isDark,
                    bgCard,
                    borderColor,
                    textPrimary,
                    textSecondary,
                  ),

                  // --- E. Sign Out Action Button (if signed in) ---
                  if (user != null) ...[
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: () => _confirmSignOut(context, auth),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: BorderSide(color: const Color(0xFFEF4444).withOpacity(0.35)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Sign Out of Session', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // IDENTITY HERO CARD
  // ===========================================================================
  Widget _buildIdentityCard(
    BuildContext context,
    dynamic user,
    bool isAdmin,
    AuthService auth,
    bool isDark,
    Color bgCard,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    if (user == null) {
      return Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 54,
              height: 54,
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
              child: const Icon(Icons.shield_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              'PowerNews Executive Access',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Sign in to access real-time power sector intelligence, saved briefings, and administrative controls.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: textSecondary, height: 1.4),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginSignUpScreen(isModal: true)),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                icon: const Icon(Icons.login_rounded, size: 18),
                label: const Text('Sign In / Create Account', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar with live indicator ring
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isAdmin ? const Color(0xFF10B981) : const Color(0xFF2563EB),
                        width: 2.2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: user.photoUrl != null && user.photoUrl!.isNotEmpty
                          ? Image.network(
                              user.photoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildInitialsAvatar(user.displayName),
                            )
                          : _buildInitialsAvatar(user.displayName),
                    ),
                  ),
                  Container(
                    width: 15,
                    height: 15,
                    decoration: BoxDecoration(
                      color: isAdmin ? const Color(0xFF10B981) : const Color(0xFF2563EB),
                      shape: BoxShape.circle,
                      border: Border.all(color: bgCard, width: 2),
                    ),
                    child: Icon(
                      isAdmin ? Icons.star_rounded : Icons.check_rounded,
                      size: 9,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: TextStyle(
                        fontSize: 17.5,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                        letterSpacing: -0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: TextStyle(fontSize: 12.5, color: textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Role & Verification Badges
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: isAdmin
                                ? const Color(0xFF10B981).withOpacity(0.14)
                                : const Color(0xFF2563EB).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: isAdmin ? const Color(0xFF10B981).withOpacity(0.4) : const Color(0xFF2563EB).withOpacity(0.3),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            isAdmin ? 'ADMIN' : 'EXECUTIVE',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: isAdmin ? const Color(0xFF10B981) : const Color(0xFF2563EB),
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: user.isEmailVerified
                                ? const Color(0xFF10B981).withOpacity(0.12)
                                : const Color(0xFFF59E0B).withOpacity(0.14),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: user.isEmailVerified
                                  ? const Color(0xFF10B981).withOpacity(0.3)
                                  : const Color(0xFFF59E0B).withOpacity(0.35),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                user.isEmailVerified ? Icons.verified_rounded : Icons.pending_rounded,
                                size: 10,
                                color: user.isEmailVerified ? const Color(0xFF10B981) : const Color(0xFFD97706),
                              ),
                              const SizedBox(width: 3.5),
                              Text(
                                user.isEmailVerified ? 'VERIFIED' : 'UNVERIFIED',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: user.isEmailVerified ? const Color(0xFF10B981) : const Color(0xFFD97706),
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
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
          Divider(color: borderColor, height: 1),
          const SizedBox(height: 14),

          // Clean 3-Column Identity Meta Strip
          Row(
            children: [
              Expanded(
                child: _buildMetaPill(
                  label: 'ROLE',
                  value: isAdmin ? 'Root Admin' : 'Reader',
                  color: isAdmin ? const Color(0xFF10B981) : const Color(0xFF2563EB),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetaPill(
                  label: 'SECURITY',
                  value: user.authProvider.toUpperCase(),
                  color: const Color(0xFF6366F1),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetaPill(
                  label: 'STATUS',
                  value: 'Active Session',
                  color: const Color(0xFF0284C7),
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaPill({
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // ADMIN COMMAND GRID (2x2 Clean Executive Grid)
  // ===========================================================================
  Widget _buildAdminCommandGrid(
    BuildContext context,
    bool isDark,
    Color bgCard,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.dashboard_customize_rounded, size: 16, color: Color(0xFF10B981)),
            const SizedBox(width: 6),
            Text(
              'Admin Command Center',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const Spacer(),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminDashboardScreen(initialTabIndex: 0)),
                );
              },
              child: const Row(
                children: [
                  Text(
                    'Full Dashboard',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF10B981)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // 2x2 Grid of Actions
        Row(
          children: [
            Expanded(
              child: _buildCommandTile(
                context: context,
                title: 'Live Feed',
                subtitle: 'Filter & verify ingestion',
                icon: Icons.dynamic_feed_rounded,
                accentColor: const Color(0xFF0284C7),
                isDark: isDark,
                bgCard: bgCard,
                borderColor: borderColor,
                tabIndex: 0,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildCommandTile(
                context: context,
                title: 'Keywords',
                subtitle: 'Taxonomy & discovery',
                icon: Icons.tag_rounded,
                accentColor: const Color(0xFF8B5CF6),
                isDark: isDark,
                bgCard: bgCard,
                borderColor: borderColor,
                tabIndex: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildCommandTile(
                context: context,
                title: 'ML Curation',
                subtitle: 'Dataset scoring metrics',
                icon: Icons.psychology_rounded,
                accentColor: const Color(0xFFF59E0B),
                isDark: isDark,
                bgCard: bgCard,
                borderColor: borderColor,
                tabIndex: 2,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildCommandTile(
                context: context,
                title: 'Telemetry',
                subtitle: 'Cloud sync & health',
                icon: Icons.health_and_safety_rounded,
                accentColor: const Color(0xFF10B981),
                isDark: isDark,
                bgCard: bgCard,
                borderColor: borderColor,
                tabIndex: 3,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCommandTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required bool isDark,
    required Color bgCard,
    required Color borderColor,
    required int tabIndex,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminDashboardScreen(initialTabIndex: tabIndex),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(isDark ? 0.2 : 0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(icon, size: 18, color: accentColor),
                  ),
                  Icon(
                    Icons.arrow_outward_rounded,
                    size: 15,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10.5,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // PLATFORM ANALYTICS & STORAGE CARD
  // ===========================================================================
  Widget _buildPlatformAnalyticsCard(
    BuildContext context,
    NewsProvider newsProvider,
    bool isDark,
    Color bgCard,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_outlined, size: 16, color: Color(0xFF2563EB)),
              const SizedBox(width: 6),
              Text(
                'Intelligence Storage & Cache',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
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
                  icon: Icons.bolt_rounded,
                  color: const Color(0xFF2563EB),
                  label: 'Feed Ingested',
                  value: '${newsProvider.articles.length} Stories',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.cloud_done_rounded,
                  color: const Color(0xFF10B981),
                  label: 'Cloud Sync',
                  value: 'Live Active',
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
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
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // PREFERENCES & CONTROLS
  // ===========================================================================
  Widget _buildPreferencesCard(
    BuildContext context,
    NewsProvider newsProvider,
    bool isDark,
    Color bgCard,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          SwitchListTile(
            secondary: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: (isDark ? const Color(0xFFF59E0B) : const Color(0xFF2563EB)).withOpacity(0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: isDark ? const Color(0xFFF59E0B) : const Color(0xFF2563EB),
                size: 18,
              ),
            ),
            title: Text(
              'Dark Mode',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: textPrimary),
            ),
            subtitle: Text(
              'High-contrast executive theme',
              style: TextStyle(fontSize: 11.5, color: textSecondary),
            ),
            value: isDark,
            activeColor: const Color(0xFF2563EB),
            onChanged: (_) => newsProvider.toggleTheme(),
          ),
          Divider(height: 1, color: borderColor),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFF818CF8).withOpacity(0.14),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF818CF8), size: 18),
            ),
            title: Text(
              'Ask AI Desk (Gemini)',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: textPrimary),
            ),
            subtitle: Text(
              'Deep analytical queries on Indian power grid & tariffs',
              style: TextStyle(fontSize: 11.5, color: textSecondary),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, size: 20),
            onTap: () => AskGeminiSheet.show(context),
          ),
          Divider(height: 1, color: borderColor),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7).withOpacity(0.14),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.explore_rounded, color: Color(0xFF0284C7), size: 18),
            ),
            title: Text(
              'Tour & Gesture Guide',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: textPrimary),
            ),
            subtitle: Text(
              'Review swipe gestures, sectors & shortcut features',
              style: TextStyle(fontSize: 11.5, color: textSecondary),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, size: 20),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OnboardingScreen()),
              );
            },
          ),
          Divider(height: 1, color: borderColor),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.14),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.verified_user_outlined, color: Color(0xFF10B981), size: 18),
            ),
            title: Text(
              'Editorial Standards & Policy',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: textPrimary),
            ),
            subtitle: Text(
              '60-word summarization ethics & source attribution',
              style: TextStyle(fontSize: 11.5, color: textSecondary),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, size: 20),
            onTap: () => AboutSheet.show(context),
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
}
