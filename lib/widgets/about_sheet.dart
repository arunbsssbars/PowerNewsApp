import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutSheet extends StatelessWidget {
  const AboutSheet({super.key});

  static void show(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const AboutSheet(),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFE6EDF3) : const Color(0xFF0F172A);
    final secondaryText = isDark ? const Color(0xFF9DA7B3) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF263040) : const Color(0xFFE2E8F0);

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Grab handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Brand Row
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0284C7).withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/icons/app_icon.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF0284C7)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.bolt_rounded, size: 26, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PowerNews',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                          letterSpacing: -0.4,
                        ),
                      ),
                      Text(
                        'Version 1.0.0 (Production) • India Grid Intel',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: secondaryText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Divider(color: borderColor, height: 1),
              const SizedBox(height: 16),

              // Editorial Mission
              Text(
                'EDITORIAL MISSION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'PowerNews delivers real-time, objective business intelligence across generation, 765kV transmission corridors, CERC/SERC tariff orders, RDSS smart metering, and equipment tenders for leadership at CEA, DISCOMs, PSUs, and power OEMs.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 18),

              // AI Synthesized Dispatches & Grounding
              Text(
                'AI SYNTHESIS & FACT GROUNDING',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'All 50–100 word narrative executive dispatches are synthesized using Google Gemini AI models strictly grounded in original publisher reporting. The platform enforces zero hallucinations, highlighting quantitative project capex, capacity metrics (MW/GW), and transmission voltages.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 18),

              // Indexed Publications & Attribution
              Text(
                'ATTRIBUTED NEWS SOURCES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  'Mercom India',
                  'PV Magazine India',
                  'Economic Times Energy',
                  'Financial Express',
                  'LiveMint Energy',
                  'PIB / Ministry of Power',
                  'CERC & SERC Public Orders',
                  'SECI Tenders',
                ].map((src) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor),
                    ),
                    child: Text(
                      src,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Policy & Developer Contact Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0D1117) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified_user_rounded, size: 16, color: Color(0xFF10B981)),
                        const SizedBox(width: 6),
                        Text(
                          'Google Play Compliance & Legal',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'All news stories link directly to the original publisher\'s full web article. Publishers may request feed updates or opt-outs anytime by contacting our team.',
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.45,
                        color: secondaryText,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        InkWell(
                          onTap: () => _launchUrl('https://powernewsapp-backend.onrender.com/privacy'),
                          child: const Text(
                            'Privacy Policy',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF38BDF8),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        InkWell(
                          onTap: () => _launchUrl('mailto:support@powernews.app'),
                          child: const Text(
                            'Contact Editorial Desk',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF38BDF8),
                              decoration: TextDecoration.underline,
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
        );
      },
    );
  }
}
