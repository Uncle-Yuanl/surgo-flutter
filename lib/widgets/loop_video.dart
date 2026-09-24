import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Muted looping local video, matching the source's autoplay/loop/muted assets.
class LoopVideo extends StatefulWidget {
  const LoopVideo({super.key,required this.asset,this.width=120,this.height=120,this.fit=BoxFit.cover});
  final String asset;
  final double width,height;
  /// Source clips fill their box; pass [BoxFit.contain] where the whole
  /// illustration must stay visible.
  final BoxFit fit;
  @override
  State<LoopVideo> createState()=>_LoopVideoState();
}
class _LoopVideoState extends State<LoopVideo> {
  late final VideoPlayerController player;
  Object? failure;
  @override
  void initState(){super.initState();player=VideoPlayerController.asset(widget.asset);_start();}
  Future<void> _start() async {
    try {await player.initialize();if(!mounted)return;await player.setVolume(0);await player.setLooping(true);await player.play();if(mounted)setState((){});}
    catch(e){if(mounted)setState(()=>failure=e);}
  }
  @override
  void dispose(){player.dispose();super.dispose();}
  @override
  Widget build(BuildContext context)=>SizedBox(width:widget.width,height:widget.height,
    child: failure!=null ? const Center(child:Text('视频暂不可用',style:TextStyle(fontSize:10))) : player.value.isInitialized ? ClipRect(child:FittedBox(fit:widget.fit,
      child:SizedBox(width:player.value.size.width,height:player.value.size.height,child:VideoPlayer(player)))) : const SizedBox.shrink());
}
