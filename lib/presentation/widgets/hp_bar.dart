import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class HPBar extends StatefulWidget {
  final int currentHp;
  final int maxHp;
  final String pokemonName;
  final bool isOpponent;

  const HPBar({
    Key? key,
    required this.currentHp,
    required this.maxHp,
    required this.pokemonName,
    this.isOpponent = false,
  }) : super(key: key);

  @override
  State<HPBar> createState() => _HPBarState();
}

class _HPBarState extends State<HPBar> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<int> _hpAnimation;

  int _displayHp = 0;

  @override
  void initState() {
    super.initState();
    _displayHp = widget.currentHp;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(HPBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentHp != widget.currentHp) {
      _hpAnimation =
          IntTween(begin: _displayHp, end: widget.currentHp).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.linear),
      );

      _hpAnimation.addListener(() {
        setState(() {
          _displayHp = _hpAnimation.value;
        });
      });

      _animationController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getHpColor() {
    if (widget.maxHp == 0) return AppColors.hpHealthy;
    final percentage = _displayHp / widget.maxHp;
    if (percentage > 0.5) {
      return AppColors.hpHealthy;
    } else if (percentage > 0.25) {
      return AppColors.hpWarning;
    } else {
      return AppColors.hpCritical;
    }
  }

  @override
  Widget build(BuildContext context) {
    final percentage = (_displayHp / widget.maxHp).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment:
          widget.isOpponent ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(
          widget.pokemonName,
          style: const TextStyle(
            color: AppColors.lightGray,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            if (widget.isOpponent) ...[
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(
                    children: [
                      Container(
                        height: 20,
                        color: AppColors.darkGray,
                      ),
                      FractionallySizedBox(
                        widthFactor: percentage,
                        child: Container(
                          height: 20,
                          color: _getHpColor(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_displayHp}/${widget.maxHp}',
                style: const TextStyle(
                  color: AppColors.lightGray,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ] else ...[
              Text(
                '${_displayHp}/${widget.maxHp}',
                style: const TextStyle(
                  color: AppColors.lightGray,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(
                    children: [
                      Container(
                        height: 20,
                        color: AppColors.darkGray,
                      ),
                      FractionallySizedBox(
                        widthFactor: percentage,
                        child: Container(
                          height: 20,
                          color: _getHpColor(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ]
          ],
        ),
      ],
    );
  }
}
