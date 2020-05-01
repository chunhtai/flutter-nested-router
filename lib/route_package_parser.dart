import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'routing_util.dart';

class GenericRoutePackageParser extends RoutePackageParser<List<ParsedResult>> {
  GenericRoutePackageParser({this.routePatterns});
  final Map<Object, RoutePattern> routePatterns;

  ParsedResult _parse(
    String routeName,
    Map<Object, RoutePattern> routingTable,
    Map<String, List<String>> queryParameters
  ) {
    RouteMatch match;
    for (final Object patternKey in routingTable.keys) {
      match = matchRoutePattern(routeName: routeName, pattern: routingTable[patternKey].pattern);
      if (match != null) {
        final Map<Object, RoutePattern> subPatterns = routingTable[patternKey].children;
        ParsedResult subResult;
        if (match.subRouteName?.isNotEmpty == true) {
          subResult = _parse(match.subRouteName, subPatterns, queryParameters);
        }
        return ParsedResult(
          routeParameters: match.routeParameters,
          patternKey: patternKey,
          queryParameters: queryParameters,
          subRouteResult: subResult,
        );
      }
    }
    return null;
  }

  @override
  Future<List<ParsedResult>> parse(RoutePackage routePackage) {
    String routeName = routePackage.routeName;
    final int startOfQuery = routeName.indexOf('?');
    final String path = routeName.substring(0, startOfQuery >= 0 ? startOfQuery : routeName.length);
    final String query = startOfQuery >= 0 ? routeName.substring(startOfQuery + 1, routeName.length) : '';
    final Uri syntheticUrl = new Uri(path: path, query: query);
    final List<String> paths = <String>['/'];
    if (syntheticUrl.pathSegments.isNotEmpty) {
      final StringBuffer path = new StringBuffer('');
      for (String segment in syntheticUrl.pathSegments) {
        path.write('/$segment');
        paths.add(path.toString());
      }
    }
    final Map<String, List<String>> arguments = Map<String, List<String>>.from(syntheticUrl.queryParametersAll);
    final List<ParsedResult> result = <ParsedResult>[];
    for (String routePath in paths)
      result.add(_parse(routePath, routePatterns, arguments));
    result.removeWhere((ParsedResult element) => element == null);
    assert(_restoreRouteName(result.last, routePatterns) == paths.last, 'no match for route name ${paths.last}');
    return SynchronousFuture<List<ParsedResult>>(result);
  }

  String _restoreRouteName(ParsedResult result, Map<Object, RoutePattern> patterns) {
    final RoutePattern routePattern = patterns[result.patternKey];

    String path = routePattern.pattern;
    if (result.routeParameters != null) {
      for (final String routeParameter in result.routeParameters.keys) {
        path = path.replaceFirst(
          ':$routeParameter', result.routeParameters[routeParameter]);
      }
    }
    if (path.endsWith('*') && result.subRouteResult != null) {
      path = path.replaceFirst('*', _restoreRouteName(result.subRouteResult, patterns[result.patternKey].children));
    }
    return path;
  }

  @override
  Future<RoutePackage> restore(List<ParsedResult> configuration) {
    final String routeName = Uri(
      path: _restoreRouteName(configuration.last, routePatterns),
      queryParameters: configuration.last.queryParameters
    ).toString();
    return SynchronousFuture<RoutePackage>(RoutePackage(routeName: routeName));
  }
}