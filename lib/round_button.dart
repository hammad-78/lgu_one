import 'package:flutter/material.dart';

class RoundButton extends StatelessWidget {

  final String title;
  final VoidCallback ontap;
  final double width;
  const RoundButton({super.key,
    required this.title,
    required this.ontap,
    required this.width
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: ontap,
      child: Container(
        height: 50,
        width: width,
        decoration: BoxDecoration(
            color: Color(0xFF4CAF50),
            borderRadius:BorderRadius.circular(10)
        ),
        child: Center(
            child: Text(title,
              style: TextStyle(color: Colors.white
                  , fontSize: 25),)),
      ),
    );
  }
}
