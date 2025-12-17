import 'package:css/css.dart';
import 'package:examples/fsm/fsm.dart';
import 'package:examples/fuzzy/fuzzy.dart';
import 'package:examples/goals/goal_example.dart';
import 'package:examples/graph/basic.dart';
import 'package:examples/math/bounding_volumes.dart';
import 'package:examples/math/bvh.dart';
import 'package:examples/math/orientation.dart';
import 'package:examples/memory_system/line_of_sight.dart';
import 'package:examples/memory_system/memory_system.dart';
import 'package:examples/misc/trigger.dart';
import 'package:examples/navigation/firsperson.dart';
import 'package:examples/navigation/nav_advanced.dart';
import 'package:examples/navigation/nav_basic.dart';
import 'package:examples/playground/hideseek/hideseek.dart';
import 'package:examples/playground/shooter/shooter.dart';
import 'package:examples/steering/arriving.dart';
import 'package:examples/steering/flee.dart';
import 'package:examples/steering/flocking.dart';
import 'package:examples/steering/follow.dart';
import 'package:examples/steering/interpose.dart';
import 'package:examples/steering/obsticle.dart';
import 'package:examples/steering/offset_pursuit.dart';
import 'package:examples/steering/pursuit.dart';
import 'package:examples/steering/seek.dart';
import 'package:examples/steering/wander.dart';
import 'src/plugins/plugin.dart';
import 'package:flutter/material.dart';
import 'src/files_json.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  setPathUrlStrategy();
  runApp(const MyApp());
}
class MyApp extends StatefulWidget{
  const MyApp({super.key,}) ;
  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();
  String onPage = '';
  double pageLocation = 0;
  bool useSideNav = false;

  int mainPages = 0;

  @override
  void initState() {
    super.initState();
  }

  void callback(String page, [double? location]){
    onPage = page;
    if(location != null){
      pageLocation = location;
    }

    if(page == 'Examples'){
      onPage = '';
      mainPages = 1;
      setState(() {});
    }
    else{
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) { 
        _navKey.currentState!.popAndPushNamed('/$page');
        setState(() {});
      });
    }
  }

  List<Widget> navNames(){
    return [
      SizedBox(width: 20),
      InkWell(
        onTap: (){
          setState(() {
            mainPages = 0;
          });
        },
        child: Text(
          'Yuka',
          style: TextStyle(
            fontSize: 26,
            color: Colors.red
          ),
        ),
      ),
      SizedBox(width: 20),
      InkWell(
        onTap: (){
          setState(() {
            mainPages = 1;
          });
        },
        child: Text('Examples',),
      ),
      SizedBox(width: 20),
      InkWell(
        onTap: (){
          launchUrl(Uri.parse('https://pub.dev/documentation/three_js/latest/three_js/'));
        },
        child: Text('Documentation'),
      ),
      SizedBox(width: 20),
      InkWell(
        onTap: (){
          launchUrl(Uri.parse('https://github.com/Knightro63/three_js'));
        },
        child: Text('GitHub'),
      )
    ];
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    Size mediaSize = MediaQuery.of(context).size;
    double safePadding = MediaQuery.of(context).padding.top;
    double deviceHeight = mediaSize.height-safePadding-(useSideNav?0:50);
    if(mediaSize.aspectRatio > 1 && mediaSize.width > 500){
      useSideNav = true;
    }
    else{
      useSideNav = false;
    }

    widthInifity = MediaQuery.of(context).size.width;

    return SafeArea(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Three_JS',
        theme: CSS.darkTheme,
        home: Scaffold(
          //key: _scaffoldKey,
          drawer: (!useSideNav)?Drawer(
            child: SizedBox(
              width: 249,
              child: Container(
                width: 249,
                height: deviceHeight,
                color: Theme.of(context).canvasColor,
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                  child:ListView(
                    padding: const EdgeInsets.all(0),
                    children: navNames()
                  ),
                )
              )
            )
          ):null,
          appBar: PreferredSize(
            preferredSize: Size(widthInifity,65),
            child:onPage != ''?AppBar(callback: callback,page: onPage,):Row( children: navNames(),)
          ),
          body: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Three_JS',
            theme: CSS.darkTheme,
            navigatorKey: _navKey,
            routes: {
              '/':(BuildContext context) {
                return mainPages == 0?HomePage(
                  callback: callback,
                  prevLocation: pageLocation
                  ):Examples(
                  callback: callback,
                  prevLocation: pageLocation,
                );
              },
              '/fsm':(BuildContext context) {
                return const FSM();
              },
              '/fuzzy':(BuildContext context) {
                return const Fuzzy();
              },
              '/goal':(BuildContext context) {
                return const Goals();
              },
              '/bounding_volumes':(BuildContext context) {
                return const BoundingVolumes();
              },
              '/bvh':(BuildContext context) {
                return const BVHExample();
              },
              '/orientation':(BuildContext context) {
                return const OrientationExample();
              },
              '/graph_basic':(BuildContext context) {
                return const GraphBasic();
              },
              '/nav_basic':(BuildContext context) {
                return const NavBaisc();
              },
              '/nav_advanced':(BuildContext context) {
                return const NavAdvanced();
              },
              '/first_person':(BuildContext context) {
                return const FirstPersonNav();
              },
              '/trigger':(BuildContext context) {
                return const Trigger();
              },
              '/line_of_sight':(BuildContext context) {
                return const LineOfSight();
              },
              '/memory_system':(BuildContext context) {
                return const MemorySystem();
              },
              '/steering_arrive':(BuildContext context) {
                return const SteeringArrive();
              },
              '/steering_flee':(BuildContext context) {
                return const SteeringFlee();
              },
              '/steering_flocking':(BuildContext context) {
                return const SteeringFlocking();
              },
              '/steering_follow':(BuildContext context) {
                return const SteeringFollow();
              },
              '/steering_interpose':(BuildContext context) {
                return const SteeringInterpose();
              },
              '/steering_pursuit':(BuildContext context) {
                return const SteeringPursuit();
              },
              '/steering_obsticle':(BuildContext context) {
                return const SteeringObsticle();
              },
              '/steering_offset_pursuit':(BuildContext context) {
                return const SteeringOffsetPursuit();
              },
              '/steering_seek':(BuildContext context) {
                return const SteeringSeek();
              },
              '/steering_wander':(BuildContext context) {
                return const SteeringWander();
              },
              '/shooter':(BuildContext context) {
                return const Shooter();
              },
              '/hideseek':(BuildContext context) {
                return const HideSeek();
              },
            }
          ),
        )
      )
    );
  }
}

