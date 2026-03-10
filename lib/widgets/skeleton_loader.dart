import 'package:flutter/material.dart';
import '../theme/owany_theme.dart';

class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const SkeletonLoader({
    super.key,
    this.width = double.infinity,
    this.height = 20,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this)..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [OwanyTheme.surface, OwanyTheme.borderColor(context), OwanyTheme.surface],
              stops: [0.0, _animationController.value, 1.0],
            ),
          ),
        );
      },
    );
  }
}

class SkeletonListLoader extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const SkeletonListLoader({super.key, this.itemCount = 5, this.itemHeight = 60});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: OwanyTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: OwanyTheme.borderColor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonLoader(width: double.infinity, height: 16),
              SizedBox(height: 8),
              SkeletonLoader(width: 200, height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class SkeletonGridLoader extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;

  const SkeletonGridLoader({super.key, this.itemCount = 6, this.crossAxisCount = 2});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => Container(
        decoration: BoxDecoration(
          color: OwanyTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: OwanyTheme.borderColor(context)),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            SkeletonLoader(height: 80, borderRadius: BorderRadius.circular(8)),
            SizedBox(height: 10),
            SkeletonLoader(width: double.infinity, height: 12),
            SizedBox(height: 6),
            SkeletonLoader(width: 100, height: 10),
          ],
        ),
      ),
    );
  }
}
