import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// think about state!
class ParsedResult {
  ParsedResult({
    this.patternKey,
    this.routeParameters,
    this.subRouteResult,
  });
  final Object patternKey;
  final ParsedResult subRouteResult;
  final Map<String, String> routeParameters;

  @override
  String toString() {
    return '$patternKey $subRouteResult';
  }
}

class PageConfiguration {
  const PageConfiguration({
    this.parsedResult,
    this.state,
    this.queryParameters,
  });
  final ParsedResult parsedResult;
  final Map<String, String> state;
  final Map<String, List<String>> queryParameters;


  static PageConfiguration of(BuildContext context) {
    assert(context != null);
    final PageConfigurationWidget query = context.dependOnInheritedWidgetOfExactType<PageConfigurationWidget>();
    if (query != null)
      return query.data;
    return null;
  }
}

class PageConfigurationWidget extends InheritedWidget {
  const PageConfigurationWidget({
    Key key,
    @required this.data,
    @required Widget child,
  }) : assert(child != null),
       super(key: key, child: child);

  final PageConfiguration data;

  @override
  bool updateShouldNotify(PageConfigurationWidget oldWidget) => data != oldWidget.data;
}

class RoutePattern {
  RoutePattern(
    this.pattern, {
    this.children,
  });
  final String pattern;
  final Map<Object, RoutePattern> children;
}


/// The data structure to store the result from route matching.
@immutable
class RouteMatch {
  /// Creates a route match object.
  const RouteMatch({
    this.routeName,
    this.pattern,
    this.routeParameters,
    this.subRouteName,
  });

  /// The original route name.
  final String routeName;

  /// The pattern that are used in the route match
  final String pattern;

  /// The route parameter that are captured in the route match.
  final Map<String, String> routeParameters;

  /// The sub route name that is captured in the route match
  final String subRouteName;
}

/// Matches the string route name with a given pattern.
///
/// The pattern includes both exact strings or route parameters. To capture
/// a route parameter, uses semicolon follows by the route parameter name.
///
/// ex.
///
/// `/profile/:id` will match the string route name `/profile/1` and capture
/// `1` as id.
///
/// The route parameters are stored in the [RouteMatch.routeParameter].
///
/// You can also uses wild-card character `*` at the end of the pattern to
/// match arbitrary trailing string. The trailing string is treated as sub route
/// name and stored in the RouteMatch.subRouteName].
///
/// ex.
///
/// `/profile/*` will match the string route name `/profile/1/settings` and
/// capture `1/settings` as sub route name.
///
/// This function returns null if the string route name does not match the
/// pattern.
RouteMatch matchRoutePattern({String routeName, String pattern}) {
  String regExpSource = pattern;
  // If the string end with a wild-card character, we replace it with matching
  // all regular expression.
  if (regExpSource.endsWith('*')) {
    regExpSource = regExpSource.substring(0, regExpSource.length -1) + '(.*)';
  }

  // Replaces all route parameters to real regular expression.
  final RegExp routeParameterMatcher = RegExp(r':([^\/]+)');
  final Iterable<RegExpMatch> allRouteParameter = routeParameterMatcher.allMatches(regExpSource);
  for (final RegExpMatch parameter in allRouteParameter) {
    final String name = parameter.group(1);
    regExpSource = regExpSource.replaceFirst(':$name', '(?<$name>[^\\/]+)');
  }
  final RegExp routeParsingRegExp = RegExp(regExpSource);

  final RegExpMatch matchedResults = routeParsingRegExp.firstMatch(routeName);

  // We are looking for a full match.
  if (matchedResults == null || matchedResults.group(0) != routeName)
    return null;

  assert(
  matchedResults.groupNames.length == matchedResults.groupCount ||
    matchedResults.groupNames.length == matchedResults.groupCount - 1
  );

  Map<String, String> routeParameters;
  for (final String routeParameterName in matchedResults.groupNames) {
    routeParameters = routeParameters ?? <String, String>{};
    routeParameters[routeParameterName] = matchedResults.namedGroup(routeParameterName);
  }

  String subRouteName;
  if (matchedResults.groupNames.length != matchedResults.groupCount) {
    subRouteName = matchedResults.group(matchedResults.groupCount);
  }

  return RouteMatch(
    routeName: routeName,
    pattern: pattern,
    routeParameters: routeParameters,
    subRouteName: subRouteName,
  );
}