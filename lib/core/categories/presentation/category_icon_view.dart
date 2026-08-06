import 'package:flutter/material.dart';

import '../../assets/prepared_vector_asset_atlas.dart';

class CategoryIconView extends StatelessWidget {
  const CategoryIconView({
    required this.picture,
    this.size = 24,
    this.color,
    this.semanticsLabel,
    super.key,
  });

  final PreparedVectorPicture picture;
  final double size;
  final Color? color;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) => PreparedVectorPictureView(
    picture: picture,
    width: size,
    height: size,
    fit: BoxFit.contain,
    color: color,
    semanticsLabel: semanticsLabel,
  );
}
