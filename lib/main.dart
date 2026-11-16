
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Connect Firestore and Functions to the local emulators.
  FirebaseFirestore.instance.useFirestoreEmulator('10.0.2.2', 8080);

  FirebaseFunctions.instanceFor(region: 'us-central1')
      .useFunctionsEmulator('10.0.2.2', 5001);

  runApp(const CloudQuestApp());
}

class CloudQuestApp extends StatelessWidget {
  const CloudQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cloud Quest',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData) {
            return const HomeScreen();
          }

          return const LoginScreen();
        },
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isRegistering = false;
  bool isLoading = false;
  String errorMessage = '';

  Future<void> submit() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        errorMessage = 'Please enter your email and password.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      if (isRegistering) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = e.message ?? 'Authentication failed.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          errorMessage = 'Something went wrong. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Quest'),
        backgroundColor: Colors.deepPurple.shade100,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud, size: 80, color: Colors.deepPurple),
              const SizedBox(height: 16),
              Text(
                isRegistering ? 'Create an Account' : 'Welcome Back!',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              if (errorMessage.isNotEmpty)
                Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : submit,
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : Text(isRegistering ? 'Register' : 'Sign In'),
                ),
              ),
              TextButton(
                onPressed: isLoading
                    ? null
                    : () {
                        setState(() {
                          isRegistering = !isRegistering;
                          errorMessage = '';
                        });
                      },
                child: Text(
                  isRegistering
                      ? 'Already have an account? Sign In'
                      : 'New user? Create an Account',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isCompleting = false;
  String rewardMessage = '';

  Future<void> completeQuest() async {
    setState(() {
      isCompleting = true;
      rewardMessage = '';
    });

    try {
      final callable = FirebaseFunctions.instanceFor(
        region: 'us-central1',
      ).httpsCallable('completeDailyQuest');

      final result = await callable.call(<String, dynamic>{});
      final data = Map<String, dynamic>.from(result.data as Map);

      if (!mounted) return;

      setState(() {
        rewardMessage = data['message']?.toString() ??
            'Quest request completed.';
      });
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;

      setState(() {
        rewardMessage = 'Error: ${e.message ?? e.code}';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        rewardMessage = 'Unable to complete quest: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          isCompleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Quest'),
        backgroundColor: Colors.deepPurple.shade100,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${user?.email ?? "Quest Player"}!',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Today's Challenge",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('challenges')
                  .doc('today')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text(
                    'Unable to load the challenge. Check Firebase settings.',
                    style: TextStyle(color: Colors.red),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final data = snapshot.data!.data();

                if (data == null) {
                  return const Text('No daily challenge available.');
                }

                final title = data['title'] ?? 'Daily Challenge';
                final description = data['description'] ?? '';
                final points = data['points'] ?? 0;

                return Card(
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title.toString(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(description.toString()),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(
                              Icons.stars,
                              color: Colors.deepPurple,
                            ),
                            const SizedBox(width: 8),
                            Text('$points points'),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                isCompleting ? null : completeQuest,
                            child: isCompleting
                                ? const CircularProgressIndicator()
                                : const Text('Complete Quest'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            if (rewardMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                rewardMessage,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(height: 24),
            const Text(
              'My Rewards',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (user != null)
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text(
                      'Unable to load rewards.',
                      style: TextStyle(color: Colors.red),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }

                  final data = snapshot.data!.data() ?? {};
                  final totalPoints = data['totalPoints'] ?? 0;
                  final badges = List<String>.from(
                    data['badges'] ?? [],
                  );

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Points: $totalPoints',
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Badges: ${badges.isEmpty ? "None yet" : badges.join(", ")}',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
