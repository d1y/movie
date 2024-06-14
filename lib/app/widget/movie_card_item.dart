import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:movie/app/widget/helper.dart';

class MovieCardItem extends StatefulWidget {
  final String imageUrl;

  final String title;

  final VoidCallback onTap;

  const MovieCardItem({
    Key? key,
    required this.imageUrl,
    required this.title,
    required this.onTap,
  }) : super(key: key);

  @override
  _MovieCardItemState createState() => _MovieCardItemState();
}

class _MovieCardItemState extends State<MovieCardItem> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      mouseCursor: SystemMouseCursors.click,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: CachedNetworkImage(
                  imageUrl: widget.imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  progressIndicatorBuilder: (context, url, progress) => Center(
                    child: CircularProgressIndicator(
                      value: progress.progress,
                    ),
                  ),
                  errorWidget: (context, error, stackTrace) => kErrorImage,
                ),
              ),
            ),
            const SizedBox(height: 9),
            Text(
              widget.title,
              maxLines: 1,
              style: TextStyle(
                fontSize: 12,
                color: Get.isDarkMode ? Colors.white : Colors.black,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
