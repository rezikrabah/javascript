import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'Login.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});
  @override
  State<Homepage> createState() => _HomepageState();
}
class _HomepageState extends State<Homepage>  {
  @override

  @override

  Widget build(BuildContext context) {

    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        child: Stack(
          children: <Widget>[
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
            child:   CachedNetworkImage(
              imageUrl:
              'https://images.unsplash.com/photo-1478760329108-5c3ed9d495a0?q=80&w=774&auto=format&fit=crop&ixlib=rb-4.1.0',
              fit: BoxFit.cover,
              placeholder: (_, __) => const SizedBox.shrink(),
              errorWidget: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        Container(
          width: double.infinity,
          alignment: Alignment.topCenter,
          padding: EdgeInsets.only(top: 120),
           child:
           Container(
             decoration: BoxDecoration(
               shape: BoxShape.circle,
               boxShadow: [
                 BoxShadow(
                   color: const Color(0xFF4ECDC4).withOpacity(0.3),
                   blurRadius: 20,
                   spreadRadius: 2,
                 ),
               ],
             ),
             child: const CircleAvatar(
               radius: 38,
               backgroundImage: AssetImage('assets/app.png'),
             ),
           ),
            ),

            Padding(
              padding: const EdgeInsets.only(bottom: 100,left: 50,top: 250,),
              child: Column(
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        const  TextSpan(
                          text: 'WAV',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),

                        const TextSpan(
                          text: 'eau',
                          style: TextStyle(
                            fontSize: 31,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF0EA5E9),
                            letterSpacing: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
      SizedBox(height: 40,),
     const Text(
        'Pure water, delivered.',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: -0.3,
        ),
      ),

      SizedBox(height: 8), // 👈 space after tagline

      Text(
        'Algerias first water delivery app.',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: Colors.white.withOpacity(0.60),
          letterSpacing: 0.4,
        ),
      ),
                ],
              ),
            ),

Container(
  padding:const EdgeInsets.all(9.0),
  child:
  Column(
    mainAxisAlignment: MainAxisAlignment.end,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Center(
          child:  Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
                color:const Color(0xFF2196F3),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                   BoxShadow(
            color: Colors.blue.withOpacity(0.4),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
          ],
        ),

            child:Row(
              children: [
             TextButton.icon(
                 onPressed: () {
                   Navigator.push(
                     context,
                     MaterialPageRoute(
                       builder: (context) => Login(),
                     ),
                   );
                 },
                   label:
                   const   Text('get started',
                     style: TextStyle(
                      color: Colors.white,
                       fontSize: 20,
                       fontWeight: FontWeight.w900,
                     ),
                   ),
                ),
                const  SizedBox(width:100,),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      const    BoxShadow(
                        color: Colors.blue,
                        blurRadius: 50,
                      ),
                    ],
                  ),

                  child: IconButton(  icon:const Icon(CupertinoIcons.arrow_right,color: Colors.white,size: 20,),
                    onPressed: (){
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Login(),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
          ),

      ),
     const SizedBox(height: 80,),

    ],

  ),

)
          ],

        ),

      ),
    );
  }
}


