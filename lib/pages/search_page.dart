import 'package:chatapp/main.dart';
import 'package:chatapp/models/chatroommodel.dart';
import 'package:chatapp/models/usermodel.dart';
import 'package:chatapp/pages/chatroom_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  const SearchPage(
      {super.key, required this.userModel, required this.firebaseUser});

  final UserModel userModel;
  final User firebaseUser;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController searchController = TextEditingController();

  Future<ChatRoomModel?> getChatRoomModel(UserModel targetUser) async {
    ChatRoomModel? chatRoom;

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection("chatrooms")
        .where("participants.${widget.userModel.uid}", isEqualTo: true)
        .where("participants.${targetUser.uid}", isEqualTo: true)
        .get();

    if (snapshot.docs.length > 0) {
      //  fetch the existing chat room model
      var docData = snapshot.docs[0].data();
      ChatRoomModel existingChatroom =
          ChatRoomModel.fromMap(docData as Map<String, dynamic>);

      chatRoom = existingChatroom;
    } else {
      // create a new chat room model
      ChatRoomModel newChatRoom = ChatRoomModel(
          chatroomid: uuid.v1(),
          lastMessage: "",
          participants: {
            widget.userModel.uid.toString(): true,
            targetUser.uid.toString(): true
          });

      await FirebaseFirestore.instance
          .collection("chatrooms")
          .doc(newChatRoom.chatroomid)
          .set(newChatRoom.toMap());

      chatRoom = newChatRoom;
    }

    return chatRoom;
  }

  late UserModel searchedUser;
  Future<UserModel> searchEmailAddress() async {
    DocumentSnapshot docSnap = await FirebaseFirestore.instance
        .collection("users")
        .doc(searchController.text.trim())
        .get();

    if (docSnap != null) {
      searchedUser = UserModel.fromMap(docSnap as Map<String, dynamic>);
    }
    return searchedUser;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Search"),
      ),
      body: SafeArea(
          child: Container(
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: const InputDecoration(labelText: 'Email Address'),
            ),
            const SizedBox(
              height: 20,
            ),
            CupertinoButton(
              onPressed: () {
                setState(() {});
              },
              color: Theme.of(context).colorScheme.secondary,
              child: const Text("Search"),
            ),
            const SizedBox(
              height: 20,
            ),
            StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection("users")
                    .where("email", isEqualTo: searchController.text)
                    .where("email", isNotEqualTo: widget.userModel.email)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.active) {
                    if (snapshot.hasData) {
                      QuerySnapshot dataSnapshot =
                          snapshot.data as QuerySnapshot;

                      if (dataSnapshot.docs.length > 0) {
                        Map<String, dynamic> userMap =
                            dataSnapshot.docs[0].data() as Map<String, dynamic>;

                        UserModel searchedUser = UserModel.fromMap(userMap);

                        return ListTile(
                          onTap: () async {
                            ChatRoomModel? chatroomModel =
                                await getChatRoomModel(searchedUser);

                            if (chatroomModel != null) {
                              Navigator.of(context).pop();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => ChatRoomPage(
                                    targetUser: searchedUser,
                                    userModel: widget.userModel,
                                    firebaseUser: widget.firebaseUser,
                                    chatRoom: chatroomModel,
                                  ),
                                ),
                              );
                            }
                          },
                          leading: CircleAvatar(
                            backgroundImage:
                                NetworkImage(searchedUser.profilepic!),
                            backgroundColor: Colors.grey[500],
                          ),
                          title: Text(searchedUser.email.toString()),
                          subtitle: Text(searchedUser.fullname.toString()),
                          trailing: const Icon(Icons.keyboard_arrow_right),
                        );
                      } else {
                        return const Text("No result found");
                      }
                    } else if (snapshot.hasError) {
                      return const Text("An error occured");
                    } else {
                      return const Text("No result found");
                    }
                  } else {
                    return const CircularProgressIndicator();
                  }
                }),
          ],
        ),
      )),
    );
  }
}
