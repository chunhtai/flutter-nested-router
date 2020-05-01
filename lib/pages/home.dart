import 'package:flutter/material.dart';
import 'package:nested_routers/routing_util.dart';

final String homePattern = 'home';

final Map<Object, dynamic> homePattens = <Object, dynamic>{
  homePattern : RoutePattern('/'),
};

final Map<Object, WidgetBuilder> homeBuilders = <Object, WidgetBuilder>{
  homePattern : home,
};

Widget home(BuildContext context) {
  return HomeWidget();
}

class HomeWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => HomeWidgetState();
}

class HomeWidgetState extends State<HomeWidget> {

  @override
  Widget build(BuildContext context) {
    final TextEditingController search = TextEditingController();
    return Scaffold(
      appBar: AppBar(title: Text('Welcome to Search App')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width - 100,
                  child: TextField(
                    controller: search,
                    onSubmitted: (String value) {
                      if (value != null && value.length > 0) {
                        final PlatformRoutePackageProvider provider = Router.of(context).routePackageProvider as PlatformRoutePackageProvider;
                        // We probably want to avoid query injection.
                        provider.value = RoutePackage(
                          routeName: '/movies?search=$value',
                        );
                      }
                    },
                  )
                ),
              ],
            ),
            RaisedButton(
              child: Text('push name route'),
              onPressed: () {
                Navigator.of(context).pushNamed('dialog');
              },
            )
          ],
        )
      ),
    );
  }
}