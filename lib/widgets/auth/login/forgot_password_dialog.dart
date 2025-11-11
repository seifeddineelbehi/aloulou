import 'package:flutter/material.dart';
import '../../../presentation/viewmodels/auth_viewmodel.dart';

class ForgotPasswordDialog extends StatelessWidget {
  final AuthViewModel authViewModel;
  final Function(String) onSuccess;

  const ForgotPasswordDialog({
    super.key,
    required this.authViewModel,
    required this.onSuccess,
  });

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();

    return AlertDialog(
      title: const Text('Mot de passe oublié'),
      content: TextField(
        controller: emailController,
        decoration: const InputDecoration(
          labelText: 'Email',
          hintText: 'Entrez votre adresse email',
        ),
        keyboardType: TextInputType.emailAddress,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () async {
            if (emailController.text.isNotEmpty) {
              final success = await authViewModel.resetPassword(emailController.text);
              Navigator.of(context).pop();
              
              if (success) {
                onSuccess('Email de réinitialisation envoyé !');
              }
            }
          },
          child: const Text('Envoyer'),
        ),
      ],
    );
  }
}
