import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nested_routers/routing_util.dart';
import 'package:nested_routers/router_delegate.dart';

final String moviesRoutePattern = 'movies';
final String movieRoutePattern = 'movie';
final String movieDescriptionPattern = 'movie_description';
final String movieDirectorPattern = 'movie_author';


final Map<Object, RoutePattern> moviePatterns = <Object, RoutePattern>{
  moviesRoutePattern: RoutePattern('/movies'),
  movieRoutePattern: RoutePattern('/movies/:id/*', children: {
    movieDescriptionPattern: RoutePattern('description'),
    movieDirectorPattern: RoutePattern('description/director'),
  }),
};

final Map<Object, WidgetBuilder> movieBuilders = <Object, WidgetBuilder>{
  moviesRoutePattern: movieListWidget,
  movieRoutePattern: movieWidget,
};

Widget movieListWidget(BuildContext context) {
  final PageConfiguration pageConfiguration = PageConfiguration.of(context);
  String searchTerm;
  if (pageConfiguration.queryParameters != null && pageConfiguration.queryParameters.containsKey('search')) {
    searchTerm = pageConfiguration.queryParameters['search'][0];
  }
  return MovieList(searchTerm: searchTerm);
}

class MovieList extends StatelessWidget {
  MovieList({
    Key key,
    this.searchTerm,
  }) : super(key: key);

  final String searchTerm;

  Future<List<Map<String, dynamic>>> loadMovieJson(BuildContext context) async {
    final String data = await DefaultAssetBundle.of(context).loadString("assets/movies.json");
    final List<Map<String, dynamic>> result = (jsonDecode(data) as List<dynamic>).cast<Map<String, dynamic>>();
    return result;
  }

  Widget _buildBody(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: loadMovieJson(context),
      builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
        if (snapshot.hasData) {
          List<Map<String, dynamic>> movieList = snapshot.data;
          if (searchTerm != null) {
            movieList = movieList.where((Map<String, dynamic> movie) => (movie['name'] as String).contains(searchTerm)).toList();
            if (movieList.isEmpty) {
              return Center(
                child: Text("No matching movie"),
              );
            }
            else {
              return ListView.builder(itemBuilder: (BuildContext context, int index) {
                  if (index >= (movieList.length * 2) - 1) {
                    return null;
                  }
                  if (index % 2 == 1) {
                    return Divider();
                  }
                  return InkWell(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(movieList[(index ~/ 2)]['name'] as String),
                    ),
                    onTap: () {
                      final GenericRouterDelegate delegate = Router.of(context).routerDelegate as GenericRouterDelegate;
                      // Pushes a new page route
                      delegate.pageConfigurations = List<PageConfiguration>.from(delegate.pageConfigurations..add(PageConfiguration(
                        parsedResult: ParsedResult(
                          patternKey: movieRoutePattern,
                          routeParameters: <String, String>{
                            'id': movieList[(index ~/ 2)]['id']
                          },
                          subRouteResult: null,
                        )
                      )));
                    },
                  );
                });
            }
          }
        }
        return Center(
          child: Text("Still loading...."),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Movies')),
      body: _buildBody(context),
    );
  }
}

class ParsedResultWidget extends InheritedWidget {
  const ParsedResultWidget({
    Key key,
    @required this.data,
    @required Widget child,
  }) : assert(child != null),
      super(key: key, child: child);

  final ParsedResult data;

  static ParsedResult of(BuildContext context) {
    assert(context != null);
    final ParsedResultWidget query = context.dependOnInheritedWidgetOfExactType<ParsedResultWidget>();
    if (query != null)
      return query.data;
    return null;
  }

  @override
  bool updateShouldNotify(ParsedResultWidget oldWidget) => data != oldWidget.data;
}

Widget movieWidget(BuildContext context) {
  final PageConfiguration pageConfiguration = PageConfiguration.of(context);
  return ParsedResultWidget(
    data: pageConfiguration.parsedResult.subRouteResult,
    child: MoviePage(parameters: pageConfiguration.parsedResult.routeParameters),
  );
}

class MoviePage extends StatelessWidget {
  MoviePage({
    Key key,
    @required this.parameters,
  }) : assert(parameters != null),
       super(key: key);

  final Map<String, String> parameters;

  Future<Map<String, dynamic>> loadMovieJsonById(BuildContext context, String id) async {
    final String data = await DefaultAssetBundle.of(context).loadString("assets/movies.json");
    final List<Map<String, dynamic>> result = (jsonDecode(data) as List<dynamic>).cast<Map<String, dynamic>>();
    final Map<String, dynamic> movie = result.firstWhere((Map<String, dynamic> movie) => (movie['id'] as String) == id, orElse: () => null);
    return movie;
  }

