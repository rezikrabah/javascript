import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:test2/pages/Login.dart';
import 'Loginpage.dart';
void main() => runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: newpassword(),
    )
);
class newpassword extends StatefulWidget {
  const newpassword({super.key});

  @override
  State<newpassword> createState() => _newpasswordState();
}

class _newpasswordState extends State<newpassword> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B3C49),
      appBar: AppBar( iconTheme: const IconThemeData(color: Color(0xFFFFFFFF),),title: const Text("new password",style: TextStyle(color: Color(0xFFEAFBFF),fontSize: 21),),backgroundColor: const Color(0xFF0B3C49),centerTitle: true,
        actions: [
          IconButton(
            icon: const     Icon(Icons.water_drop, size: 30,color: Color(0xFF1E88E5)),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
    child: Column(
        children: [
          Container(
              width: double.infinity,
              alignment: Alignment.topCenter,
              padding: EdgeInsets.only(top: 10),
              child:
              const    CircleAvatar(
                radius: 20,
                backgroundImage:  CachedNetworkImageProvider(
                  'https://img.freepik.com/premium-vector/water-vector-logo-design-white-background_1277164-15228.jpg',

                ),

              )
          ),
          const  Text('new password',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 15,),
          const  Text('please enter your new password',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),

          ),
          const   SizedBox(height: 20,),

//-----------------------new password-------------------------------------------
          TextFormField(
            keyboardType: TextInputType.visiblePassword,
            readOnly: false,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),

            decoration: InputDecoration(
              labelText: 'new password',
              labelStyle: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),

              hintText: 'please enter your new password',
              hintStyle: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),

              prefixIcon: const Icon(Icons.password,color: Colors.white,),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide(color: Color(0xFFEAFBFF), width: 1.5),
              ),

              // Border when focused
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide(color: Colors.lightBlueAccent, width: 2), // Change color here
              ),
            ),
            onChanged: (String value) {
            },
            validator: (value){
              return value!. isEmpty ? 'please enter your password':null;
            },
          ),
          const SizedBox(height: 10,),

//------------------confirm new password---------------------------------------

          TextFormField(
            keyboardType: TextInputType.visiblePassword,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              labelText: ' confirm password',
              labelStyle: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
              hintText: 'please  confirm your new password',
              hintStyle: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              prefixIcon:  const Icon(Icons.password,color: Colors.white,),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide(color:const Color(0xFFEAFBFF), width: 1.5), // Change color here
              ),

              // Border when focused
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide(color: Colors.lightBlueAccent, width: 2), // Change color here
              ),
            ),
            onChanged: (String value) {
            },
            validator: (value){
              return value!. isEmpty ? 'please enter your password':null;
            },
          ),
          const   SizedBox(height: 10,),


          Container(
            height: 56,
            alignment: Alignment.center,
            decoration:
            BoxDecoration(color:const Color(0xFF8FCFE3),borderRadius: BorderRadius.circular(28),),
            child:TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Loginpage(),
                  ),
                );
              },
              label: const Text(
                'confirm',style: TextStyle(color: Colors.white,fontSize: 16,fontWeight: FontWeight.w600),
              ),
            ),

          ),
        ],
      ),
    ),
    );
  }
}
