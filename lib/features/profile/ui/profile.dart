// lib/features/profile/ui/profile.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:online_shop/features/profile/bloc/profile_bloc.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(ProfileInitialEvent());
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listenWhen: (previous, current) => current is ProfileActionState,
        buildWhen: (previous, current) => current is! ProfileActionState,
        listener: (context, state) {
          if (state is ProfilePasswordChangeButtonPressed) {
            _showPasswordResetDialog(context);
          } else if (state is ProfileChangeEmailButtonPressedState) {
            _showEmailResetDialog(context);
          } else if (state is ProfileVerificationSent) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Verification email sent to ${state.newEmail}. Please check your inbox.',
                ),
                backgroundColor: Colors.blue,
                duration: const Duration(seconds: 5),
              ),
            );
          } else if (state is ProfileUpdateSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Email updated successfully!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
          } else if (state is ProfileUpdateFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to update email: ${state.error}'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
            context.read<ProfileBloc>().add(ProfileInitialEvent());
          }
        },
        builder: (context, state) {
          switch (state.runtimeType) {
            case ProfileLoading:
              return const Center(
                child: SpinKitSpinningLines(
                  color: Color(0xFF328E6E),
                  size: 50.0,
                ),
              );
            case ProfileSuccess:
              final user = (state as ProfileSuccess).user;
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView(
                  children: [
                    CircleAvatar(
                      radius: 100,
                      child: ClipOval(
                        child: CachedNetworkImage(
                          imageUrl:
                              'https://robohash.org/${user.email}.png?set=set1',
                          placeholder:
                              (context, url) =>
                                  SpinKitPulse(color: Colors.black),
                          errorWidget:
                              (context, url, error) => const Icon(Icons.error),
                        ),
                      ),
                    ),
                    const Divider(thickness: 1, color: Colors.grey),
                    Row(
                      children: [
                        const Text(
                          'Name:',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(user.name, style: const TextStyle(fontSize: 20)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text(
                          'Email:',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(user.email, style: const TextStyle(fontSize: 20)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF328E6E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 15,
                          horizontal: 30,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      onPressed: () {
                        context.read<ProfileBloc>().add(
                          ChangePasswordButtonPressedEvent(),
                        );
                      },
                      child: const Text('Change Password'),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF328E6E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 15,
                          horizontal: 30,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      onPressed: () {
                        context.read<ProfileBloc>().add(
                          ProfileChangeEmailButtonPressedEvent(),
                        );
                      },
                      child: const Text('Change Email'),
                    ),
                  ],
                ),
              );
            case ProfileFailure:
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      (state as ProfileFailure).error,
                      style: const TextStyle(color: Colors.red, fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF328E6E),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        context.read<ProfileBloc>().add(ProfileInitialEvent());
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            default:
              return Container();
          }
        },
      ),
    );
  }

  void _showPasswordResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Reset Password'),
          content: const Text(
            'If you agree, a password reset email will be sent to your email, and you will be signed out.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF328E6E),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                final currentUser = FirebaseAuth.instance.currentUser;
                if (currentUser != null && currentUser.email != null) {
                  context.read<ProfileBloc>().add(
                    ChangePasswordEvent(email: currentUser.email!),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No user is signed in.')),
                  );
                }
              },
              child: const Text('Agree'),
            ),
          ],
        );
      },
    );
  }

  Future _showEmailResetDialog(BuildContext context) async {
    _emailController.clear();
    _passwordController.clear();
    return showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Change Email'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  hintText: 'Enter New Email',
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  hintText: 'Enter Password',
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF328E6E),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (_emailController.text.isNotEmpty &&
                    _passwordController.text.isNotEmpty) {
                  context.read<ProfileBloc>().add(
                    ProfileChangeEmailEvent(
                      email: _emailController.text.trim(),
                      password: _passwordController.text,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter both email and password.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Agree'),
            ),
          ],
        );
      },
    );
  }
}
