import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'dart:convert' as convert;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:yuka/navigation/navmesh/file_loader.dart';
import 'package:yuka/yuka.dart';
import 'package:http/http.dart' as http;

/// Class for loading navigation meshes as glTF assets. The loader supports
/// *glTF* and *glb* files, embedded buffers, index and non-indexed geometries.
/// Interleaved geometry data are not yet supported.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class NavMeshLoader {

  Future<NavMesh?> fromNetwork(Uri uri, [Map<String,dynamic>? options]) async{
    try{
      final http.Response response = await http.get(uri);
      final bytes = response.bodyBytes;
      return _parse(bytes,options);
    }catch(e){
      yukaConsole.error('Yuka error: $e');
      return null;
    }
  }
  Future<NavMesh?> fromFile(File file, [Map<String,dynamic>? options]) async{
    final Uint8List data = await file.readAsBytes();
    return _parse(data,options);
  }
  Future<NavMesh?> fromPath(String filePath, [Map<String,dynamic>? options]) async{
    try{
      final File file = File(filePath);
      final Uint8List data = await file.readAsBytes();
      return _parse(data,options);
    }catch(e){
      yukaConsole.error('FileLoader error from path: $filePath');
      return null;
    }
  }
  Future<NavMesh?> fromAsset(String asset, {String? package, Map<String,dynamic>? options}) async{
    asset = package != null?'packages/$package/$asset':asset;
    try{
      ByteData fileData = await rootBundle.load(asset);
      final bytes = fileData.buffer.asUint8List();
      return _parse(bytes,options);
    }
    catch(e){
      yukaConsole.error('Yuka error: $e');
      return null;
    }
  }
  Future<NavMesh?> fromBytes(Uint8List bytes, [Map<String,dynamic>? options]) async{
    return _parse(bytes,options);
  }
  Future<NavMesh?> unknown(dynamic url, [Map<String,dynamic>? options]) async{
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

        return fromBytes(convert.base64.decode(data));
      }
      else{
        return fromPath(url);
      }
    }

    return null;
  }

  String decodeText(List<int> array) {
    final s = const convert.Utf8Decoder().convert(array);
    return s;
  }

	Future<NavMesh?> _parse( Uint8List array, [Map<String,dynamic>? options] ) async{
		final parser = Parser();
		//String data = String.fromCharCodes(arrayBuffer).toString();

    late final String content;
    late final String magic;
    if(kIsWasm){
      final list = array.buffer.asUint8List().sublist(0, 4);
      magic = decodeText(list);
    }
    else{
      magic = decodeText(Uint8List.view(array.buffer, 0, 4));
    }
    
    if (magic == 'glTF') {
			parser.parseBinary( array.buffer );
			content = parser.extensions['BINARY']['content'];
    } 
    else {
      content = decodeText(array);
    }

		final Map<String, dynamic> json = convert.jsonDecode(content);
		if ( json['asset'] == null || num.parse(json["asset"]["version"]) < 2.0 ) {
			throw( 'YUKA.NavMeshLoader: Unsupported asset version.' );
		} 
    else {
			return await parser.parse( json, options );
		}
	}
}

class Parser {
  final behl = 12;
  final bect = { 'JSON': 0x4E4F534A, 'BIN': 0x004E4942 };
  final webglTypeSize = {
    'SCALAR': 1,
    'VEC2': 2,
    'VEC3': 3,
    'VEC4': 4,
    'MAT2': 4,
    'MAT3': 9,
    'MAT4': 16
  };

  dynamic view(int type, ByteBuffer buffer, int offset, int length) {
    if (type == 5120) {
      return Int8List.view(buffer, offset, length);
    } else if (type == 5121) {
      return Uint8List.view(buffer, offset, length);
    } else if (type == 5122) {
      return Int16List.view(buffer, offset, length);
    } else if (type == 5123) {
      return Uint16List.view(buffer, offset, length);
    } else if (type == 5125) {
      return Uint32List.view(buffer, offset, length);
    } else if (type == 5126) {
      return Float32List.view(buffer, offset, length);
    } else {
      throw (" GLTFHelper GLTypeData view type: $type is not support ...");
    }
  }

