import 'package:flutter/material.dart';
import 'package:nested_routers/pages/movie.dart' show moviePatterns, movieBuilders;
import 'package:nested_routers/pages/home.dart' show homePattens, homeBuilders;

import 'router_delegate.dart';
import 'routing_util.dart';
import 'route_package_parser.dart';

void main() {
  runApp(SearchApp());
}

class SearchApp extends StatefulWidget {
  // This widget is the root of your application.
  @override
  SearchAppState createState() => SearchAppState();
}

class SearchAppState extends State<SearchApp> {

  GenericRoutePackageParser _routePackageParser = GenericRoutePackageParser(
    routePatterns: <Object, RoutePattern>{
      ...homePattens,
      ...moviePatterns
    }
  );



  GenericRouterDelegate _routerDelegate = GenericRouterDelegate(
    routeBuilders: <Object, WidgetBuilder>{
      ...homeBuilders,
      ...movieBuilders,
    },
    onPushNameRoute: (RouteSettings settings) {
      if (settings.name == 'dialog') {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (BuildContext context) => Text('dialog'),
        );
      }
      return null;
    }
  );

  PlatformRoutePackageProvider _routePackageProvider = PlatformRoutePackageProvider(
    initialRoutePackage: RoutePackage(routeName: '/')
  );

  BackButtonDispatcher _backButtonDispatcher = RootBackButtonDispatcher();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      routePackageParser: _routePackageParser,
      routerDelegate: _routerDelegate,
      routePackageProvider: _routePackageProvider,
      backButtonDispatcher: _backButtonDispatcher,
    );
  }
}