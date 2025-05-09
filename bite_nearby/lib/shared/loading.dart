import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:bite_nearby/Coolors.dart';

class Loading extends StatelessWidget {
  const Loading({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Coolors.ivoryCream,
      child: Center(
        child: SpinKitThreeBounce(
          color: Coolors.wineRed,
          size: 50.0,
        ),
      ),
    );
  }
}
