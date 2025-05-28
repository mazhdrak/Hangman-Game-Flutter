import 'package:flutter/material.dart';
import 'package:hangman/utilities/constants.dart';

class WordButton extends StatelessWidget {
  const WordButton({
    super.key,
    required this.buttonTitle,
    this.onPress,
    this.buttonStatus = true, // Added this parameter with a default value
  });

  final VoidCallback? onPress;
  final String buttonTitle;
  final bool buttonStatus; // Added this field

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        elevation: 3.0,
        backgroundColor: buttonStatus ? kWordButtonColor : Colors.grey.shade700, // Change color if disabled
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(4.0),
      ),
      // If buttonStatus is false, set onPressed to null to disable the button
      onPressed: buttonStatus ? onPress : null,
      child: Text(
        buttonTitle,
        textAlign: TextAlign.center,
        style: buttonStatus
            ? kWordButtonTextStyle
            : kWordButtonTextStyle.copyWith(
          color: Colors.grey.shade400, // Change text color if disabled
          decoration: TextDecoration.lineThrough, // Optional: add line-through
        ),
      ),
    );
  }
}