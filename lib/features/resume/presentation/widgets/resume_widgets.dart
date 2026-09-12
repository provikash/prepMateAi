import 'package:flutter/material.dart';
import '../../../../config/theme.dart';

class SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final VoidCallback? onAdd;

  const SectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Card(
      elevation: 0,
      color: colors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colors.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (onAdd != null)
                  TextButton.icon(
                    onPressed: onAdd,
                    icon: Icon(Icons.add, size: 18, color: colors.primary),
                    label: Text(
                      'Add',
                      style: TextStyle(
                        color: colors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class ExperienceCard extends StatelessWidget {
  final String title;
  final String company;
  final String duration;
  final String location;
  final List<String> bullets;

  const ExperienceCard({
    super.key,
    required this.title,
    required this.company,
    required this.duration,
    required this.location,
    required this.bullets,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        Text(
          company,
          style: TextStyle(fontSize: 14, color: colors.textSecondary),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              duration,
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
            const Spacer(),
            Icon(
              Icons.location_on,
              size: 14,
              color: colors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(width: 4),
            Text(
              location,
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...bullets.map(
          (bullet) => Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "• ",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
                Expanded(
                  child: Text(
                    bullet,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class AIButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;

  const AIButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [colors.primary, colors.primary.withOpacity(0.8)],
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
