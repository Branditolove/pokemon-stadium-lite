import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class BattleLog extends StatefulWidget {
  final List<String> messages;
  final int maxMessages;

  const BattleLog({
    Key? key,
    required this.messages,
    this.maxMessages = 5,
  }) : super(key: key);

  @override
  State<BattleLog> createState() => _BattleLogState();
}

class _BattleLogState extends State<BattleLog> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void didUpdateWidget(BattleLog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.messages.length != widget.messages.length) {
      Future.microtask(() {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayMessages = widget.messages.length > widget.maxMessages
        ? widget.messages.sublist(
            widget.messages.length - widget.maxMessages,
            widget.messages.length,
          )
        : widget.messages;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkGray,
        border: Border.all(
          color: AppColors.pokemonRed,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'REGISTRO DE BATALLA',
            style: TextStyle(
              color: AppColors.pokemonRed,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(color: AppColors.pokemonRed, height: 12),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: displayMessages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    displayMessages[index],
                    style: const TextStyle(
                      color: AppColors.lightGray,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
