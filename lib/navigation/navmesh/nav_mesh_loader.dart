import 'package:yuka/yuka.dart';

import '../../math/polygon.dart';
import '../../math/vector3.dart';

/// Class for loading navigation meshes as glTF assets. The loader supports
/// *glTF* and *glb* files, embedded buffers, index and non-indexed geometries.
/// Interleaved geometry data are not yet supported.
///
/// @author {@link https://github.com/Mugen87|Mugen87}
class NavMeshLoader {

	/**
	* Loads a {@link NavMesh navigation mesh} from the given URL. The second parameter can be used
	* to influence the parsing of the navigation mesh.
	*
	* @param {String} url - The URL of the glTF asset.
	* @param {Object} options - The (optional) configuration object.
	* @return {Promise} A promise representing the loading and parsing process.
	*/
	load( url, options ) {

		return Promise( ( resolve, reject ) => {

			fetch( url )

				.then( response => {

					if ( response.status >= 200 && response.status < 300 ) {

						return response.arrayBuffer();

					} else {

						final error = Error( response.statusText || response.status );
						error.response = response;
						return Promise.reject( error );

					}

				} )

				.then( ( arrayBuffer ) => {

					return this.parse( arrayBuffer, url, options );

				} )

				.then( ( data ) => {

					resolve( data );

				} )

				.catch( ( error ) => {

					Logger.error( 'YUKA.NavMeshLoader: Unable to load navigation mesh.', error );

					reject( error );

				} );

		} );

	}

	/**
	* Use this method if you are loading the contents of a navmesh not via {@link NavMeshLoader#load}.
	* This is for example useful in a node environment.
	*
	* It's mandatory to use glb files with embedded buffer data if you are going to load nav meshes
	* in node.js.
	*
	* @param {ArrayBuffer} arrayBuffer - The array buffer.
	* @param {String} url - The (optional) URL.
	* @param {Object} options - The (optional) configuration object.
	* @return {Promise} A promise representing the parsing process.
	*/
	parse( arrayBuffer, url, options ) {
		final parser = Parser();
		final decoder = TextDecoder();
		let data;

		final magic = decoder.decode( Uint8Array( arrayBuffer, 0, 4 ) );

		if ( magic == BINARY_EXTENSION_HEADER_MAGIC ) {
			parser.parseBinary( arrayBuffer );
			data = parser.extensions.get( 'BINARY' ).content;
		} 
    else {
			data = decoder.decode( Uint8Array( arrayBuffer ) );
		}

		final json = JSON.parse( data );
		if ( json.asset == null || json.asset.version[ 0 ] < 2 ) {
			throw( 'YUKA.NavMeshLoader: Unsupported asset version.' );
		} 
    else {
			final path = extractUrlBase( url );
			return parser.parse( json, path, options );
		}
	}
}

class Parser {
  late Map<String,dynamic> json;
  Map<String, dynamic>? options;
  Map<String,dynamic> cache = {};
  Map<String,dynamic> extensions = {};

	parse(Map<String,dynamic> json, path, Map<String,dynamic>? options ) {
		this.json = json;
    this.options = options;

		// read the first mesh in the glTF file
		return getDependency( 'mesh', 0 ).then( ( data ){
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

		} );
	}

