import 'package:flutter/material.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key, required this.title, this.actions, this.bottom});

  final String title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize => Size.fromHeight(bottom == null ? 100 : 100 + bottom!.preferredSize.height);

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  @override
  Widget build(BuildContext context) {
    return SliverAppBar.large(
      pinned: true,
      automaticallyImplyLeading: false,
      elevation: 0,
      surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shadowColor: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
      actions: widget.actions,
      title: Text(
        widget.title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
      ),
    );
  }
}
