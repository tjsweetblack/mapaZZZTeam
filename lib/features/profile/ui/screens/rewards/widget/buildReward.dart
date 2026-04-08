import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

Widget buildRewardItem({
  required String image,
  required String title,
  required int points,
  required String buttonText,
  required Color buttonColor,
  required VoidCallback? onPressed,
  Color? strokeColor,
}) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10.0),
      border: Border.all(
        color: strokeColor ?? Colors.grey.shade300,
        width: strokeColor != null ? 2.0 : 1.0,
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Center(
            child: Container(
              height: 80.0,
              child: image.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: image,
                      imageBuilder: (context, imageProvider) => Image(
                        image: imageProvider,
                        fit: BoxFit.contain, // Control image scaling
                        semanticLabel: title, // Accessibility for the image
                      ),
                      progressIndicatorBuilder:
                          (context, url, downloadProgress) => Center(
                        child: CircularProgressIndicator(
                            value: downloadProgress.progress),
                      ),
                      errorWidget: (context, url, error) => const Icon(
                        Icons.image_not_supported,
                        size: 50,
                        color: Colors.grey,
                        semanticLabel:
                            'Image not available', // Accessibility for error
                      ),
                    )
                  : const Icon(
                      Icons.card_giftcard,
                      size: 50,
                      color: Colors.grey,
                      semanticLabel:
                          'Reward placeholder', // Accessibility for placeholder
                    ),
            ),
          ),
          const SizedBox(height: 16.0),
          const Text(
            'Nome:',
            style:
                TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          Text(title, style: const TextStyle(color: Colors.black87)),
          const SizedBox(height: 8.0),
          Row(
            children: <Widget>[
              const Icon(
                Icons.star,
                color: Colors.red,
                size: 20.0,
              ),
              const SizedBox(width: 4.0),
              Text('pontos necessario: $points pontos',
                  style: const TextStyle(color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 16.0),
          Align(
            alignment: Alignment.bottomLeft,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
              child: Text(buttonText),
            ),
          ),
        ],
      ),
    ),
  );
}
