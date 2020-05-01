import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'routing_util.dart';

class GenericRouterDelegate extends RouterDelegate<List<ParsedResult>> with PopNavigatorRouterDelegateMixin<List<ParsedResult>> {
  GenericRouterDelegate({
    @required this.routeBuilders,
    this.onPushNameRoute,
  });

  final Map<Object, WidgetBuilder> routeBuilders;

  List<ParsedResult> get parsedResult => _parsedResult;
  List<ParsedResult> _parsedResult;
  set parsedResult (List<ParsedResult> other) {
    if (_parsedResult == other)
      return;
    _parsedResult = other;
    notifyListeners();
  }

  final RouteFactory onPushNameRoute;

  @override
  GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Future<List<ParsedResult>> get currentConfiguration {
    return SynchronousFuture<List<ParsedResult>>(parsedResult);
  }

  @override
  Future<void> setNewRoutePath(List<ParsedResult> parsedResult) {
    _parsedResult = parsedResult;
    return SynchronousFuture<void>(null);
  }

  Page<void> _producePage(ParsedResult parsedResult) {
    final Object patternKey = parsedResult.patternKey;
    return MaterialPage(
      key: ValueKey<String>(patternKey),
      builder: (BuildContext context) {
        return ParsedResultWidget(
          data: parsedResult,
          child: Builder(
            builder: (BuildContext context) {
              return routeBuilders[parsedResult.patternKey](context);
            },
          )
        );
      }
    );
  }

  List<Page<void>> _buildPages() {
    return parsedResult.map<Page<void>>(_producePage).toList();
  }

  bool _handlePopPage(Route<dynamic> route, dynamic result) {
    final bool success = route.didPop(result);
    if (success)
      parsedResult.removeLast();
    return success;
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: onPushNameRoute,
      pages: _buildPages(),
      onPopPage: _handlePopPage,
      transitionDelegate: DefaultTransitionDelegate(),
    );
  }

}