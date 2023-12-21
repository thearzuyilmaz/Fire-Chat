import 'package:fire_chat/screens/chat_screen.dart';
import 'package:fire_chat/widgets/user_image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

final _firebase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  var _isLogin = true;

  final _form = GlobalKey<FormState>();
  var _enteredEmail = '';
  var _enteredPassword = '';
  File? _selectedImage; // import 'dart:io';
  var _isAuthenticating = false;
  var _enteredUserName = '';

  // submitting form by log-in / sign-up
  void _submit() async {
    final isValid = _form.currentState!.validate();

    if (!isValid || _selectedImage == null && !_isLogin) {
      // show error message ...
      return;
    }

    _form.currentState!.save();

    try {
      // circular progress indicator starts
      setState(() {
        _isAuthenticating = true;
      });

      if (_isLogin) {
        // Log in existing user
        UserCredential userCredentials =
            await _firebase.signInWithEmailAndPassword(
                email: _enteredEmail, password: _enteredPassword);
        print("Logged in user: ${userCredentials.user?.email}"); //testing
      } else {
        // Sign up a new user
        UserCredential userCredentials =
            await _firebase.createUserWithEmailAndPassword(
                email: _enteredEmail, password: _enteredPassword);
        print("Signed up user: ${userCredentials.user?.email}"); //testing

        //creating a storage reference
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_images')
            .child('${userCredentials.user!.uid}.jpg');

        await storageRef
            .putFile(_selectedImage!); //uploading the image to Firebase Storage
        final imageUrl = await storageRef
            .getDownloadURL(); //getting the URL from Firebase Storage
        print("Image URL: $imageUrl"); //testing

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredentials.user!.uid)
            .set({
          'username': _enteredUserName,
          'email': _enteredEmail,
          'image_url': imageUrl,
        });
      }
    } on FirebaseAuthException catch (e) {
      // Handle FirebaseAuth Exception
      String errorMessage = '';

      if (e.code == 'weak-password') {
        errorMessage = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'The account already exists for that email.';
      } else if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        errorMessage = 'Invalid email or password.';
      } else {
        errorMessage = 'Error: ${e.message}';
      }

      // Show error message
      _showSnackBar(errorMessage);

      // circular progress indicator stops
      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.onBackground,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.only(
                  top: 30,
                  bottom: 20,
                  left: 20,
                  right: 20,
                ),
                width: 150,
                child: Image.asset('assets/images/chat.png'),
              ),
              Card(
                elevation: 1,
                color: Theme.of(context).colorScheme.secondaryContainer,
                margin: const EdgeInsets.all(30),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Form(
                        key: _form,
                        onChanged: () {},
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            !_isLogin
                                ? UserImagePicker(imagePickFn: (File image) {
                                    _selectedImage = image;
                                  })
                                : const SizedBox(),
                            TextFormField(
                              onSaved: (value) {
                                _enteredEmail = value!;
                              },
                              decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Email Address'),
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              textCapitalization: TextCapitalization.none,
                              validator: (value) {
                                if (value == null ||
                                    value.trim().isEmpty ||
                                    !value.contains('@')) {
                                  return 'Please enter a valid email address.';
                                }
                                return null;
                              },
                            ),
                            if (!_isLogin)
                              const SizedBox(
                                height: 15,
                              ),
                            if (!_isLogin)
                              TextFormField(
                                onSaved: (value) {
                                  _enteredUserName = value!;
                                },
                                enableSuggestions: false,
                                decoration: const InputDecoration(
                                  labelText: 'Username',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null ||
                                      value.trim().isEmpty ||
                                      value.trim().length < 3) {
                                    return 'Please enter a valid password.';
                                  }
                                  return null;
                                },
                              ),
                            const SizedBox(
                              height: 15,
                            ),
                            TextFormField(
                              onSaved: (value) {
                                _enteredPassword = value!;
                              },
                              decoration: const InputDecoration(
                                labelText: 'Password',
                                border: OutlineInputBorder(),
                              ),
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.trim().length < 6) {
                                  return 'Please must be at least 6 characters long.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(
                              height: 12,
                            ),
                            if (_isAuthenticating)
                              const CircularProgressIndicator(),
                            if (!_isAuthenticating)
                              ElevatedButton(
                                onPressed: _submit,
                                style: ElevatedButton.styleFrom(
                                  foregroundColor:
                                      Theme.of(context).colorScheme.onPrimary,
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                ),
                                child: Text(_isLogin ? 'Login' : 'Signup'),
                              ),
                            if (!_isAuthenticating)
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isLogin = !_isLogin;
                                  });
                                },
                                child: Text(_isLogin
                                    ? 'Create an account'
                                    : 'I already have an account'),
                              ),
                          ],
                        )),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
