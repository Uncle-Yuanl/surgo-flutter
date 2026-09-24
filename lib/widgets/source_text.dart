import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../app/app_state.dart';

/// Only changes exact text nodes observed changing in the original route DOM.
/// All unmatched questions, answer values and user drafts remain verbatim.
class SourceNodeTranslations {
 static Map<String,dynamic> routes={};
 static bool loaded=false;
 static Future<void> load()async{if(loaded)return;final data=jsonDecode(await rootBundle.loadString('assets/data/source_dom_translations.json'));routes=Map<String,dynamic>.from(data['routes']);loaded=true;}
 static String lookup(String text,String page,String lang){final map=routes[page]?[lang] as Map?;return map?[text.trim()] as String? ?? text;}
}
class SourceText extends StatelessWidget {
 const SourceText(this.data,{super.key,this.style,this.textAlign,this.maxLines,this.overflow,this.softWrap,this.textDirection,this.textWidthBasis,this.textHeightBehavior,this.semanticsLabel,this.strutStyle}):span=null;
 const SourceText.rich(InlineSpan textSpan,{super.key,this.style,this.textAlign,this.maxLines,this.overflow,this.softWrap,this.textDirection,this.textWidthBasis,this.textHeightBehavior,this.semanticsLabel,this.strutStyle}):span=textSpan,data=null;
 final String? data;
 final InlineSpan? span;
 final TextStyle? style;
 final TextAlign? textAlign;
 final int? maxLines;
 final TextOverflow? overflow;
 final bool? softWrap;
 final TextDirection? textDirection;
 final TextWidthBasis? textWidthBasis;
 final TextHeightBehavior? textHeightBehavior;
 final String? semanticsLabel;
 final StrutStyle? strutStyle;
 @override
 Widget build(BuildContext context){final app=context.watch<AppState>();String tr(String s)=>SourceNodeTranslations.lookup(s,app.current.name,app.lang.name);
  InlineSpan translateSpan(InlineSpan node){if(node is! TextSpan)return node;return TextSpan(text:node.text==null?null:tr(node.text!),style:node.style,children:node.children?.map(translateSpan).toList(),recognizer:node.recognizer,mouseCursor:node.mouseCursor,onEnter:node.onEnter,onExit:node.onExit,semanticsLabel:node.semanticsLabel,locale:node.locale,spellOut:node.spellOut);}
  return span==null?Text(tr(data!),style:style,textAlign:textAlign,maxLines:maxLines,overflow:overflow,softWrap:softWrap,textDirection:textDirection,textWidthBasis:textWidthBasis,textHeightBehavior:textHeightBehavior,semanticsLabel:semanticsLabel,strutStyle:strutStyle):Text.rich(translateSpan(span!),style:style,textAlign:textAlign,maxLines:maxLines,overflow:overflow,softWrap:softWrap,textDirection:textDirection,textWidthBasis:textWidthBasis,textHeightBehavior:textHeightBehavior,semanticsLabel:semanticsLabel,strutStyle:strutStyle);
 }
}
