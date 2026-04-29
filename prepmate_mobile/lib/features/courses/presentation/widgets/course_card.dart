import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../data/models/course_model.dart';

class CourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback onTap;

  const CourseCard({super.key, required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(right: 16, bottom: 8),
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    course.thumbnail,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 120,
                      color: colors.mutedBackground,
                      child: Icon(Icons.image_not_supported, color: colors.textSecondary),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.cardBackground.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getIconForType(course.type),
                          size: 14,
                          color: _getColorForType(course.type),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getTextForType(course.type),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getColorForType(course.type),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: colors.cardBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.bookmark_border, size: 16, color: colors.textSecondary),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getDetailText(course),
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        '${course.rating} (${course.reviewCount ?? 0})',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colors.textPrimary),
                      ),
                      const Spacer(),
                      if (course.isOpened)
                        const Icon(Icons.check_circle, size: 16, color: Colors.green)
                      else
                        Icon(Icons.more_vert, size: 16, color: colors.textSecondary),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDetailText(Course course) {
    switch (course.type) {
      case CourseType.pdf:
        return '${course.lessonsCount} pages';
      case CourseType.playlist:
        return '${course.duration} • ${course.lessonsCount} videos';
      case CourseType.youtubeVideo:
        return '${course.duration} • ${course.lessonsCount} lesson';
      default:
        return '${course.duration} • ${course.lessonsCount} lessons';
    }
  }

  IconData _getIconForType(CourseType type) {
    switch (type) {
      case CourseType.youtubeVideo:
        return Icons.play_circle_fill;
      case CourseType.playlist:
        return Icons.playlist_play;
      case CourseType.pdf:
        return Icons.picture_as_pdf;
      default:
        return Icons.link;
    }
  }

  Color _getColorForType(CourseType type) {
    switch (type) {
      case CourseType.youtubeVideo:
        return Colors.red;
      case CourseType.playlist:
        return Colors.green;
      case CourseType.pdf:
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  String _getTextForType(CourseType type) {
    switch (type) {
      case CourseType.youtubeVideo:
        return 'YOUTUBE VIDEO';
      case CourseType.playlist:
        return 'PLAYLIST';
      case CourseType.pdf:
        return 'PDF DOCUMENT';
      default:
        return 'RESOURCE';
    }
  }
}
