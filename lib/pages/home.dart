import 'package:flutter/material.dart';
import './home_page.dart';
import './transaksi_page.dart';
import './laporan_page.dart';
import './setting_page.dart';

class MyHomePage extends StatefulWidget {
  final String role; // menerima role dari login (admin / user)

  const MyHomePage({Key? key, required this.role}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  late List<Widget> _pages;
  late List<BottomNavigationBarItem> _navBarItems;

  @override
  void initState() {
    super.initState();

    // Setup menu sesuai role
    if (widget.role == 'admin') {
      _pages = [
        HomePage(),
        TransaksiPage(),
        LaporanPage(),
        SettingPage(),
      ];
      _navBarItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Transaksi'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Laporan'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Setting'),
      ];
    } else {
      _pages = [
        HomePage(),
        TransaksiPage(),
        SettingPage(),
      ];
      _navBarItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Transaksi'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Setting'),
      ];
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: _navBarItems,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
