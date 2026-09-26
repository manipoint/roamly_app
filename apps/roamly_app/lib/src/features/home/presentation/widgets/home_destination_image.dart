import 'package:flutter/material.dart';
import 'package:roamly_ui/roamly_ui.dart';

import '../../domain/entities/destination.dart';

class HomeDestinationImage extends StatelessWidget {
  const HomeDestinationImage({super.key, required this.destination});
  final Destination destination;

  @override
  Widget build(BuildContext context) {
    return RoamlyNetworkImage(
      uri: destination.imageUri,
      altText: destination.imageAlt,
      fit: BoxFit.cover,
    );
  }
}
