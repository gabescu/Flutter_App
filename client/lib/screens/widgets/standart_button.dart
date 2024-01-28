import 'package:client/screens/widgets/standard_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';


class StandardButton extends StatelessWidget {
  final String text;
  final Function onPressed;

  const StandardButton({Key key, this.text, this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.purple,
        borderRadius: BorderRadius.all(Radius.circular(4.r)),
      ),
      height: 48.h,
      child: TextButton(
        onPressed: onPressed,
        child: StandardText(
          text: text,
          color: Colors.white,
          weight: FontWeight.normal,
          size: 18.sp,
        ),
      ),
    );
  }

}