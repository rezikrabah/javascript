import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:test2/client/commandes.dart';
import 'package:test2/client/historique.dart';
import 'package:test2/client/profile.dart';
import 'package:test2/client/suivi.dart';
import 'package:test2/pages/Login.dart';
import 'package:test2/pages/RoleSelectionScreen.dart';

import '../services/api_service.dart';

void main() => runApp(
    MaterialApp(
        debugShowCheckedModeBanner: false,
        home: clientpage()
    )
);
class clientpage extends StatefulWidget {
  const clientpage({super.key});

  @override
  State<clientpage> createState() => _clientpageState();
}
int _currentScreenIndex =3;
List<Widget> _screens = [
  const Scaffold(),
  const Scaffold(),
  const Scaffold(),
  const Scaffold(),
];

class _clientpageState extends State<clientpage> {
  Widget roleCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 90,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              const  BoxShadow(
                color: Colors.blue,
                blurRadius: 10,
              ),
            ],
          ),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 30, color: Colors.blue),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {



    return Scaffold(
        resizeToAvoidBottomInset: true,

      appBar:
      AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Color(0xFF0C2A34),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const  Text(
              'Bienvenue 👋',
              style: TextStyle(
                color: Color(0xFF4ECDC4),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const   Text(
              'client profile',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          Icon(Icons.water_drop, color: Color(0xFF4ECDC4), size: 28),

          const  SizedBox(width: 10),
          const   CircleAvatar(
            backgroundColor: Color(0xFF1a5a6a),
            radius: 20,
            child: Icon(Icons.person, color: Colors.white, size: 22),
          ),
          const  SizedBox(width: 16),
        ],
      ),



        body: SingleChildScrollView(
          padding:const EdgeInsets.only(top: 30, left: 16, right: 16),
       child:
       Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Container(
            padding:const EdgeInsets.symmetric(horizontal: 13, vertical: 11),

            decoration: BoxDecoration(
              color: Color(0xFF0B3C49),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const  CircleAvatar(
                  radius: 22,
                  backgroundColor: Color(0xFF0C2A34),
                  child: Icon(Icons.person, color: Colors.white, size: 22),
                ),
                const  SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const  Text('rezik rabah',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        )
                    ),
                    const Text('client depuis 2023',
                      style: TextStyle(
                        color: Colors.lightBlue,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
           SizedBox(height:12 ,),
       Row(
            children: [
              roleCard(
                icon: Icons.local_shipping_sharp,
                title: "  12\n commande",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => clientpage(),
                    ),
                  );
                },
              ),
              roleCard(
                icon: Icons.water_drop_rounded,
                title: "1100L",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => commandes(clientId: int.tryParse(ApiService.userId ?? '0') ?? 0,),
                    ),
                  );
                },
              ),
            ],
          ),
           Container(
             height: 250,
             width: 300,
             margin: const EdgeInsetsDirectional.only(top: 40),
             decoration: BoxDecoration(
               color: const Color(0xFF0B3C49),
               borderRadius: BorderRadius.circular(20),

             ),

   child: Column(
     crossAxisAlignment: CrossAxisAlignment.start,
   children: [
   Row(
     mainAxisAlignment: MainAxisAlignment.spaceBetween,
     children: [
       const Text('Dernières commandes',

     style: TextStyle(
       fontSize: 13,
       fontWeight: FontWeight.w600,
       color: Colors.white,

     ),
    ),
       SizedBox(width: 30,),
       TextButton(onPressed: (){
         Navigator.push(

           context,
           MaterialPageRoute(
             builder: (context) => historique(),
           ),
         );
       },
       child:const Text('voir tout ->',
         style: TextStyle(
           fontSize: 13,
           color: Colors.blue,
         ),
       ),
       ),
             ],
   ),
     // --------------------------1ere------------------------------
     Row(
       children: [
         Icon(Icons.local_shipping_sharp, color: Color(0xFF4ECDC4), size: 28),
         SizedBox(width: 10,),

         RichText(
           text:const TextSpan(
             children: [
                  TextSpan(
                 text: '1 citerne x500L',
                 style: TextStyle(
                   color: Colors.white,
                   fontSize: 15,
                   fontWeight: FontWeight.bold,
                 ),
               ),
               TextSpan(
                 text: '\nl25 Décembre 2024',
                 style: TextStyle(
                   color: Color(0xFF4ECDC4),
                   fontSize: 12,
                   fontWeight: FontWeight.w400,
                 ),
               ),
             ],
           ),
         ),  const SizedBox(width: 10,),

         Container(height: 60, width: 1, color: Colors.white24),
         SizedBox(width: 60,),
         Text('Livrée ✓',
           style:const TextStyle(
             color: Colors.green,

           ),
         ),

       ],
     ),

     // ---------------------------2EME-------------------------
     Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         Row(
           children: [
             Icon(Icons.local_shipping_sharp, color: Color(0xFF4ECDC4), size: 28),
             SizedBox(width: 10,),

              RichText(
               text:const TextSpan(
                 children: [
                   TextSpan(
                     text: '1 citerne x400L',
                     style: TextStyle(
                       color: Colors.white,
                       fontSize: 15,
                       fontWeight: FontWeight.bold,
                     ),
                   ),
                   const  TextSpan(
                     text: '\n02 Janvier 2025',
                     style: TextStyle(
                       color: Color(0xFF4ECDC4),
                       fontSize: 12,
                       fontWeight: FontWeight.w400,
                     ),
                   ),
                 ],
               ),
             ),  const SizedBox(width: 10,),

             Container(height: 60, width: 1, color: Colors.white24),
             const    SizedBox(width: 60,),
             const  Text('Livrée ✓',
               style: TextStyle(
                 color: Colors.green,

               ),
             ),

           ],
         )
       ],
     ),
               // ---------------------------3EME-------------------------
           Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
               Row(
               children: [
                 const    Icon(Icons.local_shipping_sharp, color: Color(0xFF4ECDC4), size: 28),
      SizedBox(width: 10,),

      RichText(
        text:const TextSpan(
          children: [
            TextSpan(
              text: '1 citerne x200L',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: '\nle 25 janvier 2026',
              style: TextStyle(
                color: Color(0xFF4ECDC4),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),  const SizedBox(width: 10,),

      Container(height: 60, width: 1, color: Colors.white24),
                 const  SizedBox(width: 50,),
                 const  Text('en cours...',
        style: TextStyle(
          color: Colors.orangeAccent,

        ),
      ),

      ],
    )
    ],
    ),
             ],
           ),

   ),
           const SizedBox(height: 10,width: 30,),
           Padding(padding:const EdgeInsets.only(left: 0),
           child: Container(
             height: 56,

             alignment: Alignment.center,
             decoration: BoxDecoration(
               color:const Color(0xFF0B3C49),
               borderRadius: BorderRadius.circular(18),
               boxShadow: [
                 BoxShadow(
                   color: Colors.blue.withOpacity(0.4),
                   blurRadius: 20,
                   offset: Offset(0, 6),
                 ),
               ],
             ),
             child: TextButton(
               onPressed:(){
                 Navigator.push(
                   context,
                   MaterialPageRoute(
                     builder: (context) => commandes(clientId: int.tryParse(ApiService.userId ?? '0') ?? 0,),
                   ),
                 );
               },
               child: const Text(''
                   'passer une commande',
                 style: TextStyle(
                   color: Colors.white,
                   fontWeight: FontWeight.w900,
                   fontSize: 18,
                 ),
               ),
             ),
           ),
           ),


      ],
        ),
        ),




      floatingActionButton: FloatingActionButton(
          mini: true,
          backgroundColor: Color(0xFF0B3C49),
          shape: const CircleBorder(),
          child:const Icon(CupertinoIcons.home, color: Colors.white, size:20,),
          onPressed:(){
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => clientpage(),
              ),
            );
          }
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar:BottomAppBar(
        notchMargin: 8,
        height: 90,
        child: Row(
          children: [
            //---------------------SUIVI------------------------------------
           Column(
             mainAxisAlignment: MainAxisAlignment.center,
             mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(  icon:
              const  Icon(CupertinoIcons.map, size: 20,  color:  Color(0xFF0B3C49)

              ),

              onPressed: (){
                Navigator.push(

                  context,
                  MaterialPageRoute(
                    builder: (context) => suivi(),
                  ),
                );
              },

      ),

              const   Text('suivi',
                  style: TextStyle(
                    fontSize: 10,
                      color:  Color(0xFF0B3C49)
                  ),
                ),


          ],
        ),
            const SizedBox(width: 35,),
            //---------------------commandes------------------------------------
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(  icon:const Icon(CupertinoIcons.cube_box_fill,size: 20, color:  Color(0xFF0B3C49)
                ),
                onPressed: (){
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => commandes(clientId: int.tryParse(ApiService.userId ?? '0') ?? 0,),
                    ),
                  );

                },),
                const Text('commandes',
                  style: TextStyle(
                    fontSize: 8,
                    color:  Color(0xFF0B3C49),
                 fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 25,),
            //---------------------historique------------------------------------
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                  icon:const Icon(CupertinoIcons.clock,size: 20, color:  Color(0xFF0B3C49)
                  ),
                onPressed: (){
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => historique(),
                    ),
                  );

                },
                ),
                const  Text('historique',
                  style: TextStyle(
                    fontSize: 8,
                      color:  Color(0xFF0B3C49)
                  ),
                ),
              ],
            ),
            const  SizedBox(width: 22,height: 80,),
            //---------------------profile------------------------------------
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(  icon: Icon(CupertinoIcons.profile_circled,size: 20, color:  Color(0xFF0B3C49)

                ),

                onPressed: (){
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => profile(),
                    ),
                  );
                },
                ),
                const   Text('profile',
                  style: TextStyle(
                    fontSize: 10,
                      color:  Color(0xFF0B3C49)
                  ),
                ),
              ],
            ),

          ],
        ),
      )

    );
  }
}
