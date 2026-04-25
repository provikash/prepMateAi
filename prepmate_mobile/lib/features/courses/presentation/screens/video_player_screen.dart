import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../data/models/course_model.dart';
import '../providers/course_providers.dart';

class VideoPlayerScreen extends ConsumerStatefulWidget {
  final Course course;

  const VideoPlayerScreen({super.key, required this.course});

  @override
  ConsumerState<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends ConsumerState<VideoPlayerScreen> {
  late YoutubePlayerController _controller;
  bool _isPlayerReady = false;

  @override
  void initState() {
    super.initState();
    final videoId = YoutubePlayer.convertUrlToId(widget.course.url);
    
    _controller = YoutubePlayerController(
      initialVideoId: videoId ?? '',
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
      ),
    )..addListener(_listener);
  }

  void _listener() {
    if (_isPlayerReady && mounted && !_controller.value.isFullScreen) {
      final position = _controller.value.position.inSeconds;
      final duration = _controller.metadata.duration.inSeconds;

      if (duration > 0) {
        final percentage = ((position / duration) * 100).toInt();
        ref.read(openedCoursesProvider.notifier).updateProgress(
              widget.course.id,
              percentage,
            );
      }
    }
  }

  @override
  void deactivate() {
    _controller.pause();
    super.deactivate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      onExitFullScreen: () {
        // Handle exit full screen if needed
      },
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Colors.blueAccent,
        topActions: <Widget>[
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              _controller.metadata.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18.0,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
        onReady: () {
          _isPlayerReady = true;
          ref.read(openedCoursesProvider.notifier).markAsOpened(widget.course.id);
        },
      ),
      builder: (context, player) => Scaffold(
        appBar: AppBar(
          title: Text(widget.course.title),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: Column(
          children: [
            player,
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.course.title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.course.duration} • ${widget.course.lessonsCount} lessons',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const Divider(height: 32),
                  const Text(
                    "About this Course",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "This course provides a comprehensive overview of the subject matter. "
                    "Follow along with the video and practical exercises to master these skills.",
                    style: TextStyle(color: Colors.black87, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