  Widget _buildBody(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: loadMovieJsonById(context, parameters['id']),
      builder: (BuildContext context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
        if (snapshot.hasData) {
          final Map<String, dynamic> movie = snapshot.data;
          if (movie == null) {
            return Center(
              child: Text("The selected movie cannot be found"),
            );
          }
          return MovieContent(movie: movie);
        }
        return Center(
          child: Text("Still loading...."),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Movie')),
      body: _buildBody(context),
    );
  }
}

class MovieContent extends StatelessWidget {
  MovieContent({this.movie});

  final Map<String, dynamic> movie;

  @override
  Widget build(BuildContext context) {
    final RootBackButtonDispatcher backButtonDispatcher = Router.of(context).backButtonDispatcher as RootBackButtonDispatcher;
    return Router(
      backButtonDispatcher: ChildBackButtonDispatcher(backButtonDispatcher)..takePriority(),
      routerDelegate: MovieRouterDelegate(
        movie,
        ParsedResultWidget.of(context),
        Router.of(context).routerDelegate as GenericRouterDelegate,
      ),
    );
  }
}

class MovieRouterDelegate extends RouterDelegate<void> {
  MovieRouterDelegate(
    this._movie,
    this._subRouteResult,
    this._parent
    ) : _widgets = <Widget>[] {
    _widgets.add(_buildHomePage());
    if (_subRouteResult != null) {
      if (_subRouteResult.patternKey == movieDescriptionPattern ||
        _subRouteResult.patternKey == movieDirectorPattern) {
        _widgets.add(_buildDescriptionPage());
      }
      if (_subRouteResult.patternKey == movieDirectorPattern) {
        _widgets.add(_buildAuthorPage());
      }
    }
  }

  Map<String, dynamic> _movie;
  final List<Widget> _widgets;
  final GenericRouterDelegate _parent;
  final ParsedResult _subRouteResult;

  Widget _buildHomePage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('The movie you are watch is ${_movie['name']}'),
        RaisedButton(
          child: Text('See description'),
          onPressed: () {
            final PageConfiguration current = _parent.pageConfigurations.removeLast();
            // Makes sure we are on the right page.
            assert(current.parsedResult.patternKey == movieRoutePattern);
            // Modifies the subroute directly.
            final PageConfiguration newResults = PageConfiguration(
              parsedResult: ParsedResult(
                patternKey: current.parsedResult.patternKey,
                routeParameters: current.parsedResult.routeParameters,
                subRouteResult: ParsedResult(
                  patternKey: movieDescriptionPattern,
                )
              ),
              queryParameters: current.queryParameters,
              state: current.state,
            );
            _parent.pageConfigurations = List<PageConfiguration>.from(
              _parent.pageConfigurations..add(newResults)
            );
          },
        )
      ],
    );
  }

  Widget _buildDescriptionPage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('The description of ${_movie['name']}:'),
        Text(_movie['description']),
        RaisedButton(
          child: Text('See director'),
          onPressed: () {
            final PageConfiguration current = _parent.pageConfigurations.removeLast();
            // Makes sure we are on the right page.
            assert(current.parsedResult.patternKey == movieRoutePattern);
            // Modifies the subroute directly.
            final PageConfiguration newResults = PageConfiguration(
              parsedResult: ParsedResult(
                patternKey: current.parsedResult.patternKey,
                routeParameters: current.parsedResult.routeParameters,
                subRouteResult: ParsedResult(
                  patternKey: movieDirectorPattern,
                )
              ),
              queryParameters: current.queryParameters,
              state: current.state,
            );
            _parent.pageConfigurations = List<PageConfiguration>.from(
              _parent.pageConfigurations..add(newResults)
            );
          },
        )
      ],
    );
  }

  Widget _buildAuthorPage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('The director of ${_movie['name']}:'),
        Text(_movie['director']),
      ],
    );
  }

  @override
  Future<bool> popRoute() {
    if (_widgets.length <= 1)
      return SynchronousFuture<bool>(false);
    _widgets.removeLast();
    notifyListeners();
    return SynchronousFuture<bool>(true);
  }

  @override
  Future<void> setNewRoutePath(void configuration) {
    // should never be called.
    throw UnimplementedError();
  }

  @override
  Widget build(BuildContext context) {
    return _widgets.last;
  }
}

