import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// Web handoff preview: fixed 390x844 H5 viewport, aspect-fitted without layout
/// compression. On a narrow device the native body fills available bounds.
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({super.key,required this.child,this.backgroundImage,this.background,this.backgroundLayer,this.fitToScreen=false});
  final Widget child;
  final String? backgroundImage;
  final Color? background;
  final Widget? backgroundLayer;
  final bool fitToScreen;
  @override
  Widget build(BuildContext context) {
    Widget content()=>Stack(children:[Positioned.fill(child:backgroundLayer ?? (background!=null?ColoredBox(color:background!):
      backgroundImage!=null?Image.asset(backgroundImage!,fit:BoxFit.cover,alignment:Alignment.topCenter):const ColoredBox(color:Colors.white))),child]);
    if(fitToScreen)return SizedBox.expand(child:content());
    return ColoredBox(color:SurgoColors.canvas,child:Padding(padding:const EdgeInsets.all(30),child:Center(
      child:FittedBox(fit:BoxFit.contain,child:Transform.scale(scale:.9,child:Container(width:414,height:868,
        decoration:BoxDecoration(color:SurgoColors.deviceBlack,borderRadius:BorderRadius.circular(44),boxShadow:SurgoShadow.device),
        padding:const EdgeInsets.all(12),child:ClipRRect(borderRadius:BorderRadius.circular(32),child:content())))))));
  }
}
class PhoneNotch extends StatelessWidget {
  const PhoneNotch({super.key});
  @override
  Widget build(BuildContext context)=>Align(alignment:Alignment.topCenter,child:Container(width:150,height:30,
    decoration:const BoxDecoration(color:SurgoColors.deviceBlack,borderRadius:BorderRadius.vertical(bottom:Radius.circular(20)))));
}
class PhoneStatusBar extends StatelessWidget {
  const PhoneStatusBar({super.key,this.image='assets/images/status_bar.png'});
  final String image;
  @override
  Widget build(BuildContext context)=>SizedBox(height:52,width:double.infinity,child:Center(child:Image.asset(image,width:double.infinity,fit:BoxFit.fitWidth)));
}