@immutable
class AppBar extends StatelessWidget{
  const AppBar({
    super.key,
    required this.page,
    required this.callback
  });
  final String page;
  final void Function(String page,[double? loc]) callback;
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 45,
      padding: const EdgeInsets.only(left: 10),
      color: Theme.of(context).cardColor,
      child: Row(
        children: [
          InkWell(
            onTap: (){
              callback('');
            },
            child: const Icon(
              Icons.arrow_back_ios_new_rounded
            ),
          ),
          const SizedBox(width: 20,),
          Text(
            (page[0]+page.substring(1)).replaceAll('_', ' ').toUpperCase(),
            style: Theme.of(context).primaryTextTheme.bodyMedium,
          )
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget{
  const HomePage({
    super.key,
    required this.callback,
    required this.prevLocation
  });

  final void Function(String page,[double? location]) callback;
  final double prevLocation;

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  double deviceHeight = double.infinity;
  double deviceWidth = double.infinity;
  
  @override
  void initState(){
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsetsGeometry.fromLTRB(50, 20, 50, 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.only(bottom: 50),
              padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
              width: deviceWidth,
              height: 300,
              color: Colors.black,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('YUKA', style: Theme.of(context).primaryTextTheme.bodyLarge?.copyWith(fontSize: 48),),
                  Text(
                    'A JavaScript library made by mugen87 for developing Game AI.\nThis is a conversion to dart.\nFor the origional go here.',
                    textAlign: TextAlign.center, 
                    style: Theme.of(context).primaryTextTheme.bodyMedium
                  ),
                  InkWell(
                    onTap: (){
                      widget.callback('Examples',0);
                    },
                    child: Container(
                      width: 200,
                      height: 45,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(5)
                      ),
                      child: Text('View Examples', style: Theme.of(context).primaryTextTheme.bodyMedium),
                    ),
                  )
                ],
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: (deviceWidth-100)/3,
                  child: Column(
                    children: [
                      Text(
                        'Autonomous Agent Design',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).primaryTextTheme.bodyLarge
                      ),
                      Text(
                        'Yuka provides a basic game entity concept and classes for state-driven and goal-driven agent design.', 
                        textAlign: TextAlign.center,
                        style: Theme.of(context).primaryTextTheme.bodyMedium
                      )
                    ],
                  )
                ),
                SizedBox(
                  width: (deviceWidth-100)/3,
                  child: Column(
                    children: [
                      Text(
                        'Steering and Navigation',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).primaryTextTheme.bodyLarge
                      ),
                      Text(
                        'Use the build-in vehicle model and steering behaviors in order to develop moving game entities. Graph classes, search algorithms and a navigation mesh implementation enables advanced path finding.', 
                        textAlign: TextAlign.center,
                        style: Theme.of(context).primaryTextTheme.bodyMedium
                      )
                    ],
                  )
                ),
                SizedBox(
                  width: (deviceWidth-100)/3,
                  child: Column(
                    children: [
                      Text(
                        'Perception and Triggers',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).primaryTextTheme.bodyLarge
                      ),
                      Text(
                        'Create game entities with a short-term memory and a vision component. Use triggers to generate dynamic actions in your game.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).primaryTextTheme.bodyMedium
                      )
                    ],
                  )
                )
              ],
            ),
            Container(
              margin: EdgeInsets.only(top: 50),
              color: Colors.white,
              height: 0.5,
            ),
            Container(
              margin: EdgeInsets.only(top: 50),
              width: (deviceWidth-100),
              child: Column(
                children: [
                  Text(
                    'Video Game Industry Best Practices',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).primaryTextTheme.bodyLarge
                  ),
                  Text(
                    'One of Yuka\'s goals is to implement concepts that have been successfully used by the video game industry over a long period of time. With this approach, we hope to create a robust and performant foundation for web-based video games.', 
                    textAlign: TextAlign.center,
                    style: Theme.of(context).primaryTextTheme.bodyMedium
                  )
                ],
              )
            ),
            Container(
              margin: EdgeInsets.only(top: 50),
              color: Colors.white,
              height: 0.5,
            ),
            Container(
              margin: EdgeInsets.only(top: 50),
              width: (deviceWidth-100),
              child: Column(
                children: [
                  Text(
                    'Standalone AI Engine',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).primaryTextTheme.bodyLarge
                  ),
                  Text(
                    'Yuka is a standalone library and independent of a particular 3D engine. The idea is to implement the actual game logic with Yuka and the visual representation with your preferred JavaScript 3D library. Yuka uses three_js for its examples and showcases but it is also possible to use it with other projects like BabylonJS.', 
                    textAlign: TextAlign.center,
                    style: Theme.of(context).primaryTextTheme.bodyMedium
                  )
                ],
              )
            ),
            Container(
              margin: EdgeInsets.only(top: 50,bottom: 50),
              color: Colors.white,
              height: 0.5,
            ),
          ]
        )
      )
    );
  }
}

