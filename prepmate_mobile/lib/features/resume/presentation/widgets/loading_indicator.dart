import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  final String? label;
  const LoadingIndicator({Key? key, this.label}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (label != null) ...[const SizedBox(height: 12), Text(label!)],
        ],
      ),
    );
  }
}
