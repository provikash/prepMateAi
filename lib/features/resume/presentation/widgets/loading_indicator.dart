import 'package:prepmate_mobile/core/widgets/app_loading.dart';
import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  final String? label;
  const LoadingIndicator({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppLoading(),
          if (label != null) ...[const SizedBox(height: 12), Text(label!)],
        ],
      ),
    );
  }
}
