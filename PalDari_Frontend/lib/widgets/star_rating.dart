import 'package:flutter/material.dart';

class StarRating extends StatelessWidget {
  final int value; // 선택된 점수
  final int max; // 최대 별 개수 (기본 5)
  final double size;
  final ValueChanged<int> onChanged;

  const StarRating({
    Key? key,
    required this.value,
    this.max = 5,
    this.size = 32,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(max, (index) {
        final starIndex = index + 1;
        final selected = starIndex <= value;

        return IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () => onChanged(starIndex),
          icon: Icon(
            selected ? Icons.star : Icons.star_border,
          ),
          iconSize: size,
        );
      }),
    );
  }
}
