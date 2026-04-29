import 'package:flutter/material.dart';

import '../User 3D Market Place/auth-login-sign/login_seller.dart';
import '../User 3D Market Place/auth-login-sign/login_tailor.dart';
import '../User 3D Market Place/auth-login-sign/login_user.dart';

// Order Types
enum OrderType { standard, custom }
enum OrderStatus {
  pending,
  withSeller,
  shippedToTailor,
  tailorDelivered,
  tailorStitched,
  tailorToShip,
  shipped,
  delivered,
  paymentReceived
}

// Notification Model
class NotificationModel {
  String orderId;
  String type;
  bool isRead;
  DateTime timestamp;

  NotificationModel({
    required this.orderId,
    required this.type,
    this.isRead = false,
    required this.timestamp,
  });
}

// Order Model
class Order {
  String id;
  String customerName;
  String customerId;
  String productName;
  String sellerName;
  String sellerAddress;
  String tailorName;
  String tailorAddress;
  String deliveryAddress;
  /// Per-unit product price after discount (seller line); line total = totalAmount * quantity.
  double totalAmount;
  /// Full-order tailoring total (PKR). Zero for standard orders; hidden from seller UIs.
  double tailorStitchingTotal;
  String currency;
  OrderType type;
  OrderStatus status;
  int quantity;
  Map<String, dynamic> details;
  DateTime? sellerReceivedDate;
  DateTime? tailorReceivedDate;
  DateTime? stitchedDate;
  DateTime? shippedDate;
  DateTime? deliveredDate;
  DateTime? paymentReceivedDate;
  /// Set when seller taps Confirm Payment (product line).
  DateTime? sellerPaymentReleasedAt;
  /// Set when tailor taps Confirm Payment (stitching line); custom orders only.
  DateTime? tailorPaymentReleasedAt;
  DateTime? createdAt;
  List<NotificationModel> notifications;

  /// Old orders: status is paymentReceived but split timestamps were never written.
  bool get hasLegacyCombinedPaymentConfirm =>
      status == OrderStatus.paymentReceived &&
      sellerPaymentReleasedAt == null &&
      tailorPaymentReleasedAt == null;

  Order({
    required this.id,
    required this.customerName,
    required this.customerId,
    required this.productName,
    this.sellerName = 'SmartFitao Store',
    this.sellerAddress = '123 Seller Street, Lahore',
    this.tailorName = 'Tailor Ahmed',
    this.tailorAddress = '456 Tailor Road, Lahore',
    this.deliveryAddress = '45 E1, near Lacas School, Johar Town, Lahore',
    required this.totalAmount,
    this.tailorStitchingTotal = 0,
    this.currency = 'PKR',
    required this.type,
    required this.status,
    this.quantity = 1,
    required this.details,
    this.sellerReceivedDate,
    this.tailorReceivedDate,
    this.stitchedDate,
    this.shippedDate,
    this.deliveredDate,
    this.paymentReceivedDate,
    this.sellerPaymentReleasedAt,
    this.tailorPaymentReleasedAt,
    this.createdAt,
    List<NotificationModel>? notifications,
  }) : notifications = notifications ?? [];

  String get statusText {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.withSeller:
        return 'With Seller';
      case OrderStatus.shippedToTailor:
        return 'Shipped to Tailor';
      case OrderStatus.tailorDelivered:
        return 'Tailor Delivered';
      case OrderStatus.tailorStitched:
        return 'Tailor Stitched';
      case OrderStatus.tailorToShip:
        return 'Tailor to Ship';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.paymentReceived:
        return 'Payment Received';
    }
  }

  Color get statusColor {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.withSeller:
        return Colors.blue;
      case OrderStatus.shippedToTailor:
        return Colors.amber;
      case OrderStatus.tailorDelivered:
        return Colors.purple;
      case OrderStatus.tailorStitched:
        return Colors.indigo;
      case OrderStatus.tailorToShip:
        return Colors.teal;
      case OrderStatus.shipped:
        return Colors.cyan;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.paymentReceived:
        return Colors.deepOrange;
    }
  }

  void addNotification(String type) {
    notifications.add(NotificationModel(
      orderId: id,
      type: type,
      timestamp: DateTime.now(),
    ));
  }

  List<NotificationModel> getUnreadNotifications() {
    return notifications.where((n) => !n.isRead).toList();
  }

  void markNotificationsAsRead(String type) {
    for (var notification in notifications) {
      if (notification.type == type && !notification.isRead) {
        notification.isRead = true;
      }
    }
  }
  
  void markAllNotificationsAsRead() {
    for (var notification in notifications) {
      notification.isRead = true;
    }
  }
}

// Mock Data Store
class OrderStore {
  static List<Order> orders = [];