class Examples extends StatefulWidget{
  const Examples({
    super.key,
    required this.callback,
    required this.prevLocation
  });

  final void Function(String page,[double? location]) callback;
  final double prevLocation;

  @override
  ExamplesPageState createState() => ExamplesPageState();
}

class ExamplesPageState extends State<Examples> {
  double deviceHeight = double.infinity;
  double deviceWidth = double.infinity;
  ScrollController controller = ScrollController();

  List<Widget> displayExamples(){

    List<Widget> widgets = [
      SizedBox(
        height: 65,
        child: Text(
          'Examples',
          style: Theme.of(context).primaryTextTheme.bodyLarge?.copyWith(fontSize: 36),
        ),
      ),
    ];

    for(String key in filesJson.keys){
      final section = filesJson[key]!;
      widgets.add(
        Container(
          padding: EdgeInsets.only(bottom: 25,top: 25),
          child: Text(
            key,
            style: Theme.of(context).primaryTextTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic),
          ),
        ),
      );

      for(String key in section.keys){
        final name = section[key]!['name']!;
        final description = section[key]!['description']!;

        widgets.add(
          InkWell(
            onTap: (){
              widget.callback(key,controller.offset);
            },
            child: Text(
              name,
              style: Theme.of(context).primaryTextTheme.bodyMedium?.copyWith(color: Colors.red),
            )
          ),
        );
        widgets.add(
          Container(
            margin: EdgeInsets.fromLTRB(0, 5, 0, 5),
            child: Text(
              description,
              style: Theme.of(context).primaryTextTheme.bodySmall,
            )
          )
        );

        widgets.add(
          Container(
            margin: EdgeInsets.fromLTRB(0, 10, 0, 10),
            height: 0.5,
            color: Colors.white,
          )
        );
      }
    }

    return widgets;
  }

  @override
  void initState(){
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) { 
      controller.jumpTo(widget.prevLocation);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width;
    
    return SingleChildScrollView(
      controller: controller,
      child: Padding(
        padding: EdgeInsetsGeometry.fromLTRB(50, 20, 50, 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: displayExamples(),
        )
      )
    );
  }
}