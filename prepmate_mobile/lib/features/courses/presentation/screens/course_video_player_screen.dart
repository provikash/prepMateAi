import 'package:prepmate_mobile/core/widgets/app_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../data/models/ai_course_model.dart';
import '../providers/course_providers.dart';

class CourseVideoPlayerScreen extends ConsumerStatefulWidget {
  final AICourse course;

  const CourseVideoPlayerScreen({super.key, required this.course});

  @override
  ConsumerState<CourseVideoPlayerScreen> createState() =>
      _CourseVideoPlayerScreenState();
}

class _CourseVideoPlayerScreenState
    extends ConsumerState<CourseVideoPlayerScreen>
    with WidgetsBindingObserver {
  late YoutubePlayerController _youtubeController;
  late Duration _lastReportedPosition;
  late CourseProgressNotifier _progressNotifier;
  DateTime _lastReport = DateTime.fromMillisecondsSinceEpoch(0);
  bool _reporting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _progressNotifier = ref.read(
      courseProgressProvider(widget.course.videoId).notifier,
    );
    _initializePlayer();
    _lastReportedPosition = Duration.zero;
  }

  void _initializePlayer() {
    _youtubeController = YoutubePlayerController(
      initialVideoId: widget.course.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
      ),
    );

    // Listen to player state changes and track progress
    _youtubeController.addListener(_onPlayerStateChanged);
  }

  void _onPlayerStateChanged() {
    if (_youtubeController.value.isPlaying) {
      _trackProgress();
    }
  }

  Future<void> _trackProgress({bool force = false}) async {
    // Report progress every 5-10 seconds
    final currentPosition = _youtubeController.value.position;
    final totalDuration = _youtubeController.metadata.duration;

    // Only report if position changed significantly (at least 5 seconds)
    if (totalDuration.inSeconds <= 0 || _reporting) return;
    if (force ||
        (DateTime.now().difference(_lastReport).inSeconds >= 30 &&
            currentPosition != _lastReportedPosition)) {
      _lastReportedPosition = currentPosition;
      _lastReport = DateTime.now();
      _reporting = true;

      // Update progress on backend
      try {
        await _progressNotifier.updateProgress(
          watchedSeconds: currentPosition.inSeconds.clamp(
            0,
            totalDuration.inSeconds,
          ),
          totalSeconds: totalDuration.inSeconds,
        );
      } finally {
        _reporting = false;
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _youtubeController.pause();
      _trackProgress(force: true);
    }
  }

  @override
  void dispose() {
    _trackProgress(force: true);
    WidgetsBinding.instance.removeObserver(this);
    _youtubeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progressAsync = ref.watch(
      courseProgressProvider(widget.course.videoId),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          widget.course.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // YouTube Player
          Container(
            color: Colors.black,
            child: YoutubePlayer(
              controller: _youtubeController,
              showVideoProgressIndicator: true,
              progressIndicatorColor: Colors.red,
              progressColors: ProgressBarColors(
                playedColor: Colors.red,
                handleColor: Colors.redAccent,
                bufferedColor: Colors.grey,
                backgroundColor: Colors.grey[800],
              ),
              onReady: () async {
                try {
                  final progress = await ref.read(
                    courseProgressProvider(widget.course.videoId).future,
                  );
                  if (mounted &&
                      progress.watchedSeconds > 0 &&
                      !progress.isCompleted) {
                    _youtubeController.seekTo(
                      Duration(seconds: progress.watchedSeconds),
                    );
                  }
                } catch (_) {
                  /* Playback remains available without saved progress. */
                }
              },
            ),
          ),

          // Video Info and Progress
          Expanded(
            child: progressAsync.when(
              data: (progress) {
                return SingleChildScrollView(
                  child: Container(
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.course.title,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.course.channel,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Progress Bar
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Watch Progress',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      Text(
                                        '${progress.watchPercentage.toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: progress.watchPercentage / 100,
                                      minHeight: 6,
                                      backgroundColor: Colors.grey[300],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF7C3AED),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${_formatDuration(Duration(seconds: progress.watchedSeconds))} / '
                                    '${_formatDuration(Duration(seconds: progress.totalSeconds))}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        Divider(),

                        // Match Score
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Color(0xFFF0E7FF),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Color(0xFFD4B3FF),
                                width: 1,
                              ),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Match Score',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF7C3AED),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'How well this matches your skill gaps',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF7C3AED),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${widget.course.matchScore.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Completion Status
                        if (progress.isCompleted)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Color(0xFFC8E6C9),
                                  width: 1,
                                ),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Congratulations! You completed this course!',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green[800],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                );
              },
              loading: () => Center(child: AppLoading()),
              error: (error, stack) => Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading progress: $error',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    }
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}
