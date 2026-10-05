import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prepmate_mobile/config/theme.dart';
import '../../providers/home_providers.dart';
import '../../data/models/resume_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class ResumeHorizontalList extends ConsumerWidget {
  const ResumeHorizontalList({super.key});

  static const _circleSize = 64.0;
  static const _labelWidth = 78.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resumesAsync = ref.watch(resumeListProvider);

    return SizedBox(
      height: 108,
      child: resumesAsync.when(
        data: (resumes) => ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.zero,
          itemCount: resumes.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildAddResumeButton(context);
            }
            final resume = resumes[index - 1];
            return ResumeItemWidget(resume: resume);
          },
        ),
        loading: () => _buildLoadingShimmer(),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildAddResumeButton(BuildContext context) {
    final colors = AppColors.of(context);

    return GestureDetector(
      onTap: () => context.push('/template'),
      child: Padding(
        padding: const EdgeInsets.only(right: 16.0),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: _circleSize,
                  height: _circleSize,
                  decoration: BoxDecoration(
                    color: colors.iconSoftBackground,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.border, width: 1.4),
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    color: colors.textSecondary,
                    size: 24,
                  ),
                ),
                Positioned(
                  right: -1,
                  bottom: -1,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Add Resume',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Column(
            children: [
              Container(
                width: _circleSize,
                height: _circleSize,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 8),
              Container(width: 50, height: 10, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class ResumeItemWidget extends StatelessWidget {
  final ResumeModel resume;

  const ResumeItemWidget({super.key, required this.resume});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return GestureDetector(
      onTap: () => context.push('/resume/pdf/${resume.id}'),
      child: Padding(
        padding: const EdgeInsets.only(right: 16.0),
        child: Column(
          children: [
            Container(
              width: ResumeHorizontalList._circleSize,
              height: ResumeHorizontalList._circleSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.mutedBackground,
                border: Border.all(color: colors.primary, width: 2),
              ),
              child: ClipOval(
                child: resume.thumbnailUrl.isEmpty
                    ? const _ResumeFallbackArt()
                    : CachedNetworkImage(
                        imageUrl: resume.thumbnailUrl,
                        placeholder: (context, url) =>
                            const _ResumeFallbackArt(),
                        errorWidget: (context, url, error) =>
                            const _ResumeFallbackArt(),
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: ResumeHorizontalList._labelWidth,
              child: Text(
                resume.title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumeFallbackArt extends StatelessWidget {
  const _ResumeFallbackArt();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      color: colors.mutedBackground,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            _ArtLine(width: 30),
            SizedBox(height: 4),
            _ArtLine(width: 34),
            SizedBox(height: 4),
            _ArtLine(width: 26),
          ],
        ),
      ),
    );
  }
}

class _ArtLine extends StatelessWidget {
  final double width;

  const _ArtLine({required this.width});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      width: width,
      height: 3,
      decoration: BoxDecoration(
        color: colors.textSecondary,
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}
