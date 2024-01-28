import 'package:flutter/material.dart';

class StandardText extends StatelessWidget {
  final String text;
  final double size;
  final Color color;
  final double letterSpacing;
  final TextAlign textAlign;
  final FontWeight weight;
  final double lineHeight;
  final bool isUnderlined;
  final bool isStrikethrough;

  const StandardText({
    Key key,
    this.text,
    this.size,
    this.color,
    this.letterSpacing,
    this.textAlign,
    this.weight,
    this.lineHeight,
    this.isUnderlined = false,
    this.isStrikethrough = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    TextDecoration defaultTextDecoration = TextDecoration.none;
    if(isUnderlined) defaultTextDecoration = TextDecoration.underline;
    if(isStrikethrough) defaultTextDecoration = TextDecoration.lineThrough;
    return Text(
      text,
      style: TextStyle(
        decoration: defaultTextDecoration,
        shadows: isUnderlined ? [
          Shadow(
              color: color,
              offset: Offset(0, -6))
        ] : null,
        decorationColor: color,
        height: lineHeight,
        fontStyle: FontStyle.normal,
        color: isUnderlined ?
        Colors.transparent :
        color != null ? color : Colors.black,
        fontSize: size,
        fontWeight: weight != null ? weight : null,
        letterSpacing: letterSpacing != null ? letterSpacing : 1,
      ),
      textAlign: textAlign != null ? textAlign : TextAlign.center,
    );
  }
}
