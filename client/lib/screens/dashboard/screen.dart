import 'package:async_builder/async_builder.dart';
import 'package:client/models/server.dart';
import 'package:client/screens/dashboard/body.dart';
import 'package:client/screens/widgets/simple_drop_down.dart';
import 'package:client/screens/widgets/standard_text.dart';
import 'package:client/service/database_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DashboardScreen extends StatefulWidget {

  @override
  State<StatefulWidget> createState() => DashboardScreenState();

}
class DashboardScreenState extends State<DashboardScreen> {
  DatabaseManager _dbManager = DatabaseManager();
  Server _selectedServer;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Center(
          child: AsyncBuilder<List<Server>>(
            future: _dbManager.getServerTokens(),
            waiting: (context) => Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                    child: CircularProgressIndicator()
                ),
              ],
            ),
            builder: (context, servers) {
              List<String> serverIds = [];
              for (var s in servers)
                serverIds.add(s.name);
              return Column(
                children: [
                  SizedBox(height: 80.h,),
                  Center(
                    child: StandardText(
                      color: Colors.black,
                      text: "Client Web App",
                      size: 32.sp,
                      weight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 80.h,),
                  Center(
                    child: SimpleDropDown(
                      initialMessage: _selectedServer == null ? "Select Server Id" : null,
                      firstSelected: _selectedServer?.name,
                      extendsWords: true,
                      elements: serverIds,
                      onSelectedElement: (serverId) {
                        setState(() {
                          for (var s in servers) {
                            if (s.name == serverId)
                              _selectedServer = s;
                          }
                        });
                      },
                    ),
                  ),
                  DashboardBody(server: _selectedServer),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

}