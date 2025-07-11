import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    decoration: BoxDecoration(
                        color: Color(0xFF3D4142),
                        borderRadius: BorderRadius.all(Radius.circular(10))),
                    width: 350,
                    height: 166.41,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Text(
                                'Daily Sales',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18
                                ),
                              ),
                              SizedBox(width: 80,),
                              Container(
                                width: 35,
                                height: 35,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.currency_rupee,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                        color: Color(0xFF3D4142),
                        borderRadius: BorderRadius.all(Radius.circular(10))),
                    width: 350,
                    height: 166.41,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Text(
                                'Monthly Revenue',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18
                                ),
                              ),
                              SizedBox(width: 80,),
                              Container(
                                width: 35,
                                height: 35,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.money,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                        color: Color(0xFF3D4142),
                        borderRadius: BorderRadius.all(Radius.circular(10))),
                    width: 350,
                    height: 166.41,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Text(
                                'Oders',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18
                                ),
                              ),
                              SizedBox(width: 80,),
                              Container(
                                width: 35,
                                height: 35,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.shopping_cart,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    decoration: BoxDecoration(
                        color: Color(0xFF292C2D),
                        borderRadius: BorderRadius.all(Radius.circular(10))),
                    width: 500,
                    height: 466,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                'Popular Items',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 25
                                ),
                              ),
                              SizedBox(width: 80,),
                            ],
                          ),
                        ),
                        // List of hardcoded items
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            width: 450,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Color(0xFF3D4142),
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Image.asset('assets/images/thumbnail.png'),
                                SizedBox(width: 50,),
                                Text('Dove Soap',style: TextStyle(color: Colors.white,fontSize: 18),),
                                SizedBox(width:150,),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('In Stock',style: TextStyle(color: Color(0xFFFAC1D9),fontSize:16 ),),
                                    Text('RS.55.00',style: TextStyle(color: Colors.white,fontSize:16 ),),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            width: 450,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Color(0xFF3D4142),
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                            ),
                            child: Row(
                              children: [
                                Image.asset('assets/images/dove.png'),
                                Text('Dove Soap',style: TextStyle(color: Colors.white,fontSize: 18),),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            width: 450,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Color(0xFF3D4142),
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                            ),
                            child: Row(
                              children: [
                                Image.asset('assets/images/thumbnail.png'),
                                Text('Dove Soap',style: TextStyle(color: Colors.white,fontSize: 18),),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            width: 450,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Color(0xFF3D4142),
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                            ),
                            child: Row(
                              children: [
                                Image.asset('assets/images/dove.png'),
                                Text('Dove Soap',style: TextStyle(color: Colors.white,fontSize: 18),),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                        color: Color(0xFF292C2D),
                        borderRadius: BorderRadius.all(Radius.circular(10))),
                    width: 500,
                    height: 466,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                'Popular Items',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 25
                                ),
                              ),
                              SizedBox(width: 80,),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            width: 450,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Color(0xFF3D4142),
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                            ),
                            child: Row(
                              children: [
                                Image.asset('assets/images/thumbnail.png'),
                                Text('Dove Soap',style: TextStyle(color: Colors.white,fontSize: 18),),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            width: 450,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Color(0xFF3D4142),
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                            ),
                            child: Row(
                              children: [
                                Image.asset('assets/images/dove.png'),
                                Text('Dove Soap',style: TextStyle(color: Colors.white,fontSize: 18),),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            width: 450,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Color(0xFF3D4142),
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                            ),
                            child: Row(
                              children: [
                                Image.asset('assets/images/thumbnail.png'),
                                Text('Dove Soap',style: TextStyle(color: Colors.white,fontSize: 18),),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            width: 450,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Color(0xFF3D4142),
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                            ),
                            child: Row(
                              children: [
                                Image.asset('assets/images/dove.png'),
                                Text('Dove Soap',style: TextStyle(color: Colors.white,fontSize: 18),),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}