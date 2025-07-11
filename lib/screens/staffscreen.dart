import 'package:flutter/material.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});
  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Color(0xFF1E1E1E),
        appBar: AppBar(
          backgroundColor: Color(0xFF1E1E1E),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {},
          ),
          title: Text("Staff Management", style: TextStyle(color: Colors.white)),
          actions: [
            Icon(Icons.notifications),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(child: Icon(Icons.person)),
            ),
          ],
          bottom: TabBar(
            labelColor: Colors.pinkAccent,
            unselectedLabelColor: Colors.white,
            tabs: [
              Tab(text: "Staff Management"),
              Tab(text: "Attendance"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            StaffTable(),
            Center(
              child: Text(
                "Attendance Tab Content",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {},
          label: Text("Add Staff", style: TextStyle(color: Colors.white)),
          icon: Icon(Icons.add, color: Colors.white),
          backgroundColor: Colors.blue,
        ),
      ),
    );
  }
}

class StaffTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(Colors.grey[900]),
            dataRowColor: MaterialStateProperty.all(Color(0xFF2C2C2C)),
            columns: [
              DataColumn(label: Text("ID", style: TextStyle(color: Colors.white))),
              DataColumn(label: Text("Name", style: TextStyle(color: Colors.white))),
              DataColumn(label: Text("Email", style: TextStyle(color: Colors.white))),
              DataColumn(label: Text("Phone", style: TextStyle(color: Colors.white))),
              DataColumn(label: Text("Age", style: TextStyle(color: Colors.white))),
              DataColumn(label: Text("Salary", style: TextStyle(color: Colors.white))),
              DataColumn(label: Text("Timings", style: TextStyle(color: Colors.white))),
              DataColumn(label: Text("Actions", style: TextStyle(color: Colors.white))),
            ],
            rows: List.generate(
              10,
                  (index) => DataRow(
                cells: [
                  DataCell(Text("#101", style: TextStyle(color: Colors.white))),
                  DataCell(
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: NetworkImage("https://via.placeholder.com/50"),
                          radius: 12,
                        ),
                        SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Watson Joyce",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                )),
                            Text("Manager", style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  DataCell(Text("watsonjoyce112@gmail.com", style: TextStyle(color: Colors.white))),
                  DataCell(Text("+1 (123) 123 4654", style: TextStyle(color: Colors.white))),
                  DataCell(Text("45 yr", style: TextStyle(color: Colors.white))),
                  DataCell(Text("\$2200.00", style: TextStyle(color: Colors.white))),
                  DataCell(Text("9am to 6pm", style: TextStyle(color: Colors.white))),
                  DataCell(
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.visibility, color: Colors.pinkAccent),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.white),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}