  static void initialize() {
    // No hardcoded orders.
    // Orders should come from Firestore streams (see `firebase_pages.dart`).
    orders = [];
  }

  static Order? getOrderById(String orderId) {
    try {
      return orders.firstWhere((order) => order.id == orderId);
    } catch (e) {
      return null;
    }
  }

  static void updateOrderStatus(String orderId, OrderStatus newStatus) {
    final order = getOrderById(orderId);
    if (order != null) {
      order.status = newStatus;
      
      switch (newStatus) {
        case OrderStatus.withSeller:
          order.sellerReceivedDate = DateTime.now();
          order.addNotification('new_order');
          break;
        case OrderStatus.shippedToTailor:
          order.shippedDate = DateTime.now();
          order.addNotification('shipped_to_tailor');
          break;
        case OrderStatus.tailorDelivered:
          order.tailorReceivedDate = DateTime.now();
          order.addNotification('tailor_delivered');
          break;
        case OrderStatus.tailorStitched:
          order.stitchedDate = DateTime.now();
          order.addNotification('tailor_stitched');
          break;
        case OrderStatus.tailorToShip:
          order.addNotification('tailor_to_ship');
          break;
        case OrderStatus.shipped:
          order.shippedDate = DateTime.now();
          order.addNotification('shipped');
          break;
        case OrderStatus.delivered:
          order.deliveredDate = DateTime.now();
          order.addNotification('delivered');
          break;
        case OrderStatus.paymentReceived:
          order.paymentReceivedDate = DateTime.now();
          order.addNotification('payment_received');
          break;
        default:
          break;
      }
    }
  }
}

// Role Selection Screen
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple.shade50, Colors.white],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.cut, size: 60, color: Colors.deepPurple),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Smart Fitao',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Sign in or register — choose your role',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                _buildRoleButton(
                  context: context,
                  icon: Icons.person,
                  title: 'Login as User',
                  subtitle: 'Browse products & track orders',
                  color: Colors.green,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoginUserScreen()),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildRoleButton(
                  context: context,
                  icon: Icons.store,
                  title: 'Login as Seller',
                  subtitle: 'Manage orders & ship to tailor',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoginSellerScreen()),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildRoleButton(
                  context: context,
                  icon: Icons.cut,
                  title: 'Login as Tailor',
                  subtitle: 'Stitch orders & update status',
                  color: Colors.purple,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoginTailorScreen()),
                    );
                  },
                ),
              ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 30, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: color),
          ],
        ),
      ),
    );
  }
}

// User Login Screen
class LoginUserScreen extends StatefulWidget {
  const LoginUserScreen({super.key});

  @override
  State<LoginUserScreen> createState() => _LoginUserScreenState();
}

class _LoginUserScreenState extends State<LoginUserScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool obscurePassword = true;
  bool isLoading = false;

  void _handleLogin() {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() => isLoading = true);

    Future.delayed(const Duration(seconds: 1), () {
      setState(() => isLoading = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const UserProductPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                "Login as User",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              _buildTextField(
                hintText: "Enter your email",
                controller: emailController,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                hintText: "Enter your password",
                controller: passwordController,
                isPassword: true,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ForgetPasswordScreen(role: 'user')),
                      );
                    },
                    child: const Text(
                      "Forget Password?",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 120, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.green)
                    : const Text("Login", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? ", style: TextStyle(color: Colors.white70, fontSize: 14)),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterUserScreen()),
                      );
                    },
                    child: const Text(
                      "Register now",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hintText,
    required TextEditingController controller,
    bool isPassword = false,
  }) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      height: 55,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(2, 2))
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? obscurePassword : false,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscurePassword ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      obscurePassword = !obscurePassword;
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }
}

// User Register Screen
class RegisterUserScreen extends StatefulWidget {
  const RegisterUserScreen({super.key});

  @override
  State<RegisterUserScreen> createState() => _RegisterUserScreenState();
}

class _RegisterUserScreenState extends State<RegisterUserScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool isLoading = false;

  void _handleRegister() {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    setState(() => isLoading = true);

    Future.delayed(const Duration(seconds: 1), () {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registration successful! Please login.")),
      );
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Text(
                "Register as User",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              _buildTextField(
                hintText: "Full Name",
                controller: nameController,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                hintText: "Email",
                controller: emailController,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                hintText: "Password",
                controller: passwordController,
                isPassword: true,
                isConfirm: false,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                hintText: "Confirm Password",
                controller: confirmPasswordController,
                isPassword: true,
                isConfirm: true,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: isLoading ? null : _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 120, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.green)
                    : const Text("Register", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hintText,
    required TextEditingController controller,
    bool isPassword = false,
    bool isConfirm = false,
  }) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      height: 55,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(2, 2))
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword 
            ? (isConfirm ? obscureConfirmPassword : obscurePassword)
            : false,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    (isConfirm ? obscureConfirmPassword : obscurePassword)
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      if (isConfirm) {
                        obscureConfirmPassword = !obscureConfirmPassword;
                      } else {
                        obscurePassword = !obscurePassword;
                      }
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }
}

