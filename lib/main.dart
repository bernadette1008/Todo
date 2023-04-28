import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart'; // TABLECALENDAR 추가
// import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:test0415/LoginForm/Login.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
//
//   runApp(AuthAndDatabaseExample());
// }
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 날짜와 시간의 형식을 초기화
  await initializeDateFormatting();

  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 앱 실행
  runApp(AuthAndDatabaseExample());
}

class AuthAndDatabaseExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auth & Database Example',
      home: LoginForm(),
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
  
  Future<void> _goSignUpPage() async{
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SignUpPage()),
    );
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
            ElevatedButton(
              onPressed: _goSignUpPage,
              child: Text('Sign up'),
            )
          ],
        ),
      ),
    );
  }
}

//회원가입
class SignUpPage extends StatefulWidget{
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage>{
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _errorMessage = '';

  void signUp() async {
    try{
      UserCredential userCredential = await FirebaseAuth.instance.
      createUserWithEmailAndPassword(
          email: _emailController.text, password: _passwordController.text
      )
          .then((value) {
            if (value.user!.email == null){

            }else{
              Navigator.pop(context);
            }
            return value;
      });
      FirebaseAuth.instance.currentUser?.sendEmailVerification();
    }
    on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'weak-password'){
          _errorMessage = 'the password provided is too weak';
        }else if(e.code == 'email-already-in-use'){
          _errorMessage = 'The account already exists for that email.';
        }
        else{
          _errorMessage = 'error';
        }
      });
    }
    catch (e){
      print('끝');
    }
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: Text("회원가입")),
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
              onPressed: signUp,
              child: Text('sign up'),
            ),
          ],
        )
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
  final TextEditingController _textEditingController = TextEditingController();
  List<String> _todos = [];
  String _newTodo = '';

  CalendarFormat _calendarFormat = CalendarFormat.month;
/*DateTime _selectedDay = DateTime.now();

void _onDaySelected(DateTime day, List events, List holidays) {
setState(() {
_selectedDay = day;
});
}*/

  DateTime selectedDay = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  DateTime focusedDay = DateTime.now();

  void _fetchTodos() {
    _databaseReference.onValue.listen((event) {
      Map<dynamic, dynamic>? snapshotValue = event.snapshot.value as Map?;
      if (snapshotValue == null) return;
      setState(() {
        _todos = snapshotValue.values.toList().cast<String>();
      });
    });
  }
  void _addTodo() async {
    String message = _textEditingController.text;
    String years = '${selectedDay.year}';
    String yearAndmonth = '${selectedDay.year}_${selectedDay.month}';
    String months = '${selectedDay.month}';
    String days = '${selectedDay.day}';


    if (message.isNotEmpty) {
      String? userEmail = FirebaseAuth.instance.currentUser?.email;

      if (userEmail != null) {
        QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userEmail)
            .collection('userTodos')
            .doc(yearAndmonth)
            .collection(days)
            .where('timestamp', isEqualTo: selectedDay)
            .get();

// 새로운 게시물을 추가할 때 사용할 문서 이름 생성
        int count = snapshot.docs.length;
        print('Collection Length: $count');
        String daysTitle = 'todo${selectedDay.day}_${count + 1}'; // 여기서 특징을 추가해줘야할듯.
// 사용자의 할 일 데이터 추가
        Map<String, dynamic> todoData = {
          'todo': message,
          'timestamp': selectedDay, // 현재 시간 추가
          'isComplete' : false,
        };

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userEmail)
            .collection('userTodos')
            .doc(yearAndmonth)
            .collection(days)
// .doc(daysTitle)
            .add(todoData);

// _newTodo와 _textEditingController의 값을 초기화
        setState(() {
          _newTodo = '';
          _textEditingController.clear();
        });
      }
    }
  }

  void _deleteTodo(String todo) {
    _databaseReference.child(todo).remove();
  }
  @override
  void initState() {
    super.initState();
    _fetchTodos();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Todo List')),
      body: Column(
        children: <Widget>[
          _Calender(),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: TextField(
              controller: _textEditingController,
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
              child: TodoListWidget(selectedDay: selectedDay)
          )
        ],
      ),
    );
  }

  Widget _Calender(){
    return TableCalendar(
      locale: 'ko_KR',
      calendarFormat: _calendarFormat,
// onDaySelected: _onDaySelected(DateTime selectedDay, DateTime focusedDay),
      firstDay: DateTime.utc(2021, 10, 16),
      lastDay: DateTime.utc(2030, 3, 14),
      focusedDay: focusedDay,
      onDaySelected: (DateTime selectedDay, DateTime focusedDay) {
// 선택된 날짜의 상태를 갱신합니다.
        setState(() {
          this.selectedDay = selectedDay;
          this.focusedDay = focusedDay;
        });
      },
      selectedDayPredicate: (DateTime day) {
// selectedDay 와 동일한 날짜의 모양을 바꿔줍니다.
        return isSameDay(selectedDay, day);
      },
    );
  }

}
class TodoListWidget extends StatelessWidget {

  String? userEmail = FirebaseAuth.instance.currentUser?.email;

  final DateTime selectedDay;
  final String yearAndmonth;
  final String months;
  final String days;

  TodoListWidget({Key? key, required this.selectedDay})
      : yearAndmonth = '${selectedDay.year}_${selectedDay.month}',
        months = '${selectedDay.month}',
        days = '${selectedDay.day}',
        super(key: key);

// TodoListWidget({Key? key,required this.year, required this.month ,required this.day}) : super(key:key);


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
      stream:
      FirebaseFirestore.
      instance.collection('users')
          .doc(userEmail)
          .collection('userTodos')
          .doc(yearAndmonth)
          .collection(days).
      orderBy('timestamp', descending: true).
      snapshots(),
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
  final Timestamp? timestampChk;

  Todo({
    required this.todo,
    required this.timestamp,
    this.timestampChk,
  });

  // factory Todo.fromMap(Map<String, dynamic> map) {
  //   return Todo(
  //     todo: map['todo'],
  //     timestamp: map['timestamp'].toDate()
  //   );
  // }
  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      todo: map['todo'],
      timestamp: map['timestamp'] != null ? map['timestamp'].toDate() : null,
    );
  }
}