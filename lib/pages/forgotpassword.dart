import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'new password.dart';
void main() => runApp(
    MaterialApp(
        debugShowCheckedModeBanner: false,
        home: forgotpassword(),
    )
);
class forgotpassword extends StatefulWidget {
  const forgotpassword({super.key});

  @override
  State<forgotpassword> createState() => _forgotpasswordState();
}

class _forgotpasswordState extends State<forgotpassword> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFF0B3C49),
      appBar: AppBar( iconTheme: const IconThemeData(color: Color(0xFFFFFFFF),),title: const Text("change password",style: TextStyle(color: Color(0xFFEAFBFF),fontSize: 21),),backgroundColor: const Color(0xFF0B3C49),centerTitle: true,
        actions: [
          IconButton(
            icon: const     Icon(Icons.water_drop, size: 30,color: Color(0xFF1E88E5)),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
          width: double.infinity,
          alignment: Alignment.topCenter,
          padding: EdgeInsets.only(top: 10),
          child:
          CircleAvatar(
            radius: 20,
            backgroundImage: const CachedNetworkImageProvider(
              'https://img.freepik.com/premium-vector/water-vector-logo-design-white-background_1277164-15228.jpg',

            ),

          )
      ),
          const  Text('Reset your password',
            style:const  TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 15,),
          const Text('please enter your mail to receive a link to create a new password',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),

          ),
          const  SizedBox(height: 30,),
          //mail
          TextFormField(
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: ' your email',
              labelStyle: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
              hintText: 'enter your email',
              hintStyle:const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white,

              ),
              prefixIcon: const Icon(Icons.email,color: Colors.white,),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide( color:const Color(0xFFEAFBFF), width: 1.5), // Change color here
              ),
              // Border when focused
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide ( color: Colors.lightBlueAccent, width: 2), // Change color here
              ),
            ),

            style:const TextStyle(
              color: Colors.white,
            ),

            onChanged: (String value) {
            },
            validator: (value){
              return value!. isEmpty ? 'please enter your email':null;

            },
          ),
          const SizedBox(height: 30,),


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
                    builder: (context) => newpassword(),
                  ),
                );
              },
              label: const Text(
                'send',style: TextStyle(color: Colors.white,fontSize: 16,fontWeight: FontWeight.w600),
              ),
            ),

          ),
        ],
      ),

    );
  }
}


