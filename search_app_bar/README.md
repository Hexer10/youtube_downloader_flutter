# search_app_bar

An animated SearchAppBar Widget, to be used with Flutter.

![](demo.gif)

## Usage

Simply use the `SearchAppBar` widget as a regular AppBar.
The only required attribute in the widget is called `searcher`.

You must implement the `Searcher<T>` interface in a class of yours (a Bloc, for example), to
control a list of data (of type `T`) and react to the list filtering provided by `SearchAppBar`.

Here's a simple example of `SearchAppBar`'s usage with bloc:

    Scaffold(
      appBar: SearchAppBar<String>(
        searcher: bloc,
      ),
      body: ...
    );

## Implementing Searcher

When you implement the `Searcher` interface in your class, you must provide an implementation for both overrides:
    
    class BlocExample implements Searcher<String> {
        ...
    
        @override
        List<String> get data => ...

        @override
        get onDataFiltered => ...
    }

`data` should simply return your full data list (in this case, a list of Strings), in which you will search for elements.

`onDataFiltered` expects a function that receives a `List<T>`. This is the filtered data list, based on what was typed on the `SearchAppBar`. Use that list as you will. 
For example, if you are using Bloc, add this filtered list to your data's `StreamController`.

## Complete Example

Here's a complete example of a view using `SearchAppBar`:

    import 'package:flutter/material.dart';
    import 'package:search_app_bar/filter.dart';
    import 'package:search_app_bar/search_app_bar.dart';

    import 'home_bloc.dart';

    void main() => runApp(MyApp());

    class MyApp extends StatelessWidget {
      @override
      Widget build(BuildContext context) {
        return MaterialApp(
          title: 'Search App Bar Demo',
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          home: MyHomePage(
            title: 'Search App Bar Demo',
            bloc: HomeBloc(),
          ),
        );
      }
    }

    class MyHomePage extends StatelessWidget {
      final String title;
      final HomeBloc bloc;

      MyHomePage({
        this.title,
        this.bloc,
      });

      @override
      Widget build(BuildContext context) {
        return Scaffold(
          appBar: SearchAppBar<String>(
            title: Text(title),
            searcher: bloc,
            iconTheme: IconThemeData(color: Colors.white),
          ),
          body: StreamBuilder<List<String>>(
            stream: bloc.filteredData,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return Container();
              final list = snapshot.data;
              return ListView.builder(
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(list[index]),
                  );
                },
                itemCount: list.length,
              );
            },
          ),
        );
      }
    }

Below is an example of a HomeBloc class that implements `Searcher`:
(This example also uses the `bloc_pattern` library to implement a bloc class)

    import 'package:bloc_pattern/bloc_pattern.dart';
    import 'package:rxdart/subjects.dart';
    import 'package:search_app_bar/searcher.dart';

    class HomeBloc extends BlocBase implements Searcher<String> {
      final _filteredData = BehaviorSubject<List<String>>();

      final dataList = [
        'Thaís Fernandes',
        'Vinicius Santos',
        'Gabrielly Costa',
        'Olívia Sousa',
        'Diogo Lima',
        'Lucas Assunção',
        'Conceição Cardoso'
      ];

      Stream<List<String>> get filteredData => _filteredData.stream;

      HomeBloc() {
        _filteredData.add(dataList);
      }

      @override
      get onDataFiltered => _filteredData.add;

      @override
      get data => dataList;

      @override
      void dispose() {
        _filteredData.close();
        super.dispose();
      }
    }

## Filters

Note how, in our example, we used a data list of type `List<String>`. 

In this specific case, we can omit the `filter` parameter if we want. It will be implied that we will search for strings in our data list that start with whatever we type on the `SearchAppBar`.

However, let's say that we need to search for a person's name inside a list of `Person`:

    class Person {
        final String name;
        final String occupation;
        final int age;
        ...
    }

In this case, we will need to implement a `Searcher<Person>` and provide a way for `SearchAppBar` to filter `Person` data as we want.

Enter the `filter` parameter:

    SearchAppBar<Person>(
        searcher: bloc,
        filter: (Person person, String query) => Filters.startsWith(person.name, query),
    );

Here we are instructing our `SearchAppBar` to filter only the `Person` objects whose names start with the typed query on the search bar.

The `Filters` class is provided with this library and contain the following pre-made `String` filters: `startsWith`, `equals`and `contains`.

These filters compare strings unregarding upper/lower case and diacritics.

You can also create your own `Filter` if you need.

## Parameters

Here's a list of all `SearchAppBar` parameters and what they do:

`searcher`: You must provide an object that implements `Searcher<T>` here.

`filter`: You can provide a customized filter here if needed.

`title`: The title widget on the app bar.

`centerTitle`: If `true`, this centralizes the `title` widget.

`iconTheme`: Used to define the colors of `IconButtons` on the app bar.

`backgroundColor`: AppBar's Background color.

`searchBackgroundColor`: The color used as the AppBar's background when the search is active.

`searchElementsColor`: Mainly used for icons, such as the back arrow button, when the search is active.

`hintText`: The text shown as a hint when the search is active.

`flattenOnSearch`: If `true`, removes the AppBar's elevation when the search is active.

`capitalization`: The capitalization rule for the search text on the AppBar.

`actions`: You can provide other `IconButton` within this array. They will appear besides the search button.

`searchButtonPosition`: The index that the search button should occupy in the actions array. It defaults to the last position.

## Disclaimer

This small library was developed (and later, improved)
based on the excellent tutorial provided by Nishant Desai at:
https://blog.usejournal.com/change-app-bar-in-flutter-with-animation-cfffb3413e8a

All due credit goes to him :)
