import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(AuthAndDatabaseExample());
}

class AuthAndDatabaseExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auth & Database Example',
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _errorMessage = '';

  Future<void> _login() async {
    String email = _emailController.text;
    String password = _passwordController.text;
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('Logged in user: ${userCredential.user}');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TodoListPage()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              _errorMessage,
              style: TextStyle(color: Colors.red),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Password'),
              ),
            ),
            ElevatedButton(
              onPressed: _login,
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}

class TodoListPage extends StatefulWidget {
  @override
  _TodoListPageState createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  final DatabaseReference _databaseReference =
  FirebaseDatabase.instance.reference().child('todos');

  List<String> _todos = [];
  String _newTodo = '';

  void _fetchTodos() {
    _databaseReference.onValue.listen((event) {
      Map<dynamic, dynamic>? snapshotValue = event.snapshot.value as Map?;
      if (snapshotValue == null) return;
      setState(() {
        _todos = snapshotValue.values.toList().cast<String>();
      });
    });
  }

  // void _addTodo() async {
  //   String todo = _newTodo.trim();
  //   if (todo.isNotEmpty) {
  //     String? userId = FirebaseAuth.instance.currentUser?.uid;
  //     if (userId != null) {
  //       await FirebaseFirestore.instance
  //           .collection('todos')
  //           .doc(userId)
  //           .collection('userTodos')
  //           .add({'todo': todo});
  //       setState(() {
  //         _newTodo = '';
  //       });
  //     }
  //   }
  // }
  // 버전1, 우선구현

  // FirebaseAuth auth = FirebaseAuth.instance;
  // FirebaseUser user = await auth.currentUser();
  // if (user != null) {
  // String email = user.email;
  // print('사용자 이메일: $email');
  // }유저의 이메일을 가져오는법.

  void _addTodo() async {
    String todo = _newTodo.trim();
    if (todo.isNotEmpty) {
      String? userEmail = FirebaseAuth.instance.currentUser?.email;
      if (userEmail != null) {
        Map<String, dynamic> todoData = {
          'todo': todo,
          'timestamp': DateTime.now(), // 현재 시간 추가
        };
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userEmail)
            .collection('userTodos')
            .add(todoData);
        setState(() {
          _newTodo = '';
        });
      }
    }
  }

// 버전2

  // void _addTodo() async {
  //   String todo = _newTodo.trim();
  //   if (todo.isNotEmpty) {
  //     String? userId = FirebaseAuth.instance.currentUser?.uid;
  //     if (userId != null) {
  //       // 해당 유저의 현재 todo 개수를 조회
  //       DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
  //           .collection('todos')
  //           .doc(userId)
  //           .get();
  //       Map<String, dynamic>? userData = userSnapshot.exists
  //           ? userSnapshot.data() as Map<String, dynamic>?
  //           : null;
  //       int currentTodoCount = userData?['count'] ?? 0;
  //
  //       // 새로운 todo 문서를 추가하고 필드 값을 설정
  //       Map<String, dynamic> todoData = {
  //         'todo': todo,
  //         'timestamp': FieldValue.serverTimestamp(),
  //         'count': currentTodoCount + 1, // 현재 개수에 +1을 설정
  //       };
  //       await FirebaseFirestore.instance
  //           .collection('todos')
  //           .doc(userId)
  //           .collection('userTodos')
  //           .doc('${currentTodoCount + 1}') // 문서 이름을 현재 개수 + 1로 설정
  //           .set(todoData);
  //       setState(() {
  //         _newTodo = '';
  //       });
  //     }
  //   }
  // }
  //3번이구연


  void _deleteTodo(String todo) {
    _databaseReference.child(todo).remove();
  }

  @override
  void initState() {
    super.initState();
    _fetchTodos();
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: Text('Todo List')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _newTodo = value;
                });
              },
              decoration: InputDecoration(
                labelText: 'New Todo',
                suffixIcon: IconButton(
                  icon: Icon(Icons.add),
                  onPressed: _addTodo,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _todos.length,
              itemBuilder: (context, index) {
                String todo = _todos[index];
                return ListTile(
                  title: Text(todo),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => _deleteTodo(todo),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: TodoListWidget()
          )
        ],
      ),
    );
  }
}
class TodoListWidget extends StatelessWidget {
  String? userEmail = FirebaseAuth.instance.currentUser?.email;
  void _deleteTodo(DocumentReference docRef) async {
    await docRef.delete();
  }

  Future<void> _showEditTodoDialog(BuildContext context, Todo todo, DocumentReference docRef) async {
    String updatedTodo = todo.todo; // Initialize with current todo text
    TextEditingController _textEditingController =
    TextEditingController(text: updatedTodo); // TextEditingController to handle editing

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Todo'),
          content: TextField(
            controller: _textEditingController,
            onChanged: (value) {
              updatedTodo = value; // Update the updatedTodo value as user types
            },
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Update todo and close the dialog
                await docRef.update({'todo': updatedTodo});
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    if (userEmail == null) {
      // userEmail이 null인 경우에 대한 예외 처리
      return Text('Error: User email is null');
    }
    return StreamBuilder<QuerySnapshot>(
      // Firebase 데이터의 변경을 실시간으로 감지하는 StreamBuilder
        stream: FirebaseFirestore.instance.collection('users').doc(userEmail).collection('userTodos').orderBy('timestamp', descending: true).snapshots(),
         // FirebaseFirestore.instance.collection('users').doc(userEmail!).collection('userTodos').snapshots(),
         // 'userName' 필드에 유저 이름 추가
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          // 에러가 발생한 경우 에러 메시지를 표시
          return Text('Error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          // 데이터 로딩 중인 경우 로딩 스피너를 표시
          return CircularProgressIndicator();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          // 데이터가 없는 경우 '데이터가 없음'을 표시
          return Text('No Data');
        }

        // 데이터가 있는 경우 ListView.builder를 사용하여 리스트 생성
        return ListView.builder(
          itemCount: snapshot.data?.size,
          itemBuilder: (context, index) {
            // Firestore 문서를 Todo 객체로 변환
            var todoDoc = snapshot.data!.docs[index];
            var todo = Todo.fromMap(todoDoc.data() as Map<String, dynamic>);
            DocumentReference docRef = todoDoc.reference; // DocumentReference for current todo item

            return ListTile(
              title: Text(todo.todo),
              subtitle: Text(todo.timestamp.toString()),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () {
                      _showEditTodoDialog(context, todo, docRef); // 수정메소드호출시
                      //수정된 시간도.. 넣어줘야할까 ?
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => _deleteTodo(docRef), // 삭제 메서드 호출
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class Todo {
  final String todo;
  final DateTime timestamp;
  Todo({
    required this.todo,
    required this.timestamp,
  });

  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      todo: map['todo'],
      timestamp: map['timestamp'].toDate()
    );
  }
}