import 'package:flutter/material.dart';
import 'shimmer_loading.dart';

/// Generic loading widget that uses ShimmerBlock from shimmer_loading.dart.
///
/// - If [listMode] is true shows a vertical list-style skeleton (useful for list pages).
/// - Otherwise shows a centered pill-style shimmer suitable for auth/initial loading.
class LoadingWidget extends StatelessWidget {
  final bool listMode;
  final int itemCount;
  final double centeredWidth;
  final double centeredHeight;
  final EdgeInsetsGeometry padding;

  const LoadingWidget({
    Key? key,
    this.listMode = false,
    this.itemCount = 6,
    this.centeredWidth = 240,
    this.centeredHeight = 20,
    this.padding = const EdgeInsets.all(12),
  }) : super(key: key);

  Widget _buildListSkeleton(BuildContext context) {
    return ListView.separated(
      padding: padding as EdgeInsets?,
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShimmerBlock(
              width: 64,
              height: 64,
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerBlock(
                    width: double.infinity,
                    height: 14,
                    borderRadius: BorderRadius.all(Radius.circular(6)),
                    margin: EdgeInsets.only(bottom: 8),
                  ),
                  const ShimmerBlock(
                    width: 160,
                    height: 12,
                    borderRadius: BorderRadius.all(Radius.circular(6)),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (listMode) {
      return Padding(
        padding: padding,
        child: _buildListSkeleton(context),
      );
    }

    return Center(
      child: ShimmerBlock(
        width: centeredWidth,
        height: centeredHeight,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}