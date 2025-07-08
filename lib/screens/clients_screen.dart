import 'package:flutter/material.dart';
import '../models/client.dart'; // Correct import for Client model
import 'services/client_service.dart'; // Correct import for ClientService

class ClientsScreen extends StatefulWidget {
  @override
  _ClientsScreenState createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  List<Client> _clients = [];

  @override
  void initState() {
    super.initState();
    _fetchClients();
  }

  Future<void> _fetchClients() async {
    try {
      final fetchedClients = await ClientService().getClients();
      setState(() {
        _clients = fetchedClients;
      });
    } catch (e) {
      print('Error fetching clients: $e');
    }
  }

  List<Client> getBlockedClients() {
    return _clients.where((c) => c.isBlocked == true).toList();
  }

  List<Client> getOnlineClients() {
    return _clients
        .where((c) => c.isOnline == true && c.isBlocked != true)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Clients'),
      ),
      body: ListView.builder(
        itemCount: _clients.length,
        itemBuilder: (context, index) {
          final client = _clients[index];
          return ListTile(
            title: Text(client.name),
            subtitle: Text(client.email),
            trailing: Icon(
              client.isOnline == true
                  ? Icons.circle
                  : Icons.radio_button_unchecked,
              color: client.isOnline == true ? Colors.green : Colors.red,
            ),
            onTap: () {
              // Handle client tap
            },
          );
        },
      ),
    );
  }
}
