import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/grid_persona.dart';
import '../providers/news_provider.dart';

class PersonaSelector extends StatelessWidget {
  const PersonaSelector({super.key});

  void _showPersonaBottomSheet(BuildContext context, NewsProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.tune_rounded, color: Color(0xFF2563EB), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Your Power Sector Role',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Tailors feed priority, highlights & executive metrics',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: GridPersona.values.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final persona = GridPersona.values[idx];
                    final isSelected = provider.selectedPersona == persona;

                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        provider.setPersona(persona);
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? persona.badgeColor.withOpacity(isDark ? 0.25 : 0.12)
                              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? persona.badgeColor
                                : (isDark ? Colors.white10 : Colors.black12),
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: persona.badgeColor.withOpacity(0.18),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(persona.icon, color: persona.badgeColor, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        persona.title,
                                        style: TextStyle(
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                          fontSize: 14,
                                          color: isSelected ? persona.badgeColor : null,
                                        ),
                                      ),
                                      if (isSelected) ...[
                                        const SizedBox(width: 6),
                                        Icon(Icons.check_circle_rounded, size: 16, color: persona.badgeColor),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    persona.subtitle,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NewsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentPersona = provider.selectedPersona;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        children: [
          // Role Persona Quick Selector Button / Icon
          InkWell(
            onTap: () => _showPersonaBottomSheet(context, provider),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: currentPersona == GridPersona.all
                    ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF))
                    : currentPersona.badgeColor.withOpacity(isDark ? 0.25 : 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: currentPersona == GridPersona.all
                      ? const Color(0xFF2563EB).withOpacity(0.4)
                      : currentPersona.badgeColor,
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    currentPersona.icon,
                    size: 15,
                    color: currentPersona == GridPersona.all
                        ? const Color(0xFF2563EB)
                        : currentPersona.badgeColor,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Role: ${currentPersona.shortLabel}',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: currentPersona == GridPersona.all
                          ? const Color(0xFF2563EB)
                          : currentPersona.badgeColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    size: 16,
                    color: currentPersona == GridPersona.all
                        ? const Color(0xFF2563EB)
                        : currentPersona.badgeColor,
                  ),
                ],
              ),
            ),
          ),

          // Quick Persona Chips
          ...GridPersona.values.map((persona) {
            final isSelected = currentPersona == persona;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                showCheckmark: false,
                avatar: Icon(
                  persona.icon,
                  size: 13,
                  color: isSelected ? Colors.white : persona.badgeColor,
                ),
                label: Text(
                  persona.shortLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.grey[300] : const Color(0xFF334155)),
                  ),
                ),
                selected: isSelected,
                onSelected: (val) {
                  if (val) {
                    provider.setPersona(persona);
                  } else {
                    provider.setPersona(GridPersona.all);
                  }
                },
                selectedColor: persona.badgeColor,
                backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isSelected
                        ? persona.badgeColor
                        : (isDark ? Colors.white10 : Colors.black.withOpacity(0.06)),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            );
          }),
        ],
      ),
    );
  }
}