  final fileLoader = YukaFileLoader();
  late Map<String,dynamic> json;
  Map<String, dynamic>? options;
  Map<String,dynamic> cache = {};
  Map<String,dynamic> extensions = {};

	Future<NavMesh?> parse(Map<String,dynamic> json, [Map<String,dynamic>? options] ) async{
		this.json = json;
    this.options = options;

		// read the first mesh in the glTF file
		final data = await getDependency( 'mesh', 0 );

    // parse the raw geometry data into a bunch of polygons
    final polygons = parseGeometry( data );

    // create and config navMesh
    final navMesh = NavMesh();

    if ( options != null) {
      if ( options['epsilonCoplanarTest'] != null ) navMesh.epsilonCoplanarTest = options['epsilonCoplanarTest'];
      if ( options['mergeConvexRegions'] != null ) navMesh.mergeConvexRegions = options['mergeConvexRegions'];
    }

    // use polygons to setup the nav mesh
    return navMesh.fromPolygons( polygons );
  }

	List<Polygon> parseGeometry(Map<String,dynamic> data ) {
		final index = data['index'];
		final position = data['position'];

		final vertices = <Vector3>[];
		final polygons = <Polygon>[];

		// vertices
		for ( int i = 0, l = position.length; i < l; i += 3 ) {
			final v = Vector3();

			v.x = position[ i + 0 ];
			v.y = position[ i + 1 ];
			v.z = position[ i + 2 ];

			vertices.add( v );
		}

		// polygons
		if ( index != null) {
			// indexed geometry
			for ( int i = 0, l = index.length; i < l; i += 3 ) {
				final a = index[ i + 0 ];
				final b = index[ i + 1 ];
				final c = index[ i + 2 ];

				final contour = [ vertices[ a ], vertices[ b ], vertices[ c ] ];
				final polygon = Polygon().fromContour( contour );

				polygons.add( polygon );
			}
		} 
    else {
			// non-indexed geometry //todo test
			for ( int i = 0, l = vertices.length; i < l; i += 3 ) {
				final contour = [ vertices[ i + 0 ], vertices[ i + 1 ], vertices[ i + 2 ] ];
				final polygon = Polygon().fromContour( contour );
				polygons.add( polygon );
			}
		}

		return polygons;
	}

	Future getDependencies(String type ) async {
    final dependencies = cache[type];

    if (dependencies != null) {
      return dependencies;
    }
    
    final defs = json[type + (type == 'mesh' ? 'es' : 's')] ?? [];
    List otherDependencies = [];

    for (int i = 0; i < defs.length; i++) {
      final dep1 = await getDependency(type, i);
      otherDependencies.add(dep1);
    }

    cache[type] = otherDependencies;

    return otherDependencies;
	}

	Future getDependency(String type, int index ) async{
		final cache = this.cache;
		final key = '$type:$index';

		dynamic dependency = cache[key];

		if ( dependency == null ) {
			switch ( type ) {
				case 'accessor':
					dependency = loadAccessor( index );
					break;
				case 'buffer':
					dependency = loadBuffer( index );
					break;
				case 'bufferView':
					dependency = loadBufferView( index );
					break;
				case 'mesh':
					dependency = loadMesh( index );
					break;
				default:
					throw( 'Unknown type: $type');
			}

			cache[key] =  dependency;
		}

		return dependency;
	}

  Future loadBuffer(int bufferIndex) async {
    Map<String, dynamic> bufferDef = json["buffers"][bufferIndex];
    final loader = fileLoader;

    if (bufferDef["type"] != null && bufferDef["type"] != 'arraybuffer') {
      throw ('GLTFLoader: ${bufferDef["type"]} buffer type is not supported.');
    }

    // If present, GLB container is required to be the first buffer.
    if (bufferDef["uri"] == null && bufferIndex == 0) {
      return extensions['BINARY']['body'];
    }

    final options = this.options;
    if(bufferDef["uri"] != null && options?["path"] != null){
      final url = resolveURL(bufferDef["uri"], options?["path"]);
      final res = await loader.unknown(url);

      return res?.data.buffer;
    }

    return null;
  }

