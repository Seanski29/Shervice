import 'package:flutter/material.dart';

class LegalPoliciesButton extends StatelessWidget {
  final Color iconColor;

  const LegalPoliciesButton({
    super.key,
    this.iconColor = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.info_outline, color: iconColor),
      tooltip: 'Legal & Privacy Policies',
      splashRadius: 24,
      onPressed: () => _showLegalDialog(context),
    );
  }

  void _showLegalDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final size = MediaQuery.of(context).size;
        final bool isMobile = size.width < 600;

        return AlertDialog(
          backgroundColor: const Color(0xFFF8FAFC),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: EdgeInsets.zero,
          contentPadding: EdgeInsets.zero,
          
          title: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.gavel, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Legal & Privacy Policies',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          content: SizedBox(
            width: isMobile ? size.width * 0.95 : 600,
            height: size.height * 0.7,
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── DOCUMENT TITLE ──
                    const Text(
                      'SHERVICE: TERMS OF SERVICE, PRIVACY NOTICE, AND USER CONSENT',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Effective Date: July 20, 2026  |  Document Version: 1.0.0',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ─── I. PRIVACY NOTICE ───
                    _buildSectionTitle('I. PRIVACY NOTICE'),
                    _buildText(
                      'SHERVICE is committed to protecting the privacy and security of the personal information entrusted to us by our corporate partners and their employees. This Privacy Notice describes how we collect, process, and safeguard your data in compliance with the Data Privacy Act of 2012 of the Republic of the Philippines.'
                    ),
                    const SizedBox(height: 16),
                    _buildSubsectionTitle('1. Data Collection'),
                    _buildText(
                      'We collect personal information necessary to facilitate efficient fleet and shuttle management. This includes account profile metadata such as full names, corporate email addresses, and employment roles. Operational data collected through the system includes trip requests, passenger headcounts, feedback comments, and driver performance ratings.'
                    ),
                    const SizedBox(height: 16),
                    _buildSubsectionTitle('2. Purpose of Processing'),
                    _buildText(
                      'Personal data is processed exclusively to ensure the secure and efficient dispatching of transport services. Your information allows us to verify user authorization, maintain accurate attendance records, and provide corporate administrators with necessary operational insights. We do not engage in the sale, rent, or trade of personal information.'
                    ),
                    const SizedBox(height: 16),
                    _buildSubsectionTitle('3. Data Protection Architecture'),
                    _buildText(
                      'SHERVICE utilizes a multi-layered security framework. User credentials and authentication tokens are never stored in plain text. We employ isolated database architecture where authentication records are managed within a secure, encrypted vault. Non-sensitive metadata is stored in segregated schemas, ensuring that personal identifiers remain decoupled from operational logs whenever possible.'
                    ),
                    const SizedBox(height: 24),

                    // ─── II. TERMS & CONDITIONS ───
                    _buildSectionTitle('II. TERMS & CONDITIONS'),
                    _buildText(
                      'By accessing the SHERVICE platform, you acknowledge and agree to the following terms, which constitute a binding agreement between you and the system administrators.'
                    ),
                    const SizedBox(height: 16),
                    _buildSubsectionTitle('1. System Access and Authorization'),
                    _buildText(
                      'SHERVICE is a closed-system platform. Access is strictly limited to authorized personnel affiliated with our partnered corporate entities. Unauthorized attempts to gain access to the system, or attempts to view data belonging to an organization other than your own, constitute a violation of system security and the terms of this agreement.'
                    ),
                    const SizedBox(height: 16),
                    _buildSubsectionTitle('2. User Responsibilities'),
                    _buildText(
                      'Users are bound by the following obligations based on their system designation:\n\n'
                      'System Administrators: Responsible for maintaining the integrity of the platform, overseeing data lifecycle management, and ensuring that all system activities comply with corporate security standards.\n\n'
                      'Officers-in-Charge: Accountable for the accuracy of trip requests, passenger headcounts, and driver evaluations. All inputs must reflect real-time operational reality.\n\n'
                      'Drivers: Must provide status updates solely when it is safe to do so. The operation of a motor vehicle while interacting with the mobile application is strictly forbidden. Any information provided by drivers regarding vehicle condition or passenger status must be factual.'
                    ),
                    const SizedBox(height: 16),
                    _buildSubsectionTitle('3. Intellectual Property'),
                    _buildText(
                      'All proprietary technology, including the system architecture, application design, codebase, and associated branding elements, remains the exclusive property of SHERVICE. Users are prohibited from reverse engineering, modifying, or distributing any part of the system without explicit written authorization.'
                    ),
                    const SizedBox(height: 16),
                    _buildSubsectionTitle('4. Limitation of Liability'),
                    _buildText(
                      'SHERVICE is provided as an operational support tool. While we strive for maximum uptime and data accuracy, we shall not be held liable for losses resulting from network interruptions, device hardware failures, or delays in transportation caused by external factors. The responsibility for the physical safety of shuttle operations remains with the drivers and the transport providers.'
                    ),
                    const SizedBox(height: 24),

                    // ─── III. USER CONSENT ───
                    _buildSectionTitle('III. USER CONSENT'),
                    _buildText(
                      'By clicking the "I Understand & Agree" button or by continuing to use the SHERVICE platform, you hereby provide your explicit and informed consent to the following:'
                    ),
                    const SizedBox(height: 16),
                    _buildSubsectionTitle('Authorization for Processing'),
                    _buildText(
                      'I authorize SHERVICE to collect, process, and store the personal data I submit to the system, including but not limited to my name, email address, and operational performance logs, as defined in the Privacy Notice.'
                    ),
                    const SizedBox(height: 16),
                    _buildSubsectionTitle('Compliance with Policy'),
                    _buildText(
                      'I acknowledge that I have read and understood the Terms & Conditions of the platform. I agree to abide by all stated usage guidelines and recognize that violations may lead to the suspension or permanent revocation of my access privileges.'
                    ),
                    const SizedBox(height: 16),
                    _buildSubsectionTitle('Data Integrity'),
                    _buildText(
                      'I confirm that all information I submit to the platform is accurate, truthful, and provided in good faith. I understand that submitting fraudulent evaluations or incorrect passenger data undermines the operational efficiency of the fleet.'
                    ),
                    const SizedBox(height: 16),
                    _buildSubsectionTitle('Privacy Rights'),
                    _buildText(
                      'I recognize my rights under the Data Privacy Act of 2012, including the right to access, correct, or request the deletion of my personal information, subject to the retention requirements necessitated by my employer\'s corporate policies and contractual obligations.'
                    ),
                    const SizedBox(height: 16),
                    _buildSubsectionTitle('Security Vigilance'),
                    _buildText(
                      'I accept responsibility for the security of my account credentials and agree to notify the system administration immediately upon discovery of any suspicious account activity.'
                    ),
                    const SizedBox(height: 24),

                    // ─── CONSENT STATEMENT BOX ───
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        border: Border.all(color: Colors.blue.shade200),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.verified_user, color: Colors.blue, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'User Consent Statement',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Text(
                            'By continuing to use the SHERVICE platform, I hereby explicitly consent to the collection, processing, and storage of my data as outlined in this Privacy Notice, and I agree to strictly abide by the Terms & Conditions of the platform.',
                            style: TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
          
          actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          actions: [
            SizedBox(
              width: isMobile ? double.infinity : null,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'I Understand ', 
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0F172A),
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildSubsectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E293B),
        ),
      ),
    );
  }

  Widget _buildText(String content) {
    return Text(
      content,
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey.shade700,
        height: 1.6,
      ),
    );
  }
}