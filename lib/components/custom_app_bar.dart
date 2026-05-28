import 'package:flutter/material.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key, required this.title, this.bottom});

  final String title;
  final PreferredSizeWidget? bottom;

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(100 + (bottom?.preferredSize.height ?? 0));
}

class _CustomAppBarState extends State<CustomAppBar> {
  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      automaticallyImplyLeading: false,
      expandedHeight: 100 + (widget.bottom?.preferredSize.height ?? 0),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.symmetric(
          horizontal: 20,
          vertical: widget.bottom != null ? 0 : 16,
        ),
        title: Text(
          widget.title,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium!.color,
          ),
        ),
      ),
      bottom: widget.bottom,
    );
  }
}
