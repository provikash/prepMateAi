import 'package:flutter/material.dart';

/// A bundled, data-backed thumbnail used when a server thumbnail is not yet
/// cached. It mirrors the real résumé structure instead of showing a generic
/// document placeholder, and therefore remains available in flight mode.
class TemplateSamplePreview extends StatelessWidget {
  const TemplateSamplePreview({
    super.key,
    required this.templateId,
    this.compact = false,
  });

  final String templateId;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final accent = templateId.contains('modern')
        ? const Color(0xFF0F766E)
        : templateId.contains('simple')
        ? const Color(0xFF374151)
        : const Color(0xFF2457D6);
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = (constraints.maxWidth / 360).clamp(.32, 1.2);
        return Container(
          color: Colors.white,
          padding: EdgeInsets.all((compact ? 18 : 24) * scale),
          child: DefaultTextStyle(
            style: TextStyle(
              color: const Color(0xFF202938),
              fontSize: 10 * scale,
              height: 1.2,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ALEX MORGAN',
                  style: TextStyle(
                    color: accent,
                    fontSize: 22 * scale,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .5,
                  ),
                ),
                SizedBox(height: 2 * scale),
                Text(
                  'PRODUCT DESIGNER  |  alex@example.com  |  Colombo',
                  maxLines: 1,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 7.5 * scale,
                  ),
                ),
                SizedBox(height: 10 * scale),
                Divider(color: accent, thickness: 1.4 * scale, height: 1),
                _section('PROFILE', accent, scale),
                _lines(scale, const [1, .95, .72]),
                _section('EXPERIENCE', accent, scale),
                _entry(
                  'Senior Product Designer',
                  'Example Studio  |  2022 - Present',
                  scale,
                ),
                _lines(scale, const [.96, .82]),
                _section('EDUCATION', accent, scale),
                _entry(
                  'BSc Interaction Design',
                  'Example University  |  2021',
                  scale,
                ),
                _section('SKILLS', accent, scale),
                Wrap(
                  spacing: 4 * scale,
                  runSpacing: 4 * scale,
                  children: const ['Research', 'Prototyping', 'Design systems']
                      .map(
                        (label) => Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 5 * scale,
                            vertical: 2.5 * scale,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: .09),
                            borderRadius: BorderRadius.circular(3 * scale),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(fontSize: 7 * scale),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _section(String text, Color accent, double scale) => Padding(
    padding: EdgeInsets.only(top: 12 * scale, bottom: 5 * scale),
    child: Text(
      text,
      style: TextStyle(
        color: accent,
        fontSize: 9 * scale,
        fontWeight: FontWeight.w800,
        letterSpacing: .8,
      ),
    ),
  );

  Widget _entry(String title, String subtitle, double scale) => Padding(
    padding: EdgeInsets.only(bottom: 5 * scale),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 9 * scale, fontWeight: FontWeight.w700),
        ),
        Text(
          subtitle,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 7 * scale),
        ),
      ],
    ),
  );

  Widget _lines(double scale, List<double> widths) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: widths
        .map(
          (width) => FractionallySizedBox(
            widthFactor: width,
            child: Container(
              height: 3 * scale,
              margin: EdgeInsets.only(bottom: 3 * scale),
              decoration: BoxDecoration(
                color: const Color(0xFFDDE2EA),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        )
        .toList(),
  );
}
