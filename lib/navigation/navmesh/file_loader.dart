import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

import 'package:yuka/core/console_logger/console_platform.dart';

class YukaFile{
  YukaFile(this.type,this.data,[this.location]);

  Uint8List data;
  String type;
  String? location;
}

/// A low level class for loading resources with Fetch, used internally by
/// most loaders. It can also be used directly to load any file type that does
/// not have a loader.
///
/// *Note:* The cache must be enabled using
/// `Cache.enabled = true;`
/// This is a global property and only needs to be set once to be used by all
/// loaders that use FileLoader internally. [Cache] is a cache
/// module that holds the response from each request made through this loader,
/// so each file is requested once.
class YukaFileLoader{
  Future<YukaFile?> fromNetwork(Uri uri) async{
    final url = uri.path;
    
    try{
      final http.Response response = await http.get(uri);
      final bytes = response.bodyBytes;

      return YukaFile('network',bytes,url);
    }
    catch(e){
      yukaConsole.error('Yuka error: $e');
      return null;
    }
  }
  Future<YukaFile> fromFile(File file) async{
    final Uint8List data = await file.readAsBytes();
    return await fromBytes(data,'file',file.path);
  }
  Future<YukaFile?> fromPath(String filePath) async{
    try{
      final File file = File(filePath);
      final Uint8List data = await file.readAsBytes();
      return await fromBytes(data,'path',filePath);
    }catch(e){
      yukaConsole.error('FileLoader error from path: $filePath');
      return null;
    }
  }
  Future<YukaFile?> fromAsset(String asset, {String? package}) async{
    asset = package != null?'packages/$package/$asset':asset;

    try{
      ByteData fileData = await rootBundle.load(asset);
      final bytes = fileData.buffer.asUint8List();
      return YukaFile('asset',bytes,asset);
    }
    catch(e){
      yukaConsole.error('Yuka error: $e');
      return null;
    }
  }
  Future<YukaFile> fromBytes(Uint8List bytes, [String? type, String? location]) async{
    return YukaFile(type??'bytes',bytes,location);
  }

  Future<YukaFile?> unknown(dynamic url) async{
    if(url is File){
      return fromFile(url);
    }
    else if(url is Uri){
      return fromNetwork(url);
    }
    else if(url is Uint8List){
      return fromBytes(url);
    }
    else if(url is String){
      RegExp dataUriRegex = RegExp(r"^data:(.*?)(;base64)?,(.*)$");
      if(url.contains('http://') || url.contains('https://')){  
        return fromNetwork(Uri.parse(url));
      }
      else if(url.contains('assets')){
        return fromAsset(url);
      }
      else if(dataUriRegex.hasMatch(url)){
        RegExpMatch? dataUriRegexResult = dataUriRegex.firstMatch(url);
        String? data = dataUriRegexResult!.group(3)!;

        return YukaFile('text', convert.base64.decode(data));
      }
      else{
        return fromPath(url);
      }
    }

    return null;
  }
}