// Seller Login Screen
class LoginSellerScreen extends StatefulWidget {
  const LoginSellerScreen({super.key});

  @override
  State<LoginSellerScreen> createState() => _LoginSellerScreenState();
}

class _LoginSellerScreenState extends State<LoginSellerScreen> {
  final TextEditingController shopNameController = TextEditingController();
  final TextEditingController ownerNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool obscurePassword = true;
  bool isLoading = false;

  void _handleLogin() {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final shopName = shopNameController.text.trim();
    final ownerName = ownerNameController.text.trim();

    if (email.isEmpty || password.isEmpty || shopName.isEmpty || ownerName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() => isLoading = true);

    Future.delayed(const Duration(seconds: 1), () {
      setState(() => isLoading = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SellerDashboard()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Login as Seller",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              _buildTextField(
                hintText: "Enter Shop Name",
                controller: shopNameController,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                hintText: "Enter Owner Name",
                controller: ownerNameController,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                hintText: "Enter your email",
                controller: emailController,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                hintText: "Enter your password",
                controller: passwordController,
                isPassword: true,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ForgetPasswordScreen(role: 'seller')),
                      );
                    },
                    child: const Text(
                      "Forget Password?",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(horizontal: 120, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.orange)
                    : const Text("Login", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? ", style: TextStyle(color: Colors.white70, fontSize: 14)),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterSellerScreen()),
                      );
                    },
                    child: const Text(
                      "Register now",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hintText,
    required TextEditingController controller,
    bool isPassword = false,
  }) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      height: 55,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(2, 2))
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? obscurePassword : false,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscurePassword ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      obscurePassword = !obscurePassword;
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }
}

// Seller Register Screen
class RegisterSellerScreen extends StatefulWidget {
  const RegisterSellerScreen({super.key});

  @override
  State<RegisterSellerScreen> createState() => _RegisterSellerScreenState();
}

class _RegisterSellerScreenState extends State<RegisterSellerScreen> {
  final TextEditingController shopNameController = TextEditingController();
  final TextEditingController ownerNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool isLoading = false;

  void _handleRegister() {
    final shopName = shopNameController.text.trim();
    final ownerName = ownerNameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (shopName.isEmpty || ownerName.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    setState(() => isLoading = true);

    Future.delayed(const Duration(seconds: 1), () {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registration successful! Please login.")),
      );
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Text(
                "Register as Seller",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              _buildTextField(
                hintText: "Shop Name",
                controller: shopNameController,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                hintText: "Owner Name",
                controller: ownerNameController,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                hintText: "Email",
                controller: emailController,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                hintText: "Password",
                controller: passwordController,
                isPassword: true,
                isConfirm: false,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                hintText: "Confirm Password",
                controller: confirmPasswordController,
                isPassword: true,
                isConfirm: true,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: isLoading ? null : _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(horizontal: 120, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.orange)
                    : const Text("Register", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hintText,
    required TextEditingController controller,
    bool isPassword = false,
    bool isConfirm = false,
  }) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      height: 55,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(2, 2))
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword 
            ? (isConfirm ? obscureConfirmPassword : obscurePassword)
            : false,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    (isConfirm ? obscureConfirmPassword : obscurePassword)
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      if (isConfirm) {
                        obscureConfirmPassword = !obscureConfirmPassword;
                      } else {
                        obscurePassword = !obscurePassword;
                      }
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }
}

// Tailor Login Screen
class LoginTailorScreen extends StatefulWidget {
  const LoginTailorScreen({super.key});

  @override
  State<LoginTailorScreen> createState() => _LoginTailorScreenState();
}

class _LoginTailorScreenState extends State<LoginTailorScreen> {
  final TextEditingController shopNameController = TextEditingController();
  final TextEditingController ownerNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool obscurePassword = true;
  bool isLoading = false;

  void _handleLogin() {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final shopName = shopNameController.text.trim();
    final ownerName = ownerNameController.text.trim();

    if (email.isEmpty || password.isEmpty || shopName.isEmpty || ownerName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() => isLoading = true);

    Future.delayed(const Duration(seconds: 1), () {
      setState(() => isLoading = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TailorDashboard()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Login as Tailor",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              _buildTextField(
                hintText: "Enter Shop Name",
                controller: shopNameController,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                hintText: "Enter Owner Name",
                controller: ownerNameController,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                hintText: "Enter your email",
                controller: emailController,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                hintText: "Enter your password",
                controller: passwordController,
                isPassword: true,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ForgetPasswordScreen(role: 'tailor')),
                      );
                    },
                    child: const Text(
                      "Forget Password?",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.purple,
                  padding: const EdgeInsets.symmetric(horizontal: 120, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.purple)
                    : const Text("Login", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? ", style: TextStyle(color: Colors.white70, fontSize: 14)),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterTailorScreen()),
                      );
                    },
                    child: const Text(
                      "Register now",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hintText,
    required TextEditingController controller,
    bool isPassword = false,
  }) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      height: 55,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(2, 2))
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? obscurePassword : false,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscurePassword ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      obscurePassword = !obscurePassword;
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }
}

