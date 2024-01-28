import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';


class SimpleDropDown extends StatefulWidget{
  final List<String> elements;
  final String initialMessage;
  final String firstSelected;
  final bool extendsWords;
  final Function onSelectedElement;

  SimpleDropDown({
    this.elements,
    this.initialMessage,
    this.firstSelected,
    this.onSelectedElement,
    this.extendsWords = false,
  });

  @override
  State<StatefulWidget> createState() => _SimpleDropDownState();
}

class _SimpleDropDownState extends State<SimpleDropDown> {
  int _currentIdx = 0;
  bool _showInitialMessageFirst = true;

  @override
  Widget build(BuildContext context) {
    String initialValue;
    if (widget.initialMessage == null) {
      if (widget.firstSelected != null) {
        _currentIdx = widget.elements.indexOf(widget.firstSelected);
        if (_currentIdx < 0) _currentIdx = 0;
      }
      initialValue = widget.elements[_currentIdx];
    } else {
      !_showInitialMessageFirst ? initialValue = widget.elements[_currentIdx] : initialValue = null;
    }
    return DropdownButton<String>(
      isDense: true,
      selectedItemBuilder: (context) {
        return [
          for (var string in widget.elements)
            Padding(
              padding: EdgeInsets.only(
                  left: 16.w
              ),
              child: Text(string,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16.sp,
                ),
              ),
            )
        ];
      },
      hint: widget.initialMessage != null ? Padding(
          padding: EdgeInsets.only(
            left: 16.w,
          ),
          child: Text(
            widget.initialMessage,
            style: TextStyle(
                color: Colors.black,
                fontSize: 16.sp,
                fontStyle: FontStyle.italic
            ),
          )
      ) : null,
      iconEnabledColor: Colors.black,
      iconDisabledColor: Colors.grey,
      icon: Padding(
        padding: EdgeInsets.only(right: 16.w),
        child: Icon(Icons.arrow_drop_down),
      ),
      value: initialValue,
      iconSize: 24.w,
      elevation: 0,
      style: TextStyle(
        color: Colors.black,
        fontSize: 16.sp,
      ),
      onChanged: (String selectedName) {
        FocusScope.of(context).requestFocus(FocusNode());
        setState(() {
          _showInitialMessageFirst = false;
          _currentIdx = widget.elements.indexOf(selectedName);
        });
        var selectedElement = widget.elements[_currentIdx];
        widget.onSelectedElement(selectedElement);
      },
      items: widget.elements.map<DropdownMenuItem<String>>((e)
      {
        return DropdownMenuItem(
          value: e,
          child: Text(e.replaceAll(" ", ""),
            style: TextStyle(
              color: Colors.black,
              fontSize: 16.sp,
            ),
          ),
        );
      }).toList(),
    );
  }
}