import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
/// Native equivalent of HTML onchange (committed edit) vs oninput (each edit).
class ListeningSourceGap extends StatefulWidget {
 const ListeningSourceGap({super.key,required this.onValue,this.inputEvent=false,this.maxLength});
 final ValueChanged<String> onValue;
 final bool inputEvent;
 final int? maxLength;
 @override State<ListeningSourceGap> createState()=>_ListeningSourceGapState();
}
class _ListeningSourceGapState extends State<ListeningSourceGap>{
 final text=TextEditingController(),focus=FocusNode();String committed='';
 @override void initState(){super.initState();focus.addListener(_focus);}
 void _focus(){if(!focus.hasFocus)commit();}
 void commit(){if(widget.inputEvent||text.text==committed)return;committed=text.text;widget.onValue(committed);}
 @override void dispose(){focus.removeListener(_focus);focus.dispose();text.dispose();super.dispose();}
 @override Widget build(BuildContext context)=>TextField(controller:text,focusNode:focus,inputFormatters:widget.maxLength==null?null:[LengthLimitingTextInputFormatter(widget.maxLength)],onChanged:widget.inputEvent?widget.onValue:null,onSubmitted:(_)=>commit(),onTapOutside:(_)=>focus.unfocus(),decoration:const InputDecoration(border:UnderlineInputBorder()));
}