// Tailor Register Screen
class RegisterTailorScreen extends StatefulWidget {
  const RegisterTailorScreen({super.key});

  @override
  State<RegisterTailorScreen> createState() => _RegisterTailorScreenState();
}

class _RegisterTailorScreenState extends State<RegisterTailorScreen> {
  final TextEditingController shopNameController = TextEditingController();
  final TextEditingController ownerNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool isLoading = false;

  void _handleRegister() {
    final shopName = shopNameController.text.trim();
    final ownerName = ownerNameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (shopName.isEmpty || ownerName.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    setState(() => isLoading = true);

    Future.delayed(const Duration(seconds: 1), () {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registration successful! Please login.")),
      );
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Text(
                "Register as Tailor",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              _buildTextField(
                hintText: "Shop Name",
                controller: shopNameController,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                hintText: "Owner Name",
                controller: ownerNameController,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                hintText: "Email",
                controller: emailController,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                hintText: "Password",
                controller: passwordController,
                isPassword: true,
                isConfirm: false,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                hintText: "Confirm Password",
                controller: confirmPasswordController,
                isPassword: true,
                isConfirm: true,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: isLoading ? null : _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.purple,
                  padding: const EdgeInsets.symmetric(horizontal: 120, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.purple)
                    : const Text("Register", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hintText,
    required TextEditingController controller,
    bool isPassword = false,
    bool isConfirm = false,
  }) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      height: 55,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(2, 2))
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword 
            ? (isConfirm ? obscureConfirmPassword : obscurePassword)
            : false,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    (isConfirm ? obscureConfirmPassword : obscurePassword)
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      if (isConfirm) {
                        obscureConfirmPassword = !obscureConfirmPassword;
                      } else {
                        obscurePassword = !obscurePassword;
                      }
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }
}

// Forget Password Screen
class ForgetPasswordScreen extends StatefulWidget {
  final String role;
  const ForgetPasswordScreen({super.key, required this.role});

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  bool showOTP = false;
  bool isLoading = false;
  String? generatedOTP;

  void _sendOTP() {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter email")),
      );
      return;
    }

    setState(() {
      isLoading = true;
      generatedOTP = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          showOTP = true;
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("OTP sent to $email: $generatedOTP")),
        );
      }
    });
  }

  void _verifyOTP() {
    if (otpController.text.trim() == generatedOTP) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("OTP verified successfully!")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid OTP")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Color getColor() {
      switch (widget.role) {
        case 'user':
          return Colors.green;
        case 'seller':
          return Colors.orange;
        case 'tailor':
          return Colors.purple;
        default:
          return Colors.blue;
      }
    }

    return Scaffold(
      backgroundColor: getColor(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Reset Password",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "Enter your email",
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (showOTP) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TextField(
                    controller: otpController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "Enter OTP",
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _verifyOTP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: getColor(),
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  ),
                  child: const Text("Verify OTP"),
                ),
              ] else ...[
                ElevatedButton(
                  onPressed: isLoading ? null : _sendOTP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: getColor(),
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text("Send OTP"),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Reusable Order Details Widget
class OrderDetailsWidget extends StatelessWidget {
  final Order order;
  final VoidCallback? onClose;
  final String role; // 'user', 'seller', 'tailor'

  const OrderDetailsWidget({
    super.key,
    required this.order,
    this.onClose,
    required this.role,
  });

  bool _showPaymentReleaseSection() {
    if (role != 'user' && role != 'seller' && role != 'tailor') return false;
    if (order.status != OrderStatus.delivered && order.status != OrderStatus.paymentReceived) {
      return false;
    }
    return true;
  }

  static String _releasedAtLabel(DateTime? d) {
    if (d == null) return '';
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return ' • ${d.year}-$m-$day';
  }

  List<Widget> _paymentReleaseRows(double productLineTotal, double stitchingTotal) {
    final legacy = order.hasLegacyCombinedPaymentConfirm;
    final lines = <Widget>[];

    if (role == 'user') {
      if (legacy) {
        lines.add(Text(
          'Product payment released: PKR ${productLineTotal.toStringAsFixed(0)}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ));
        if (order.type == OrderType.custom && stitchingTotal > 0) {
          lines.add(Text(
            'Tailoring payment released: PKR ${stitchingTotal.toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ));
        }
        return lines;
      }
      if (order.sellerPaymentReleasedAt != null) {
        lines.add(Text(
          'Product payment released: PKR ${productLineTotal.toStringAsFixed(0)}${_releasedAtLabel(order.sellerPaymentReleasedAt)}',
          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.green),
        ));
      } else {
        lines.add(Text(
          'Product payment: pending seller confirmation (PKR ${productLineTotal.toStringAsFixed(0)})',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade800),
        ));
      }
      if (order.type == OrderType.custom && stitchingTotal > 0) {
        lines.add(const SizedBox(height: 6));
        if (order.tailorPaymentReleasedAt != null) {
          lines.add(Text(
            'Tailoring payment released: PKR ${stitchingTotal.toStringAsFixed(0)}${_releasedAtLabel(order.tailorPaymentReleasedAt)}',
            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.green),
          ));
        } else {
          lines.add(Text(
            'Tailoring payment: pending tailor confirmation (PKR ${stitchingTotal.toStringAsFixed(0)})',
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade800),
          ));
        }
      }
      return lines;
    }

    if (role == 'seller') {
      if (legacy) {
        lines.add(Text(
          'Product payment released: PKR ${productLineTotal.toStringAsFixed(0)}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ));
      } else if (order.sellerPaymentReleasedAt != null) {
        lines.add(Text(
          'You confirmed product payment release: PKR ${productLineTotal.toStringAsFixed(0)}${_releasedAtLabel(order.sellerPaymentReleasedAt)}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ));
      } else {
        lines.add(Text(
          'Product payment: not confirmed yet (PKR ${productLineTotal.toStringAsFixed(0)})',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade800),
        ));
      }
      return lines;
    }

    if (order.type == OrderType.custom && stitchingTotal > 0) {
      if (legacy) {
        lines.add(Text(
          'Tailoring payment released: PKR ${stitchingTotal.toStringAsFixed(0)}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ));
      } else if (order.tailorPaymentReleasedAt != null) {
        lines.add(Text(
          'You confirmed tailoring payment release: PKR ${stitchingTotal.toStringAsFixed(0)}${_releasedAtLabel(order.tailorPaymentReleasedAt)}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ));
      } else {
        lines.add(Text(
          'Tailoring payment: not confirmed yet (PKR ${stitchingTotal.toStringAsFixed(0)})',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade800),
        ));
      }
    } else {
      lines.add(
        const Text('No separate tailoring fee on this order.', style: TextStyle(fontSize: 13)),
      );
    }
    return lines;
  }

  @override
  Widget build(BuildContext context) {
    final productLineTotal = order.totalAmount * order.quantity;
    final stitchingTotal = order.tailorStitchingTotal;
    final grandTotal = productLineTotal + stitchingTotal;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Order Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: order.statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.id}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: order.statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    order.statusText,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Basic Information
          _buildSection('Basic Information', [
            _buildInfoRow('Product:', order.productName),
            _buildInfoRow('Type:', order.type == OrderType.standard ? 'Standard' : 'Custom'),
            _buildInfoRow('Quantity:', order.quantity.toString()),
            if (role == 'seller') ...[
              _buildInfoRow('Product total (×${order.quantity}):', 'PKR ${productLineTotal.toStringAsFixed(0)}'),
            ] else if (role == 'tailor') ...[
              if (order.type == OrderType.custom && stitchingTotal > 0)
                _buildInfoRow('Tailoring total:', 'PKR ${stitchingTotal.toStringAsFixed(0)}'),
              if (order.type == OrderType.standard || stitchingTotal <= 0)
                _buildInfoRow('Product total (×${order.quantity}):', 'PKR ${productLineTotal.toStringAsFixed(0)}'),
            ] else ...[
              _buildInfoRow(
                'Product total (×${order.quantity}):',
                'PKR ${productLineTotal.toStringAsFixed(0)}',
              ),
              if (order.type == OrderType.custom && stitchingTotal > 0) ...[
                _buildInfoRow('Tailoring:', 'PKR ${stitchingTotal.toStringAsFixed(0)}'),
                _buildInfoRow('Grand total:', 'PKR ${grandTotal.toStringAsFixed(0)}'),
              ],
            ],
          ]),
          
          const SizedBox(height: 12),
          
          // Customer Information
          _buildSection('Customer Information', [
            _buildInfoRow('Name:', order.customerName),
            _buildInfoRow('ID:', order.customerId),
            _buildInfoRow('Delivery Address:', order.deliveryAddress),
          ]),
          
          const SizedBox(height: 12),
          
          // Seller Information
          _buildSection('Seller Information', [
            _buildInfoRow('Shop:', order.sellerName),
            _buildInfoRow('Address:', order.sellerAddress),
          ]),
          
          if (order.type == OrderType.custom) ...[
            const SizedBox(height: 12),
            // Tailor Information
            _buildSection('Tailor Information', [
              _buildInfoRow('Shop:', order.tailorName),
              _buildInfoRow('Address:', order.tailorAddress),
            ]),
          ],
          
          const SizedBox(height: 12),
          
          // Size/Measurement Details
          if (order.type == OrderType.standard)
            _buildSection('Size Details', [
              _buildInfoRow('Kurta Size:', order.details['kurtaSize'] ?? 'L/40'),
              _buildInfoRow('Pyjama Size:', order.details['pyjamaSize'] ?? 'L/40'),
              _buildInfoRow('Pyjama Length:', order.details['pyjamaLength']?.toString() ?? '42'),
              _buildInfoRow('Sleeve Length:', order.details['sleeveLength']?.toString() ?? '25'),
              _buildInfoRow('Front Length:', order.details['frontLength']?.toString() ?? '42'),
              _buildInfoRow('Hip:', order.details['hip']?.toString() ?? '46'),
              _buildInfoRow('Chest:', order.details['chest']?.toString() ?? '45'),
              _buildInfoRow('Shoulder:', order.details['shoulder']?.toString() ?? '18'),
              _buildInfoRow('Waist:', order.details['waist']?.toString() ?? '40'),
            ])
          else
            _buildSection('Measurement Details', 
              _buildMeasurements(order.details['clothSizeChart'] ?? {})
            ),
          
          if (_showPaymentReleaseSection())
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.payment, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            order.status == OrderStatus.paymentReceived
                                ? 'All required payments recorded'
                                : 'Payment releases (after delivery)',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._paymentReleaseRows(productLineTotal, stitchingTotal),
                  ],
                ),
              ),
            ),
          
          const SizedBox(height: 16),
          
          // Tracking Widget
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: CircularTracking(
              order: order,
              onBoxTap: null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Text(
              value,
              style: color != null ? TextStyle(color: color) : null,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMeasurements(Map<String, dynamic> measurements) {
    return measurements.entries.map((entry) {
      return _buildInfoRow('${entry.key}:', entry.value.toString());
    }).toList();
  }
}

// Reusable Order Card Widget
class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;
  final VoidCallback onMoreDetails;
  final String role;

  const OrderCard({
    super.key,
    required this.order,
    required this.onTap,
    required this.onMoreDetails,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final hasNotification = order.getUnreadNotifications().isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: order.type == OrderType.standard 
                              ? Colors.blue.withOpacity(0.1)
                              : Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          order.type == OrderType.standard ? Icons.checkroom : Icons.fit_screen,
                          color: order.type == OrderType.standard ? Colors.blue : Colors.purple,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order #${order.id}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              order.productName,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: order.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    order.statusText,
                    style: TextStyle(
                      color: order.statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Quick Info
            Row(
              children: [
                _buildQuickInfo(Icons.person, order.customerName),
                const SizedBox(width: 12),
                _buildQuickInfo(Icons.shopping_bag, 'Qty: ${order.quantity}'),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Tracking Widget
            CircularTracking(
              order: order,
              onBoxTap: hasNotification ? onTap : null,
            ),
            
            const SizedBox(height: 12),
            
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (hasNotification)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'New Update!',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                Row(
                  children: [
                    TextButton(
                      onPressed: onMoreDetails,
                      child: Text(
                        'more details',
                        style: TextStyle(
                          color: role == 'user' 
                              ? Colors.green 
                              : role == 'seller' 
                                  ? Colors.orange 
                                  : Colors.purple,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    if (hasNotification)
                      IconButton(
                        onPressed: onTap,
                        icon: const Icon(Icons.notifications_active, color: Colors.red),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }
}

// Reusable Track Orders Page
class TrackOrdersPage extends StatefulWidget {
  final String role;
  final Color themeColor;
  final List<Order> Function() getOrders;
  final List<Widget>? customAppBarActions; // Changed to List<Widget>?

  const TrackOrdersPage({
    super.key,
    required this.role,
    required this.themeColor,
    required this.getOrders,
    this.customAppBarActions, // Now accepts List<Widget>?
  });

  @override
  State<TrackOrdersPage> createState() => _TrackOrdersPageState();
}

class _TrackOrdersPageState extends State<TrackOrdersPage> {
  void _showOrderDetails(Order order) {
    order.markAllNotificationsAsRead();
    setState(() {});

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order #${order.id} Details'),
        content: OrderDetailsWidget(
          order: order,
          role: widget.role,
        ),
        actions: [
          if (order.status == OrderStatus.tailorToShip || 
              order.status == OrderStatus.shipped)
            if (widget.role == 'user')
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      OrderStore.updateOrderStatus(order.id, OrderStatus.delivered);
                      Navigator.pop(context);
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Order marked as delivered!')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Delivered'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Delivery not confirmed.')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Not Delivered'),
                  ),
                ],
              ),
          if (widget.role == 'seller')
            _buildSellerActions(order),
          if (widget.role == 'tailor')
            _buildTailorActions(order),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerActions(Order order) {
    return Column(
      children: [
        if (order.type == OrderType.custom && order.status == OrderStatus.withSeller)
          ElevatedButton(
            onPressed: () {
              OrderStore.updateOrderStatus(order.id, OrderStatus.shippedToTailor);
              Navigator.pop(context);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Order shipped to tailor!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Ship to Tailor'),
          ),
        if (order.type == OrderType.standard && order.status == OrderStatus.withSeller)
          ElevatedButton(
            onPressed: () {
              OrderStore.updateOrderStatus(order.id, OrderStatus.shipped);
              Navigator.pop(context);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Order shipped to customer!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Ship to Customer'),
          ),
        if (order.status == OrderStatus.delivered)
          ElevatedButton(
            onPressed: () {
              OrderStore.updateOrderStatus(order.id, OrderStatus.paymentReceived);
              Navigator.pop(context);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Payment confirmed!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Confirm Payment'),
          ),
      ],
    );
  }

  Widget _buildTailorActions(Order order) {
    return Column(
      children: [
        if (order.status == OrderStatus.shippedToTailor)
          ElevatedButton(
            onPressed: () {
              OrderStore.updateOrderStatus(order.id, OrderStatus.tailorDelivered);
              Navigator.pop(context);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Order marked as delivered to tailor!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
            ),
            child: const Text('Tailor Delivered'),
          ),
        if (order.status == OrderStatus.tailorDelivered)
          ElevatedButton(
            onPressed: () {
              OrderStore.updateOrderStatus(order.id, OrderStatus.tailorStitched);
              Navigator.pop(context);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Order marked as stitched!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
            ),
            child: const Text('Tailor Stitched'),
          ),
        if (order.status == OrderStatus.tailorStitched)
          ElevatedButton(
            onPressed: () {
              OrderStore.updateOrderStatus(order.id, OrderStatus.tailorToShip);
              Navigator.pop(context);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Order ready for shipping!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
            ),
            child: const Text('Tailor to Ship'),
          ),
        if (order.status == OrderStatus.delivered)
          ElevatedButton(
            onPressed: () {
              OrderStore.updateOrderStatus(order.id, OrderStatus.paymentReceived);
              Navigator.pop(context);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Payment confirmed!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Confirm Payment'),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final orders = widget.getOrders();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Orders'),
        backgroundColor: widget.themeColor,
        foregroundColor: Colors.white,
        actions: widget.customAppBarActions, // Now properly typed as List<Widget>?
      ),
      body: orders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No orders yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return OrderCard(
                  order: order,
                  onTap: () => _showOrderDetails(order),
                  onMoreDetails: () => _showOrderDetails(order),
                  role: widget.role,
                );
              },
            ),
    );
  }
}

// Circular Tracking Widget
class CircularTracking extends StatelessWidget {
  final Order order;
  final VoidCallback? onBoxTap;

  const CircularTracking({
    super.key,
    required this.order,
    this.onBoxTap,
  });

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> steps;
    
    if (order.type == OrderType.standard) {
      steps = [
        {'label': 'To Ship', 'status': order.status.index >= 1, 'type': 'to_ship'},
        {'label': 'Seller\nShipped', 'status': order.status.index >= 6, 'type': 'shipped'},
        {'label': 'Delivered', 'status': order.status.index >= 7, 'type': 'delivered', 'clickable': true},
        {'label': 'Payment\nReceived', 'status': order.status.index >= 8, 'type': 'payment_received'},
      ];
    } else {
      steps = [
        {'label': 'Seller to\nTailor', 'status': order.status.index >= 2, 'type': 'seller_to_tailor'},
        {'label': 'Tailor\nDelivered', 'status': order.status.index >= 3, 'type': 'tailor_delivered'},
        {'label': 'Tailor\nStitched', 'status': order.status.index >= 4, 'type': 'tailor_stitched'},
        {'label': 'Tailor to\nShip', 'status': order.status.index >= 5, 'type': 'tailor_to_ship'},
        {'label': 'Delivered', 'status': order.status.index >= 7, 'type': 'delivered', 'clickable': true},
        {'label': 'Payment\nReceived', 'status': order.status.index >= 8, 'type': 'payment_received'},
      ];
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            return Container(
              width: 30,
              height: 2,
              color: steps[(index ~/ 2)]['status'] && steps[(index ~/ 2) + 1]['status']
                  ? Colors.green
                  : Colors.grey.shade300,
            );
          } else {
            final stepIndex = index ~/ 2;
            final isCompleted = steps[stepIndex]['status'] as bool;
            final isClickable = steps[stepIndex]['clickable'] == true;
            final hasNotification = order.getUnreadNotifications()
                .any((n) => n.type == steps[stepIndex]['type']);

            return GestureDetector(
              onTap: isClickable && !isCompleted ? onBoxTap : null,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted ? Colors.green : Colors.white,
                      border: Border.all(
                        color: isCompleted 
                            ? Colors.green 
                            : isClickable 
                                ? Colors.blue 
                                : Colors.grey.shade300,
                        width: isClickable && !isCompleted ? 3 : 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        (stepIndex + 1).toString(),
                        style: TextStyle(
                          color: isCompleted ? Colors.white : Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  if (hasNotification)
                    Positioned(
                      top: -5,
                      right: -5,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Text(
                          '1',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: -20,
                    left: 0,
                    right: 0,
                    child: Text(
                      steps[stepIndex]['label']!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        height: 1.1,
                        color: isCompleted
                            ? Colors.green.shade700
                            : (isClickable ? Colors.blue : Colors.grey.shade700),
                        fontWeight: isClickable ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        }),
      ),
    );
  }
}

// User Product Page
class UserProductPage extends StatelessWidget {
  const UserProductPage({super.key});

  void _placeOrder(BuildContext context, OrderType type) {
    final newOrder = Order(
      id: 'ORD${(OrderStore.orders.length + 1).toString().padLeft(3, '0')}',
      customerName: 'New User',
      customerId: 'USER${OrderStore.orders.length + 1}',
      productName: type == OrderType.standard ? 'Classic Kurta' : 'Signature Kurta',
      totalAmount: type == OrderType.standard ? 2999 : 4850,
      tailorStitchingTotal: type == OrderType.custom ? 1200 : 0,
      sellerPaymentReleasedAt: null,
      tailorPaymentReleasedAt: null,
      type: type,
      status: OrderStatus.withSeller,
      quantity: 1,
      details: type == OrderType.standard
          ? {
              'size': 'L/40',
              'color': 'Blue',
              'quantity': 1,
              'kurtaSize': 'L/40',
              'pyjamaSize': 'L/40',
              'pyjamaLength': '42',
              'sleeveLength': '25',
              'frontLength': '42',
              'hip': '46',
              'chest': '45',
              'shoulder': '18',
              'waist': '40',
            }
          : {
              'clothSizeChart': {
                'Neck': '16',
                'Shoulder': '18',
                'Chest': '45',
                'Waist': '40',
                'Hip': '46',
                'Arm Length': '25',
                'Bicep': '14',
                'Forearm': '12',
                'Wrist': '8',
                'Thigh': '24',
                'Calf': '16',
                'Inside Leg': '32',
              },
              'kurtaSize': 'L/40',
              'pyjamaSize': 'L/40',
              'pyjamaLength': '42',
              'sleeveLength': '25',
              'frontLength': '42',
              'paymentMethod': 'Credit Card',
            },
    );
    
    OrderStore.orders.add(newOrder);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Order placed successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserTrackPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProductCard(
            context,
            'Standard Kurta',
            'Ready-made kurta with standard sizes',
            2999,
            Icons.checkroom,
            () => _placeOrder(context, OrderType.standard),
          ),
          const SizedBox(height: 16),
          _buildProductCard(
            context,
            'Custom Kurta',
            'Get kurta made with your exact measurements',
            4850,
            Icons.fit_screen,
            () => _placeOrder(context, OrderType.custom),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    String name,
    String description,
    double price,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.green),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(description),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Price: PKR $price', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 45),
              ),
              child: const Text('Place Order'),
            ),
          ],
        ),
      ),
    );
  }
}

// User Track Page
class UserTrackPage extends StatelessWidget {
  const UserTrackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return TrackOrdersPage(
      role: 'user',
      themeColor: Colors.green,
      getOrders: () => OrderStore.orders,
      customAppBarActions: [
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
            );
          },
        ),
      ],
    );
  }
}

// Seller Dashboard
class SellerDashboard extends StatelessWidget {
  const SellerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return TrackOrdersPage(
      role: 'seller',
      themeColor: Colors.orange,
      getOrders: () => OrderStore.orders,
      customAppBarActions: [
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
            );
          },
        ),
      ],
    );
  }
}

// Tailor Dashboard
class TailorDashboard extends StatelessWidget {
  const TailorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return TrackOrdersPage(
      role: 'tailor',
      themeColor: Colors.purple,
      getOrders: () => OrderStore.orders.where((o) => o.type == OrderType.custom).toList(),
      customAppBarActions: [
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
            );
          },
        ),
      ],
    );
  }
}