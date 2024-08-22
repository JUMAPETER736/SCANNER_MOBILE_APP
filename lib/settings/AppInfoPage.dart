

class AppInfoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('App Information'),
      ),
      body: Center(
        child: Text('View app version and support information.'),
      ),
    );
  }
}
