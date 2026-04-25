import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/home_providers.dart';
import '../../data/models/resume_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class ResumeHorizontalList extends ConsumerWidget {
  const ResumeHorizontalList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resumesAsync = ref.watch(resumeListProvider);

    return SizedBox(
      height: 100,
      child: resumesAsync.when(
        data: (resumes) => ListView.builder(
          scrollDirection: Axis.horizontal,
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
    return GestureDetector(
      onTap: () => context.push('/template'),
      child: Padding(
        padding: const EdgeInsets.only(right: 16.0),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Icon(Icons.add, color: Colors.blue, size: 30),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add Resume',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
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
                width: 60,
                height: 60,
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
    return GestureDetector(
      onTap: () => context.push('/resume-view', extra: resume.pdfUrl),
      child: Padding(
        padding: const EdgeInsets.only(right: 16.0),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blue.shade200, width: 2),
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: resume.thumbnailUrl,
                  placeholder: (context, url) =>
                      Container(color: Colors.grey.shade200),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.description, color: Colors.blue),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 70,
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
