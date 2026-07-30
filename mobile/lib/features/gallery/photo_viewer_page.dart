import 'package:flutter/material.dart';

/// Цял екран преглед на снимки от галерия (напр. минало събитие), с pinch-to-zoom
/// и плъзгане между снимките.
class PhotoViewerPage extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final String heroTagPrefix;

  const PhotoViewerPage({
    super.key,
    required this.images,
    this.initialIndex = 0,
    required this.heroTagPrefix,
  });

  @override
  State<PhotoViewerPage> createState() => _PhotoViewerPageState();
}

class _PhotoViewerPageState extends State<PhotoViewerPage> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToPrevious() {
    _controller.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _goToNext() {
    _controller.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, index) {
              final image = widget.images[index];
              return Center(
                child: Hero(
                  tag: '${widget.heroTagPrefix}_$image',
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: Image.asset(
                      image,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white54,
                        size: 64,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  if (widget.images.length > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_index + 1} / ${widget.images.length}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (widget.images.length > 1) ...[
            Positioned(
              left: 4,
              top: 0,
              bottom: 0,
              child: Center(
                child: _NavArrowButton(
                  icon: Icons.chevron_left,
                  onPressed: _index > 0 ? _goToPrevious : null,
                ),
              ),
            ),
            Positioned(
              right: 4,
              top: 0,
              bottom: 0,
              child: Center(
                child: _NavArrowButton(
                  icon: Icons.chevron_right,
                  onPressed: _index < widget.images.length - 1
                      ? _goToNext
                      : null,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Кръгла полупрозрачна стрелка за пред/назад в галерията. `onPressed: null`
/// я показва избледняла и неактивна (на първата/последната снимка).
class _NavArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _NavArrowButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Container(
      decoration: BoxDecoration(
        color: Colors.black45,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: enabled ? Colors.white : Colors.white30,
          size: 32,
        ),
        onPressed: onPressed,
      ),
    );
  }
}
