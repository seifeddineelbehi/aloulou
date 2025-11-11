// File: presentation/widgets/ai_provider_selector.dart (mise à jour)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/ai_service_interface.dart';
import '../../core/services/ai_service_manager.dart';

class AIProviderSelector extends StatefulWidget {
  final String userId;
  
  const AIProviderSelector({
    super.key,
    required this.userId,
  });

  @override
  State<AIProviderSelector> createState() => _AIProviderSelectorState();
}

class _AIProviderSelectorState extends State<AIProviderSelector> {
  Map<AIProvider, bool> _availability = {};
  bool _isLoading = true;
  Map<String, dynamic>? _currentSubscription;

  @override
  void initState() {
    super.initState();
    _checkAvailability();
    // _loadSubscription();
  }

  Future<void> _checkAvailability() async {
    final aiManager = context.read<AIServiceManager>();
    final availability = await aiManager.getAvailableProviders();
    
    if (mounted) {
      setState(() {
        _availability = availability;
        _isLoading = false;
      });
    }
  }

  // Future<void> _loadSubscription() async {
  //   final subscription = await PaymentService.instance.getCurrentSubscription(widget.userId);
  //   if (mounted) {
  //     setState(() => _currentSubscription = subscription);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Consumer<AIServiceManager>(
      builder: (context, aiManager, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.smart_toy,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Fournisseur IA',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (_currentSubscription != null)
                      _buildSubscriptionBadge(),
                    if (_isLoading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (!_isLoading) ...[
                  _buildProviderTile(
                    provider: AIProvider.gemini,
                    title: 'Google Gemini',
                    subtitle: 'Gemini 1.5 Flash - Rapide et intelligent',
                    icon: Icons.auto_awesome,
                    currentProvider: aiManager.currentProvider,
                    isAvailable: _availability[AIProvider.gemini] ?? false,
                    requiresSubscription: false,
                    onTap: () => _selectProvider(AIProvider.gemini, aiManager),
                  ),
                  const SizedBox(height: 8),
                  _buildProviderTile(
                    provider: AIProvider.deepSeek,
                    title: 'DeepSeek',
                    subtitle: 'Gratuit - Excellent pour le code et les maths',
                    icon: Icons.code,
                    currentProvider: aiManager.currentProvider,
                    isAvailable: _availability[AIProvider.deepSeek] ?? false,
                    requiresSubscription: false,
                    onTap: () => _selectProvider(AIProvider.deepSeek, aiManager),
                  ),
                  const SizedBox(height: 8),
                  _buildProviderTile(
                    provider: AIProvider.openAI,
                    title: 'ChatGPT',
                    subtitle: 'Premium - Le plus avancé pour conversations complexes',
                    icon: Icons.psychology,
                    currentProvider: aiManager.currentProvider,
                    isAvailable: _availability[AIProvider.openAI] ?? false,
                    requiresSubscription: true,
                    onTap: () => _selectProvider(AIProvider.openAI, aiManager),
                  ),
                  const SizedBox(height: 12),
                  _buildStatusInfo(aiManager),
                ] else ...[
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text('Vérification des services...'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubscriptionBadge() {
    if (_currentSubscription == null) return const SizedBox.shrink();
    
    final planId = _currentSubscription!['plan_id'] as String;
    final isBasic = planId.contains('basic');
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isBasic ? Colors.blue[100] : Colors.purple[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isBasic ? 'BASIC' : 'PREMIUM',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isBasic ? Colors.blue[700] : Colors.purple[700],
        ),
      ),
    );
  }

  Widget _buildProviderTile({
    required AIProvider provider,
    required String title,
    required String subtitle,
    required IconData icon,
    required AIProvider currentProvider,
    required bool isAvailable,
    required bool requiresSubscription,
    required VoidCallback onTap,
  }) {
    final isSelected = provider == currentProvider;
    final hasSubscription = _currentSubscription != null;
    final canUse = !requiresSubscription || hasSubscription;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected 
              ? Theme.of(context).primaryColor 
              : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
        color: isSelected 
            ? Theme.of(context).primaryColor.withOpacity(0.1)
            : null,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: canUse
              ? (isSelected ? Theme.of(context).primaryColor : null)
              : Colors.grey,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: canUse ? null : Colors.grey,
                ),
              ),
            ),
            if (requiresSubscription) ...[
              Icon(
                Icons.star,
                size: 16,
                color: hasSubscription ? Colors.amber : Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                'Premium',
                style: TextStyle(
                  fontSize: 12,
                  color: hasSubscription ? Colors.amber[700] : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                subtitle,
                style: TextStyle(
                  color: canUse ? null : Colors.grey,
                  fontSize: 12,
                ),
              ),
            ),
            _buildStatusBadge(isAvailable, requiresSubscription, hasSubscription),
          ],
        ),
        trailing: isSelected 
            ? Icon(
                Icons.check_circle,
                color: Theme.of(context).primaryColor,
              )
            : (requiresSubscription && !hasSubscription)
                ? const Icon(Icons.lock_outline, color: Colors.grey)
                : null,
        onTap: onTap,
        enabled: canUse,
      ),
    );
  }

  Widget _buildStatusBadge(bool isAvailable, bool requiresSubscription, bool hasSubscription) {
    String text;
    Color color;
    
    if (requiresSubscription && !hasSubscription) {
      text = 'Abonnement requis';
      color = Colors.orange;
    } else if (isAvailable) {
      text = 'Actif';
      color = Colors.green;
    } else {
      text = 'Indisponible';
      color = Colors.red;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusInfo(AIServiceManager aiManager) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, size: 16, color: Colors.blue.shade700),
              const SizedBox(width: 6),
              Text(
                'Informations',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Service actuel: ${aiManager.currentProviderName}\n'
            '• Basculement automatique en cas d\'erreur\n'
            '• Gemini et DeepSeek sont gratuits\n'
            '• ChatGPT nécessite un abonnement premium',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectProvider(AIProvider provider, AIServiceManager aiManager) async {
    // Vérifier si le provider nécessite un abonnement
    if (provider == AIProvider.openAI && _currentSubscription == null) {
      // _showSubscriptionModal(provider);
      return;
    }

    // Sinon, changer directement le provider
    aiManager.switchProvider(provider);
  }

  // void _showSubscriptionModal(AIProvider provider) {
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (context) => SubscriptionModal(
  //       userId: widget.userId,
  //       requestedProvider: provider,
  //       onPaymentComplete: (success) {
  //         if (success) {
  //           _loadSubscription();
  //           // Changer vers le provider demandé après paiement réussi
  //           final aiManager = context.read<AIServiceManager>();
  //           aiManager.switchProvider(provider);
  //         }
  //       },
  //     ),
  //   );
  // }
}
