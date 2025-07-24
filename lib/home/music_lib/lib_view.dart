
import 'package:flutter/material.dart';
import 'package:getsocio/home/music_lib/lib_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class LibView extends StatefulWidget {
  const LibView({super.key});

  @override
  State<LibView> createState() => _LibViewState();
}

class _LibViewState extends State<LibView> {
  List<String> audioFiles=[];

  _handleFilePick(BuildContext context) async {
    final provider = Provider.of<LibProvider>(context, listen: false);
    final result = await provider.pickAudioFiles();

    if (result == 'PermissionDenied') {
      _showPermissionDeniedDialog(context);
    } else if (result != null) {
      _showErrorDialog(context, result);
    }
  }

    void _showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text('Please grant audio storage permission.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(onPressed: openAppSettings, child: const Text('Settings')),
        ],
      ),
    );
  }

 
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK')),
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
     final audioFiles = context.watch<LibProvider>().audioFiles;
    return 
    Column(children: [Center(child: ElevatedButton(onPressed: (){
      _handleFilePick(context);
    }, child: Text("select audio files")),),
      audioFiles.isEmpty?EmptyPlayList():PlayList(audioFiles: audioFiles,)
    ]);
    
  
  }
}


/// Empty Playlist Widget
class EmptyPlayList extends StatelessWidget{
  const EmptyPlayList({super.key});

  @override
  Widget build(BuildContext context){
    return Center(child: Text("Playlist is empty",style: TextStyle(color: Colors.white),),);
  }
}


///Widget for showing complete playlist
class PlayList extends StatelessWidget{
  const PlayList({super.key,required this.audioFiles});
  final List<String> audioFiles;

  @override
  Widget build(BuildContext context){
    return Expanded(
      child: ListView.builder(itemCount: audioFiles.length,itemBuilder: (cont,ind){
        return ListTile(title: Text(audioFiles[ind],style: TextStyle(color: Colors.white),),);
      }),
    );
  }
}