	parseGeometry( data ) {
		final index = data.index;
		final position = data.position;

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
		if ( index ) {

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

	getDependencies(String type ) async {
    final dependencies = cache[type];

    if (dependencies != null) {
      return dependencies;
    }
    
    final defs = json[type + (type == 'mesh' ? 'es' : 's')] ?? [];
    List otherDependencies = [];

    int l = defs.length;

    for (int i = 0; i < l; i++) {
      final dep1 = await getDependency(type, i);
      otherDependencies.add(dep1);
    }

    cache[type] = otherDependencies;

    return otherDependencies;
	}

	getDependency(String type, int index ) {
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

  loadBuffer(int bufferIndex) async {
    Map<String, dynamic> bufferDef = json["buffers"][bufferIndex];
    final loader = fileLoader;

    if (bufferDef["type"] != null && bufferDef["type"] != 'arraybuffer') {
      throw ('GLTFLoader: ${bufferDef["type"]} buffer type is not supported.');
    }

    // If present, GLB container is required to be the first buffer.
    if (bufferDef["uri"] == null && bufferIndex == 0) {
      return extensions[gltfExtensions["KHR_BINARY_GLTF"]].body;
    }

    final options = this.options;
    if(bufferDef["uri"] != null && options["path"] != null){
      final url = LoaderUtils.resolveURL(bufferDef["uri"], options["path"]);
      final res = await loader.unknown(url);

      return res?.data;
    }

    return null;
  }

	loadBufferView(int index ) {
		final json = this.json;
		final definition = json['bufferViews'][ index ];

		return getDependency( 'buffer', definition['buffer'] ).then( ( buffer ){
			final byteLength = definition['byteLength'] ?? 0;
			final byteOffset = definition['byteOffset'] ?? 0;
			return buffer.subList( byteOffset, byteOffset + byteLength );
		} );
	}

	loadAccessor(int index ) {
		final json = this.json;
		final definition = json['accessors'][ index ];

		return getDependency( 'bufferView', definition['bufferView'] ).then( ( bufferView ){
			final itemSize = WEBGL_TYPE_SIZES[ definition['type'] ];
			final TypedArray = WEBGL_COMPONENT_TYPES[ definition['componentType'] ];
			final byteOffset = definition['byteOffset'] ?? 0;
			return TypedArray( bufferView, byteOffset, definition['count'] * itemSize );
		} );
	}

	loadMesh(int index ) {
		final json = this.json;
		final definition = json['meshes'][ index ];

		return getDependencies( 'accessor' ).then( ( accessors ){
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
		} );
	}

	parseBinary( data ) {
		final chunkView = DataView( data, BINARY_EXTENSION_HEADER_LENGTH );
		let chunkIndex = 0;

		final decoder = TextDecoder();
		let content = null;
		let body = null;

		while ( chunkIndex < chunkView.byteLength ) {
			final chunkLength = chunkView.getUint32( chunkIndex, true );
			chunkIndex += 4;

			final chunkType = chunkView.getUint32( chunkIndex, true );
			chunkIndex += 4;

			if ( chunkType == BINARY_EXTENSION_CHUNK_TYPES['JSON'] ) {
				final contentArray = Uint8Array( data, BINARY_EXTENSION_HEADER_LENGTH + chunkIndex, chunkLength );
				content = decoder.decode( contentArray );
			} 
      else if ( chunkType == BINARY_EXTENSION_CHUNK_TYPES['BIN'] ) {
				final byteOffset = BINARY_EXTENSION_HEADER_LENGTH + chunkIndex;
				body = data.slice( byteOffset, byteOffset + chunkLength );
			}

			chunkIndex += chunkLength;
		}

		extensions['BINARY'] = { 'content': content, 'body': body };
	}

  // helper functions
  extractUrlBase( [String url = '' ]) {
    final index = url.lastIndexOf( '/' );
    if ( index == - 1 ) return './';
    return url.substr( 0, index + 1 );
  }

  resolveURI( uri, path ) {
    if ( typeof uri != 'string' || uri == '' ) return '';
    if ( /^(https?:)?\/\//i.test( uri ) ) return uri;
    if ( /^data:.*,.*$/i.test( uri ) ) return uri;
    if ( /^blob:.*$/i.test( uri ) ) return uri;
    return path + uri;
  }
}

//

final WEBGL_TYPE_SIZES = {
	'SCALAR': 1,
	'VEC2': 2,
	'VEC3': 3,
	'VEC4': 4,
	'MAT2': 4,
	'MAT3': 9,
	'MAT4': 16
};

final WEBGL_COMPONENT_TYPES = {
	5120: Int8Array,
	5121: Uint8Array,
	5122: Int16Array,
	5123: Uint16Array,
	5125: Uint32Array,
	5126: Float32Array
};

final BINARY_EXTENSION_HEADER_MAGIC = 'glTF';
final BINARY_EXTENSION_HEADER_LENGTH = 12;
final BINARY_EXTENSION_CHUNK_TYPES = { JSON: 0x4E4F534A, BIN: 0x004E4942 };
