import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Firebase configuration for web
const firebaseConfig = {
  'apiKey': 'AIzaSyBZ_TgdFflgCB3RX3-TQ60mUujYGyjSk5U',
  'appId': '1:62157388112:web:40046920635063667d5455',
  'messagingSenderId': '62157388112',
  'projectId': 'vishal-49ba6',
  'authDomain': 'vishal-49ba6.firebaseapp.com',
  'databaseURL': 'https://vishal-49ba6-default-rtdb.firebaseio.com',
  'storageBucket': 'vishal-49ba6.firebasestorage.app',
};

void main() async {
  print('🔥 Creating Strame Admin User...\n');
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: firebaseConfig['apiKey']!,
        appId: firebaseConfig['appId']!,
        messagingSenderId: firebaseConfig['messagingSenderId']!,
        projectId: firebaseConfig['projectId']!,
        authDomain: firebaseConfig['authDomain']!,
        databaseURL: firebaseConfig['databaseURL']!,
        storageBucket: firebaseConfig['storageBucket']!,
      ),
    );
    
    print('✅ Firebase initialized successfully');
    
    // Admin credentials
    const adminEmail = 'admin@strame.com';
    const adminPassword = 'Admin@123456';
    const adminName = 'Strame Admin';
    
    print('📧 Creating admin account...');
    print('Email: $adminEmail');
    print('Password: $adminPassword\n');
    
    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;
    
    // Create admin user in Firebase Auth
    UserCredential userCredential;
    try {
      userCredential = await auth.createUserWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );
      print('✅ Admin user created in Firebase Auth');
    } catch (e) {
      if (e.toString().contains('email-already-in-use')) {
        print('⚠️  Admin user already exists in Auth, signing in...');
        userCredential = await auth.signInWithEmailAndPassword(
          email: adminEmail,
          password: adminPassword,
        );
      } else {
        throw e;
      }
    }
    
    final user = userCredential.user!;
    
    // Create admin profile in Firestore
    final adminData = {
      'uid': user.uid,
      'email': adminEmail,
      'name': adminName,
      'role': 'admin',
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    };
    
    await firestore.collection('admins').doc(user.uid).set(adminData);
    print('✅ Admin profile created in Firestore');
    
    // Sign out
    await auth.signOut();
    
    print('\n🎉 Admin user created successfully!');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📧 Email: $adminEmail');
    print('🔑 Password: $adminPassword');
    print('🌐 Admin Panel: http://localhost:8080');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('\n✨ You can now login to the Strame Admin Panel!');
    
  } catch (e) {
    print('❌ Error creating admin user: $e');
    exit(1);
  }
  
  exit(0);
}