  String resolveURL(String url, String path) {
    // Host Relative URL
    final reg1 = RegExp("^https?://", caseSensitive: false);
    if (reg1.hasMatch(path) &&
        RegExp("^/", caseSensitive: false).hasMatch(url)) {
      final reg2 = RegExp("(^https?://[^/]+).*", caseSensitive: false);

      final matches = reg2.allMatches(path);

      for (RegExpMatch match in matches) {
        path = path.replaceFirst(match.group(0)!, match.group(1)!);
      }

      yukaConsole.info("GLTFHelper.resolveURL todo debug.");
      // path = path.replace( RegExp("(^https?:\/\/[^\/]+).*", caseSensitive: false), '$1' );
    }

    // Absolute URL http://,https://,//
    if (RegExp("^(https?:)?//", caseSensitive: false).hasMatch(url)) {
      return url;
    }

    // Data URI
    if (RegExp(r"^data:.*,.*$", caseSensitive: false).hasMatch(url)) return url;

    // Blob URL
    if (RegExp(r"^blob:.*$", caseSensitive: false).hasMatch(url)) return url;

    // Relative URL
    return path + url;
  }

	Future loadBufferView(int index ) async{
		final json = this.json;
		final definition = json['bufferViews'][ index ];

		final buffer = await getDependency( 'buffer', definition['buffer'] );

    final byteLength = definition['byteLength'] ?? 0;
    final byteOffset = definition['byteOffset'] ?? 0;
    return Uint8List.view(buffer).sublist( byteOffset, byteOffset + byteLength );
	}

	Future loadAccessor(int index ) async {
		final json = this.json;
		final definition = json['accessors'][ index ];

		final bufferView = await getDependency( 'bufferView', definition['bufferView'] );

    final itemSize = webglTypeSize[ definition['type'] ];
    //final typedArray = webglComponentTypes[ definition['componentType'] ] as Float32List;
    final byteOffset = definition['byteOffset'] ?? 0;
    return view(definition['componentType'], bufferView.buffer, byteOffset, byteOffset+(definition['count'] * itemSize) );
	}

	Future<Map<String,dynamic>> loadMesh(int index ) async{
		final json = this.json;
		final definition = json['meshes'][ index ];

		final accessors = await getDependencies( 'accessor' );
    // assuming a single primitive
    final primitive = definition['primitives'][ 0 ];

    if ( primitive['mode'] != null && primitive['mode'] != 4 ) {
      throw( 'YUKA.NavMeshLoader: Invalid geometry format. Please ensure to represent your geometry as triangles.' );
    }

    return {
      'index': accessors[ primitive['indices'] ],
      'position': accessors[ primitive['attributes']['POSITION'] ],
      'normal': accessors[ primitive['attributes']['NORMAL'] ]
    };
	}

	void parseBinary(ByteBuffer data ) {
		final ByteData chunkView = ByteData.view(data, behl);
		int chunkIndex = 0;

		String? content;
		dynamic body;

		while ( chunkIndex < chunkView.lengthInBytes ) {
			final int chunkLength = chunkView.getUint32( chunkIndex, Endian.little );
			chunkIndex += 4;
      
			final int chunkType = chunkView.getUint32( chunkIndex, Endian.little );
			chunkIndex += 4;

			if ( chunkType == bect['JSON'] ) {
				final contentArray = Uint8List.view(data, behl + chunkIndex, chunkLength);
				content = String.fromCharCodes(contentArray).toString();//decoder.decode( contentArray );
			} 
      else if ( chunkType == bect['BIN'] ) {
				final byteOffset = behl + chunkIndex;
				body = Uint8List.view(data).sublist(byteOffset, byteOffset + chunkLength).buffer;
			}

			chunkIndex += chunkLength;
		}

		extensions['BINARY'] = { 'content': content, 'body': body };
	}
}