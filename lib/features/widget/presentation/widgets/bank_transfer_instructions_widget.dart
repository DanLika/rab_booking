import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/snackbar_helper.dart';

/// Widget that displays bank transfer payment instructions
/// Shows account details and payment deadline
class BankTransferInstructionsWidget extends StatelessWidget {
  final double depositAmount;
  final String bookingReference;
  final String? propertyName;

  const BankTransferInstructionsWidget({
    super.key,
    required this.depositAmount,
    required this.bookingReference,
    this.propertyName,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.account_balance,
                    size: 32,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Uplatite avans bankovnim transferom',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Iznos: €${depositAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 32),

            // Important notice
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber.shade900),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Imate 3 radna dana da izvršite uplatu. Rezervacija će biti potvrđena nakon što owner primi sredstva.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Bank account details
            _buildSectionTitle('Podaci za uplatu'),
            const SizedBox(height: 12),

            _buildCopyableField(
              context,
              label: 'Naziv banke',
              value: 'Banka Intesa Sanpaolo',
              icon: Icons.account_balance,
            ),

            _buildCopyableField(
              context,
              label: 'IBAN',
              value: 'HR1234567890123456789',
              icon: Icons.credit_card,
            ),

            _buildCopyableField(
              context,
              label: 'BIC/SWIFT',
              value: 'BINTHR2X',
              icon: Icons.swap_horiz,
            ),

            _buildCopyableField(
              context,
              label: 'Primatelj',
              value: 'RAB BOOKING d.o.o.',
              icon: Icons.business,
            ),

            const Divider(height: 32),

            // Payment description
            _buildSectionTitle('Opis plaćanja (obavezno)'),
            const SizedBox(height: 12),

            _buildCopyableField(
              context,
              label: 'Referenca',
              value: bookingReference,
              icon: Icons.tag,
              highlight: true,
            ),

            if (propertyName != null) ...[
              const SizedBox(height: 8),
              Text(
                'Opis: Avans za $propertyName - Ref: $bookingReference',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Amount breakdown
            _buildSectionTitle('Detalji uplate'),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Avans (20%)'),
                      Text(
                        '€${depositAmount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Preostali iznos (80%)'),
                      Text(
                        '€${(depositAmount * 4).toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Important notes
            _buildSectionTitle('Važne napomene'),
            const SizedBox(height: 12),

            _buildBulletPoint(
              '• Molimo unesite tačnu referencu u opis plaćanja kako bi uplata bila automatski procesirana',
            ),
            _buildBulletPoint(
              '• Uplate se obično procesiraju u roku od 1-2 radna dana',
            ),
            _buildBulletPoint(
              '• Preostali iznos (80%) plaća se direktno vlasniku pri dolasku',
            ),
            _buildBulletPoint(
              '• Nakon što owner potvrdi prijem novca, dobit ćete email potvrdu',
            ),
            _buildBulletPoint(
              '• Ako novac ne stigne u roku od 3 radna dana, rezervacija će biti automatski otkazana',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildCopyableField(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    bool highlight = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight ? Colors.blue.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlight ? Colors.blue.shade200 : Colors.grey.shade300,
          width: highlight ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
                    color: highlight ? Colors.blue.shade900 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 20),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              SnackBarHelper.showSuccess(
                context: context,
                message: '$label kopiran: $value',
                isDarkMode: false,
                duration: const Duration(seconds: 2),
              );
            },
            tooltip: 'Kopiraj',
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade700,
          height: 1.5,
        ),
      ),
    );
  }
}

/// Widget for showing bank transfer summary in the payment selection screen
class BankTransferOptionCard extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final double depositAmount;

  const BankTransferOptionCard({
    super.key,
    required this.isSelected,
    required this.onTap,
    required this.depositAmount,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.account_balance,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bankovna uplata',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Uplatite 20% avans',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: Colors.blue.shade700),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Avans (20%):',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '€${depositAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Na licu mjesta (80%):',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        '€${(depositAmount * 4).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '⏱️ Rok za uplatu: 3 radna dana',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
