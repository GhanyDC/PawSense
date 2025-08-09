import 'package:flutter/material.dart';

/// Terms and Conditions Modal
///
/// Modal dialog that displays the terms and conditions and requires user agreement.
/// This widget manages the state of the modal and handles user interactions.
class TermsAndConditionsModal extends StatefulWidget {
  const TermsAndConditionsModal({super.key});

  @override
  State<TermsAndConditionsModal> createState() => _TermsAndConditionsModalState();
}

class _TermsAndConditionsModalState extends State<TermsAndConditionsModal> {
  final ScrollController _scrollController = ScrollController();
  bool _scrolledToBottom = false;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.offset >= _scrollController.position.maxScrollExtent && !_scrollController.position.outOfRange) {
      setState(() => _scrolledToBottom = true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.all(0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 32,
              backgroundColor: Colors.blueAccent.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image(
                  image: AssetImage('assets/img/logo.png'),
                  width: 40,
                  height: 40,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Terms and Conditions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                height: 400,
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.5),
                        children: [
                          const TextSpan(
                            text: 'Welcome to PawSense, an AI-enabled mobile application that uses YOLO-based image processing to assist in the early detection of common pet skin diseases and provide real-time care guidance. '
                                'By downloading, accessing, or using the PawSense application, you agree to comply with and be bound by the following Terms and Conditions. Please read them carefully before using the App.\n\n',
                          ),
                          TextSpan(
                            text: '1. Acceptance of Terms\n',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5),
                          ),
                          const TextSpan(
                            text: 'By accessing or using PawSense, you agree to be legally bound by these Terms. If you do not agree, you must discontinue use of the App immediately.\n\n',
                          ),
                          TextSpan(
                            text: '2. Purpose of the App\n',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5),
                          ),
                          const TextSpan(
                            text: 'PawSense is designed to:\n'
                                '- Provide AI-assisted screening of visible skin conditions in cats and dogs.\n'
                                '- Offer non-prescriptive care guidance and informational resources.\n'
                                '- Facilitate user access to nearby veterinary clinics and related services.\n'
                                'Important: PawSense is not a substitute for professional veterinary diagnosis, advice, or treatment. All health concerns should be confirmed with a licensed veterinarian.\n\n',
                          ),
                          TextSpan(
                            text: '3. User Responsibilities\n',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5),
                          ),
                          const TextSpan(
                            text: 'You agree to:\n'
                                '- Provide accurate and truthful information when registering and using the App.\n'
                                '- Use the App only for lawful purposes and in compliance with applicable laws.\n'
                                '- Avoid misuse of the App, including attempting to reverse engineer, hack, or disrupt services.\n\n',
                          ),
                          TextSpan(
                            text: '4. AI Detection Limitations\n',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5),
                          ),
                          const TextSpan(
                            text: '- The App detects only visible skin conditions and cannot diagnose internal health issues.\n'
                                '- Accuracy depends on image quality, lighting, and the diversity of the AI training dataset.\n'
                                '- Only one condition per image will be identified; multiple conditions may require separate scans.\n\n',
                          ),
                          TextSpan(
                            text: '5. Data Collection and Privacy\n',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5),
                          ),
                          const TextSpan(
                            text: 'PawSense collects certain personal data (e.g., name, email, pet details) and scan history to provide services.\n'
                                'Images submitted are used for analysis and may be stored for model improvement, with anonymization where applicable.\n'
                                'All data handling follows our Privacy Policy. By using the App, you consent to such data processing.\n\n',
                          ),
                          TextSpan(
                            text: '6. Intellectual Property\n',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5),
                          ),
                          const TextSpan(
                            text: 'All content, features, and functionalities of PawSense—including text, graphics, AI models, and software—are owned by the PawSense developers and are protected by copyright, trademark, and other intellectual property laws.\n\n',
                          ),
                          TextSpan(
                            text: '7. Third-Party Services\n',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5),
                          ),
                          const TextSpan(
                            text: 'The App may include integrations with third-party services (e.g., maps for locating clinics, cloud AI services). Your use of such services is subject to their respective terms and conditions.\n\n',
                          ),
                          TextSpan(
                            text: '8. Disclaimers\n',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5),
                          ),
                          const TextSpan(
                            text: 'PawSense is provided “as is” without warranties of any kind, express or implied.\n'
                                'The developers are not liable for any damages, losses, or injuries resulting from reliance on the App’s results or guidance.\n'
                                'Veterinary care decisions should always be made with professional input.\n\n',
                          ),
                          TextSpan(
                            text: '9. Limitation of Liability\n',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5),
                          ),
                          const TextSpan(
                            text: 'To the maximum extent permitted by law, PawSense and its developers will not be liable for:\n'
                                '- Errors or inaccuracies in AI analysis.\n'
                                '- Any loss or damage resulting from reliance on the App’s outputs.\n'
                                '- Service interruptions, bugs, or technical failures.\n\n',
                          ),
                          TextSpan(
                            text: '10. Modifications to Terms\n',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5),
                          ),
                          const TextSpan(
                            text: 'We may update these Terms at any time. Continued use of the App after updates means you accept the revised Terms.\n\n',
                          ),
                          TextSpan(
                            text: '11. Governing Law\n',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5),
                          ),
                          const TextSpan(
                            text: 'These Terms shall be governed by and construed in accordance with the laws of the Republic of the Philippines.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: CheckboxListTile(
                value: _checked,
                onChanged: _scrolledToBottom
                    ? (val) => setState(() => _checked = val ?? false)
                    : null,
                title: const Text(
                  'I have read and agree to the Terms and Conditions',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.1,
                  ),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
                visualDensity: VisualDensity.compact,
              ),
            ),
   
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _checked ? () => Navigator.pop(context, true) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Agree', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
