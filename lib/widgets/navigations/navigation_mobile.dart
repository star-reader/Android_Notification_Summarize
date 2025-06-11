import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/providers/navigation_store.dart';

class NavigationMobile extends StatefulWidget {
  const NavigationMobile({super.key});

  @override
  State<NavigationMobile> createState() => _NavigationMobileState();
}

class _NavigationMobileState extends State<NavigationMobile> {
  @override
  Widget build(BuildContext context) {

    final navigationStore = Provider.of<NavigationStore>(context);

    return NavigationBar(
        onDestinationSelected: (int index) {
          navigationStore.setCurrentPageIndex(index);
        },
        selectedIndex: navigationStore.currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.home),
            icon: Icon(Icons.home_outlined),
            label: '主页',
          ),
          NavigationDestination(
            icon: Badge(child: Icon(Icons.notifications_sharp)),
            label: '通知',
          ),
          NavigationDestination(
            icon: Badge(label: Text('2'), child: Icon(Icons.person)),
            label: '个人',
          ),
        ],
      );
  }
}