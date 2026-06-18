/// Copy for Privacy Policy, Terms of Service, and data-protection summaries (SmartFitao).
class PrivacyLegalContent {
  PrivacyLegalContent._();

  static const String appName = 'SmartFitao';
  static const String lastUpdated = 'June 2026';

  static const String dataProtectionSummary = '''
SmartFitao is built on Google Firebase and secure cloud services. We collect only what is needed to run the marketplace, orders, chat, and tailoring features.

Your account password is never stored in plain text — Firebase Authentication handles sign-in securely. Data moving between your device and our servers uses HTTPS (TLS encryption). Data stored in Firebase (Firestore and Storage) is encrypted at rest on Google Cloud infrastructure.

We use Firebase Security Rules so only you (or parties involved in your order/chat) can access the right records. Payment card details are handled by Stripe — we do not store your full card number on our servers.
''';

  static const List<({String title, String detail})> dataWeCollect = [
    (
      title: 'Account',
      detail:
          'Name, email, role (customer / seller / tailor), shop name and address when you provide them at sign-up or in profile.',
    ),
    (
      title: 'Orders & payments',
      detail:
          'Order items, delivery address, order status, amounts, and payment status. Card payments are processed by Stripe.',
    ),
    (
      title: 'Measurements & try-on',
      detail:
          'Body measurements you enter or capture for custom stitching and size prediction. Camera frames for live measurement are processed for sizing; we do not sell this data.',
    ),
    (
      title: 'Chat messages',
      detail:
          'Messages you send to tailors or sellers through in-app chat, stored so both sides can continue the conversation.',
    ),
    (
      title: 'Seller & tailor uploads',
      detail:
          '3D product files (GLB), preview images, and tailor reel videos you upload to Firebase Storage for the marketplace.',
    ),
    (
      title: 'Device preferences',
      detail:
          'Light settings saved on your device (e.g. login session hints, local profile photo path) using secure local storage.',
    ),
  ];

  static const List<({String title, String detail})> howWeProtect = [
    (
      title: 'Firebase Authentication',
      detail:
          'Industry-standard auth with salted password hashing. Sessions use secure tokens; you can log out anytime.',
    ),
    (
      title: 'Encryption in transit',
      detail:
          'All API calls to Firebase, our backend APIs, and payment services use HTTPS/TLS.',
    ),
    (
      title: 'Encryption at rest',
      detail:
          'Firestore, Firebase Storage, and Google Cloud encrypt stored data at rest by default.',
    ),
    (
      title: 'Access control',
      detail:
          'Firestore and Storage security rules limit reads/writes (e.g. sellers upload only to their folder; chats are scoped to participants).',
    ),
    (
      title: 'Role-based access',
      detail:
          'Customer, seller, and tailor views only show data relevant to that role and your account.',
    ),
    (
      title: 'No sale of personal data',
      detail:
          'We do not sell your personal information to third-party advertisers.',
    ),
  ];

  static const String privacyPolicy = '''
1. Introduction
SmartFitao ("we", "our", "the app") respects your privacy. This policy explains what information we collect, how we use it, and your choices.

2. Information we collect
We collect information you provide directly: account details, profile, delivery address, order history, chat messages, measurements for custom orders, and media you upload as a seller or tailor. We also receive technical data needed to run the app (e.g. Firebase user ID, timestamps).

3. How we use information
• Provide marketplace browsing, 3D product viewing, and checkout
• Process and track orders with sellers and tailors
• Enable chat between customers, sellers, and tailors
• Calculate sizes and custom stitching where you use those features
• Improve reliability and security of the platform

4. Where data is stored
Data is stored in Firebase (Firestore, Authentication, Storage) and on trusted third-party services we use for payments (Stripe) and APIs (e.g. size prediction backend). These providers apply their own security and compliance standards.

5. Sharing
We share information only as needed to fulfil your request: e.g. your name and order details with the seller or tailor handling your order, or payment data with Stripe. We do not sell personal data.

6. Retention
We keep account and order data while your account is active and as needed for legal, dispute, or business records. You may request account deletion by contacting support (subject to outstanding orders).

7. Your rights
You can update your name and address in Profile, log out to end your session, and contact us to ask about access or correction of your data where applicable under local law.

8. Children
SmartFitao is not directed at children under 13. We do not knowingly collect data from children.

9. Changes
We may update this policy. The "Last updated" date on the Profile screen will reflect changes.

10. Contact
For privacy questions: use in-app support or your project contact email for SmartFitao.
''';

  static const String termsOfService = '''
1. Acceptance
By using SmartFitao you agree to these Terms of Service and our Privacy Policy.

2. Accounts
You must provide accurate information when registering. You are responsible for keeping your login credentials secure. One account per role type as designed (customer, seller, or tailor).

3. Marketplace & orders
• Product listings, prices, and availability are set by sellers.
• Custom stitching orders depend on measurements you provide; accuracy affects fit.
• Order status updates are shown in the tracking screen; delivery times may vary.

4. Payments
Payments are processed through Stripe or demo flows as configured. You agree to pay for orders you place. Refunds and disputes follow seller/tailor policies and applicable law.

5. User content
Sellers and tailors may upload 3D models, images, and videos. You must own or have rights to content you upload. We may remove content that violates law or these terms.

6. Acceptable use
Do not misuse chat, upload harmful files, attempt to access others' accounts, or interfere with the service. We may suspend accounts that abuse the platform.

7. Measurements & camera
Live measurement features may use your device camera with your permission. You control when the camera is active.

8. Disclaimer
SmartFitao is provided "as is" for educational / FYP purposes. Fit results and AI-assisted sizing are estimates; final tailoring is agreed with your tailor.

9. Limitation of liability
To the extent permitted by law, SmartFitao and its developers are not liable for indirect damages arising from use of the app.

10. Governing law
These terms are governed by the laws applicable in your jurisdiction unless otherwise required.

11. Contact
Questions about these terms: contact your SmartFitao project administrator.
''';
}
