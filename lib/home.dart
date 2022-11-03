import 'package:char/main.dart';
import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        shape: Border(bottom: BorderSide(color: Colors.white10, width: 1.0)),
        leading: Center(child: Text('Char', style: Theme.of(context).textTheme.titleLarge)),
        leadingWidth: 82.0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: isDesktop
            ? Padding(
                padding: const EdgeInsets.only(right: 24, top: 10, bottom: 10),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: 500.0, maxWidth: 500.0),
                  child: Center(child: CharSearchBar()),
                ),
              )
            : null,
        actions: [
          SizedBox(
            height: 64.0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isDesktop) ...[
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed('search');
                    },
                    icon: Icon(Icons.search),
                    constraints: BoxConstraints(minWidth: 54.0, minHeight: 54.0),
                  ),
                  SizedBox(width: 4.0),
                ],
                IconButton(onPressed: () {}, icon: Icon(Icons.settings), constraints: BoxConstraints(minWidth: 54.0, minHeight: 54.0)),
                SizedBox(width: 4.0),
                IconButton(onPressed: () {}, icon: Icon(Icons.person), constraints: BoxConstraints(minWidth: 54.0, minHeight: 54.0)),
                SizedBox(width: 14.0),
              ],
            ),
          )
        ],
      ),
      // body: Padding(
      //   padding: const EdgeInsets.all(24.0),
      //   child: Column(
      //     children: [
      //       if (!isDesktop) CharSearchBar(),
      //     ],
      //   ),
      // ),
    );
  }
}

class CharSearchBar extends StatelessWidget {
  final bool focused;

  const CharSearchBar({
    this.focused = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      autofocus: focused,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(999.9)),
        fillColor: Colors.black26,
        contentPadding: EdgeInsets.symmetric(horizontal: 18.0, vertical: 0.0),
        filled: true,
        hintText: 'Search Char',
        hintStyle: TextStyle(color: Colors.grey.shade500),
        hoverColor: Colors.black12,
        prefixIcon: Center(child: Icon(Icons.search, size: 20.0)),
        prefixIconConstraints: BoxConstraints(minWidth: 45.0, maxWidth: 45.0),
        suffixIcon: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 6.0,
            vertical: 2.0,
          ),
          child: IconButton(
            padding: EdgeInsets.symmetric(horizontal: 14.0),
            icon: Icon(Icons.search),
            onPressed: () {},
          ),
        ),
      ),
    );
  }
}

class HomeSearchPage extends StatelessWidget {
  const HomeSearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        centerTitle: true,
        title: CharSearchBar(focused: true),
      ),
    );
  }
}
