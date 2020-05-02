import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'routing_util.dart';

class GenericRouterDelegate extends RouterDelegate<List<PageConfiguration>> with PopNavigatorRouterDelegateMixin<List<PageConfiguration>> {
  GenericRouterDelegate({
    @required this.routeBuilders,
    this.onPushNameRoute,
  });

  final Map<Object, WidgetBuilder> routeBuilders;

  List<PageConfiguration> get pageConfigurations => _pageConfigurations;
  List<PageConfiguration> _pageConfigurations;
  set pageConfigurations (List<PageConfiguration> other) {
    if (_pageConfigurations == other)
      return;
    _pageConfigurations = other;
    notifyListeners();
  }

  final RouteFactory onPushNameRoute;

  @override
  GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Future<List<PageConfiguration>> get currentConfiguration {
    return SynchronousFuture<List<PageConfiguration>>(pageConfigurations);
  }

  @override
  Future<void> setNewRoutePath(List<PageConfiguration> pageConfigurations) {
    _pageConfigurations = pageConfigurations;
    return SynchronousFuture<void>(null);
  }

  Page<void> _producePage(PageConfiguration pageConfiguration) {
    final Object patternKey = pageConfiguration.parsedResult.patternKey;
    return MaterialPage(
      key: ValueKey<String>(patternKey),
      builder: (BuildContext context) {
        return PageConfigurationWidget(
          data: pageConfiguration,
          child: Builder(
            builder: (BuildContext context) {
              return routeBuilders[pageConfiguration.parsedResult.patternKey](context);
            },
          )
        );
      }
    );
  }

  List<Page<void>> _buildPages() {
    return pageConfigurations.map<Page<void>>(_producePage).toList();
  }

  bool _handlePopPage(Route<dynamic> route, dynamic result) {
    final bool success = route.didPop(result);
    if (success)
      pageConfigurations.removeLast();
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