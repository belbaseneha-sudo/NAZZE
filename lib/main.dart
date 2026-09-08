import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const NazzeApp());
}

/* =========================================================
   DESIGN SYSTEM
========================================================= */

class AppColors {
  static const black = Color(0xFF111111);
  static const white = Color(0xFFFFFFFF);
  static const background = Color(0xFFF7F7F5);
  static const lightGrey = Color(0xFFE8E8E6);
  static const grey = Color(0xFF707070);
}

class AppText {
  static const logo = TextStyle(
    fontFamily: 'serif',
    fontSize: 32,
    fontWeight: FontWeight.w500,
    letterSpacing: 5,
    color: AppColors.black,
  );

  static const h1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w500,
    color: AppColors.black,
  );

  static const h2 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.black,
  );

  static const body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.grey,
    height: 1.45,
  );

  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.black,
  );

  static const button = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
    letterSpacing: 1.1,
  );
}

/* =========================================================
   DATA
========================================================= */

class Product {
  final String id;
  final String name;
  final double price;
  final String image;
  final String category;
  final String description;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
    required this.category,
    required this.description,
  });
}

const List<Product> products = [
  Product(
    id: 'satin-blue',
    name: 'SATIN DRESS',
    price: 89,
    image: 'assets/images/satin_blue.png',
    category: 'DRESSES',
    description: 'Elegant satin dress with a relaxed fit, designed for effortless everyday style.',
  ),
  Product(
    id: 'linen-top',
    name: 'LINEN TOP',
    price: 59,
    image: 'assets/images/linen_top.png',
    category: 'TOPS',
    description: 'Lightweight linen top with a clean silhouette for an easy everyday look.',
  ),
  Product(
    id: 'linen-dress',
    name: 'LINEN DRESS',
    price: 79,
    image: 'assets/images/linen_dress.png',
    category: 'DRESSES',
    description: 'Minimal linen dress with a soft structured shape and comfortable natural finish.',
  ),
  Product(
    id: 'pleated-dress',
    name: 'PLEATED DRESS',
    price: 99,
    image: 'assets/images/pleated_orange.png',
    category: 'DRESSES',
    description: 'Pleated statement dress with a flowing silhouette and refined modern detail.',
  ),
  Product(
    id: 'slip-dress',
    name: 'SLIP DRESS',
    price: 69,
    image: 'assets/images/satin_pink.png',
    category: 'DRESSES',
    description: 'Soft satin slip dress with a simple cut designed for day-to-evening styling.',
  ),
  Product(
    id: 'checked-bottom',
    name: 'CHECKED TROUSER',
    price: 74,
    image: 'assets/images/fashion_blue.png',
    category: 'BOTTOMS',
    description:
        'Tailored checked trouser with a clean fashion-editorial silhouette.',
  ),
  Product(
    id: 'classic-shoe',
    name: 'CLASSIC SHOE',
    price: 82,
    image: 'assets/images/fashion_blue.png',
    category: 'SHOES',
    description:
        'Minimal classic footwear designed to complement the NAZZE collection.',
  ),
];

Product productById(String id) => products.firstWhere((p) => p.id == id);

void showSoftwareKeyboard(FocusNode focusNode) {
  focusNode.requestFocus();

  Future.delayed(const Duration(milliseconds: 120), () {
    if (focusNode.hasFocus) {
      SystemChannels.textInput.invokeMethod<void>('TextInput.show');
    }
  });
}

class CartLine {
  final Product product;
  String size;
  int quantity;

  CartLine({required this.product, required this.size, this.quantity = 1});
}

class OrderRecord {
  final String id;
  final List<CartLine> lines;
  final double total;
  final DateTime placedAt;
  final String status;

  OrderRecord({
    required this.id,
    required this.lines,
    required this.total,
    required this.placedAt,
    this.status = 'CONFIRMED',
  });
}

class NazzeStore extends ChangeNotifier {
  NazzeStore._();

  static final NazzeStore instance = NazzeStore._();

  final Set<String> wishlist = {
    'pleated-dress',
    'satin-blue',
    'linen-dress',
    'slip-dress',
  };

  final List<CartLine> cart = [];
  final List<OrderRecord> orders = [];

  int _nextOrderNumber = 1024;

  bool isWishlisted(Product product) => wishlist.contains(product.id);

  void toggleWishlist(Product product) {
    if (wishlist.contains(product.id)) {
      wishlist.remove(product.id);
    } else {
      wishlist.add(product.id);
    }
    notifyListeners();
  }

  void addToBag(Product product, String size) {
    final index = cart.indexWhere(
      (line) => line.product.id == product.id && line.size == size,
    );

    if (index >= 0) {
      cart[index].quantity++;
    } else {
      cart.add(CartLine(product: product, size: size));
    }

    notifyListeners();
  }

  void changeQuantity(CartLine line, int delta) {
    final next = line.quantity + delta;

    if (next <= 0) {
      cart.remove(line);
    } else {
      line.quantity = next;
    }

    notifyListeners();
  }

  int get cartCount => cart.fold<int>(0, (sum, line) => sum + line.quantity);

  double get subtotal => cart.fold<double>(
    0,
    (sum, line) => sum + (line.product.price * line.quantity),
  );

  OrderRecord? placeCurrentOrder() {
    if (cart.isEmpty) {
      return null;
    }

    final snapshot = cart
        .map(
          (line) => CartLine(
            product: line.product,
            size: line.size,
            quantity: line.quantity,
          ),
        )
        .toList(growable: false);

    final order = OrderRecord(
      id: 'NZ${_nextOrderNumber++}',
      lines: snapshot,
      total: subtotal,
      placedAt: DateTime.now(),
    );

    orders.insert(0, order);
    cart.clear();
    notifyListeners();

    return order;
  }

  void clearCart() {
    cart.clear();
    notifyListeners();
  }
}

/* =========================================================
   APP
========================================================= */

class NazzeApp extends StatelessWidget {
  const NazzeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NAZZE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: false,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: null,
        colorScheme: const ColorScheme.light(
          primary: AppColors.black,
          secondary: AppColors.black,
          surface: AppColors.white,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: AppColors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          hintStyle: TextStyle(fontSize: 14, color: AppColors.grey),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: AppColors.lightGrey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: AppColors.black, width: 1.2),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: AppColors.lightGrey),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

/* =========================================================
   SMOOTH LOCAL IMAGE
========================================================= */

class SmoothAssetImage extends StatelessWidget {
  final String path;
  final BoxFit fit;
  final int? cacheWidth;
  final Alignment alignment;
  final double? width;
  final double? height;

  const SmoothAssetImage(
    this.path, {
    super.key,
    this.fit = BoxFit.cover,
    this.cacheWidth,
    this.alignment = Alignment.center,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      path,
      fit: fit,
      alignment: alignment,
      cacheWidth: cacheWidth,
      width: width,
      height: height,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) {
        return Container(
          color: AppColors.lightGrey,
          alignment: Alignment.center,
          child: const Icon(Icons.image_outlined, color: AppColors.grey),
        );
      },
    );
  }
}

/* =========================================================
   SPLASH
========================================================= */

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (started) {
      return;
    }

    started = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _start();
    });
  }

  Future<void> _start() async {
    // Give the splash its first clean frame before doing image work.
    await Future.delayed(const Duration(milliseconds: 250));

    if (!mounted) {
      return;
    }

    // Warm the local image cache while the splash is already visible.
    for (final product in products) {
      unawaited(precacheImage(AssetImage(product.image), context));
    }

    // The hero image is also used on Home.
    unawaited(
      precacheImage(
        const AssetImage('assets/images/fashion_blue.png'),
        context,
      ),
    );

    // Keep the Figma splash clearly visible.
    await Future.delayed(const Duration(milliseconds: 2950));

    if (!mounted) {
      return;
    }

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const WelcomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('NAZZE', style: AppText.logo),
              SizedBox(height: 8),
              Text(
                'FASHION',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 4,
                  color: AppColors.grey,
                ),
              ),
              SizedBox(height: 38),
              SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* =========================================================
   WELCOME
========================================================= */

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 4),
              const Text('NAZZE', style: AppText.logo),
              const SizedBox(height: 12),
              const Text(
                'FASHION FOR EVERY MOMENT',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: AppColors.black,
                  letterSpacing: .2,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Discover our latest collection.',
                textAlign: TextAlign.center,
                style: AppText.body,
              ),
              const SizedBox(height: 28),
              PrimaryButton(
                text: 'GET STARTED',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignUpScreen()),
                  );
                },
              ),
              const SizedBox(height: 18),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.grey,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                child: const Text(
                  'I ALREADY HAVE AN ACCOUNT',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    letterSpacing: .6,
                    color: AppColors.grey,
                  ),
                ),
              ),
              const Spacer(flex: 5),
            ],
          ),
        ),
      ),
    );
  }
}

/* =========================================================
   AUTH
========================================================= */

class AuthScaffold extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const AuthScaffold({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              28,
              24,
              28,
              MediaQuery.of(context).viewInsets.bottom + 28,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom -
                    52,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(flex: 4),
                    const Center(child: Text('NAZZE', style: AppText.logo)),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    ...children,
                    const Spacer(flex: 5),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NazzeField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final bool obscureText;
  final Widget? suffixIcon;
  final ValueChanged<String>? onSubmitted;

  const NazzeField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hint,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.obscureText = false,
    this.suffixIcon,
    this.onSubmitted,
  });

  void _showKeyboard() {
    showSoftwareKeyboard(focusNode);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      keyboardAppearance: Brightness.light,
      textInputAction: textInputAction,
      obscureText: obscureText,
      enabled: true,
      readOnly: false,
      autofocus: false,
      enableSuggestions: !obscureText,
      autocorrect: !obscureText,
      onTap: _showKeyboard,
      onFieldSubmitted: onSubmitted,
      decoration: InputDecoration(hintText: hint, suffixIcon: suffixIcon),
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

  final emailFocus = FocusNode();
  final passwordFocus = FocusNode();

  bool obscure = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        showSoftwareKeyboard(emailFocus);
      }
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    super.dispose();
  }

  void submit() {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address'),
          duration: Duration(milliseconds: 1200),
        ),
      );
      showSoftwareKeyboard(emailFocus);
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address'),
          duration: Duration(milliseconds: 1200),
        ),
      );
      showSoftwareKeyboard(emailFocus);
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your password'),
          duration: Duration(milliseconds: 1200),
        ),
      );
      showSoftwareKeyboard(passwordFocus);
      return;
    }

    if (password.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 4 characters'),
          duration: Duration(milliseconds: 1200),
        ),
      );
      showSoftwareKeyboard(passwordFocus);
      return;
    }

    FocusScope.of(context).unfocus();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainShell()),
      (_) => false,
    );
  }

  void forgotPassword() {
    FocusScope.of(context).unfocus();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          title: const Text(
            'RESET PASSWORD',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          content: const Text(
            'Enter your email address on the login screen and we will send a password reset link.',
            style: AppText.body,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                showSoftwareKeyboard(emailFocus);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'LOGIN',
      children: [
        NazzeField(
          controller: emailController,
          focusNode: emailFocus,
          hint: 'Email address',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) {
            showSoftwareKeyboard(passwordFocus);
          },
        ),
        const SizedBox(height: 14),
        NazzeField(
          controller: passwordController,
          focusNode: passwordFocus,
          hint: 'Password',
          keyboardType: TextInputType.visiblePassword,
          obscureText: obscure,
          textInputAction: TextInputAction.done,
          suffixIcon: IconButton(
            onPressed: () {
              setState(() {
                obscure = !obscure;
              });
            },
            icon: Icon(
              obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 19,
              color: AppColors.grey,
            ),
          ),
          onSubmitted: (_) {
            submit();
          },
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: forgotPassword,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.grey,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
            ),
            child: const Text(
              'Forgot password?',
              style: TextStyle(color: AppColors.grey, fontSize: 12),
            ),
          ),
        ),
        const SizedBox(height: 2),
        PrimaryButton(text: 'LOGIN', onTap: submit),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const SignUpScreen()),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.grey),
            child: const Text(
              "Don't have an account? Sign Up",
              style: TextStyle(color: AppColors.grey, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final firstController = TextEditingController();
  final lastController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final firstFocus = FocusNode();
  final lastFocus = FocusNode();
  final emailFocus = FocusNode();
  final passwordFocus = FocusNode();
  final confirmPasswordFocus = FocusNode();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        showSoftwareKeyboard(firstFocus);
      }
    });
  }

  @override
  void dispose() {
    firstController.dispose();
    lastController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();

    firstFocus.dispose();
    lastFocus.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    confirmPasswordFocus.dispose();

    super.dispose();
  }

  void submit() {
    FocusScope.of(context).unfocus();

    if (firstController.text.trim().isEmpty ||
        lastController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all fields'),
          duration: Duration(milliseconds: 1200),
        ),
      );
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          duration: Duration(milliseconds: 1200),
        ),
      );
      showSoftwareKeyboard(confirmPasswordFocus);
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainShell()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'CREATE ACCOUNT',
      children: [
        NazzeField(
          controller: firstController,
          focusNode: firstFocus,
          hint: 'First Name',
          keyboardType: TextInputType.name,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) {
            showSoftwareKeyboard(lastFocus);
          },
        ),
        const SizedBox(height: 12),
        NazzeField(
          controller: lastController,
          focusNode: lastFocus,
          hint: 'Last Name',
          keyboardType: TextInputType.name,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) {
            showSoftwareKeyboard(emailFocus);
          },
        ),
        const SizedBox(height: 12),
        NazzeField(
          controller: emailController,
          focusNode: emailFocus,
          hint: 'Email address',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) {
            showSoftwareKeyboard(passwordFocus);
          },
        ),
        const SizedBox(height: 12),
        NazzeField(
          controller: passwordController,
          focusNode: passwordFocus,
          hint: 'Password',
          keyboardType: TextInputType.visiblePassword,
          obscureText: obscurePassword,
          textInputAction: TextInputAction.next,
          suffixIcon: IconButton(
            onPressed: () {
              setState(() {
                obscurePassword = !obscurePassword;
              });
            },
            icon: Icon(
              obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 19,
              color: AppColors.grey,
            ),
          ),
          onSubmitted: (_) {
            showSoftwareKeyboard(confirmPasswordFocus);
          },
        ),
        const SizedBox(height: 12),
        NazzeField(
          controller: confirmPasswordController,
          focusNode: confirmPasswordFocus,
          hint: 'Confirm password',
          keyboardType: TextInputType.visiblePassword,
          obscureText: obscureConfirmPassword,
          textInputAction: TextInputAction.done,
          suffixIcon: IconButton(
            onPressed: () {
              setState(() {
                obscureConfirmPassword = !obscureConfirmPassword;
              });
            },
            icon: Icon(
              obscureConfirmPassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 19,
              color: AppColors.grey,
            ),
          ),
          onSubmitted: (_) {
            submit();
          },
        ),
        const SizedBox(height: 14),
        PrimaryButton(text: 'CREATE ACCOUNT', onTap: submit),
        const SizedBox(height: 10),
        Center(
          child: TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: const Text(
              'Already have an account? Login',
              style: TextStyle(color: AppColors.grey, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}

/* =========================================================
   MAIN SHELL WITH PERMANENT BOTTOM NAV
========================================================= */

enum MainPage { home, search, wishlist, bag, profile, listing }

class MainShell extends StatefulWidget {
  final int initialIndex;
  final String? initialCategory;

  const MainShell({super.key, this.initialIndex = 0, this.initialCategory});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int selectedIndex;
  late final List<Widget?> _tabPages;

  MainPage activePage = MainPage.home;
  String listingCategory = 'DRESSES';
  String listingSize = 'M';
  double listingMaxPrice = 150;

  @override
  void initState() {
    super.initState();

    selectedIndex = widget.initialIndex;
    _tabPages = List<Widget?>.filled(5, null);

    if (widget.initialCategory != null) {
      listingCategory = widget.initialCategory!;
      activePage = MainPage.listing;
    } else {
      activePage = _pageForIndex(selectedIndex);
    }
  }

  MainPage _pageForIndex(int index) {
    switch (index) {
      case 1:
        return MainPage.search;
      case 2:
        return MainPage.wishlist;
      case 3:
        return MainPage.bag;
      case 4:
        return MainPage.profile;
      default:
        return MainPage.home;
    }
  }

  void switchTab(int index) {
    FocusScope.of(context).unfocus();

    if (selectedIndex == index && activePage != MainPage.listing) {
      return;
    }

    setState(() {
      selectedIndex = index;
      activePage = _pageForIndex(index);
    });
  }

  void openListing(String category) {
    FocusScope.of(context).unfocus();

    setState(() {
      selectedIndex = 0;
      listingCategory = category;
      listingSize = 'M';
      listingMaxPrice = 150;
      activePage = MainPage.listing;
    });
  }

  void backHome() {
    FocusScope.of(context).unfocus();

    setState(() {
      selectedIndex = 0;
      activePage = MainPage.home;
    });
  }

  Widget _buildTab(int index) {
    switch (index) {
      case 1:
        return const SearchPage();
      case 2:
        return const WishlistPage();
      case 3:
        return BagPage(onContinueShopping: backHome);
      case 4:
        return ProfilePage(
          onLogout: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const WelcomeScreen()),
              (_) => false,
            );
          },
        );
      default:
        return HomePage(onOpenListing: openListing, onTab: switchTab);
    }
  }

  Widget _mainTabs() {
    // Create each main page only when it is visited for the first time.
    // After that it remains mounted, so returning to it is fast and smooth.
    _tabPages[selectedIndex] ??= _buildTab(selectedIndex);

    return IndexedStack(
      index: selectedIndex,
      sizing: StackFit.expand,
      children: List<Widget>.generate(
        5,
        (index) => _tabPages[index] ?? const SizedBox.shrink(),
      ),
    );
  }

  Widget _body() {
    if (activePage == MainPage.listing) {
      return ProductListingPage(
        category: listingCategory,
        selectedSize: listingSize,
        maxPrice: listingMaxPrice,
        onBack: backHome,
        onFilterChanged: (result) {
          setState(() {
            listingCategory = result.category;
            listingSize = result.size;
            listingMaxPrice = result.maxPrice;
          });
        },
      );
    }

    return _mainTabs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: RepaintBoundary(child: _body())),
      bottomNavigationBar: AnimatedBuilder(
        animation: NazzeStore.instance,
        builder: (context, _) {
          return NazzeBottomNavigation(
            currentIndex: selectedIndex,
            cartCount: NazzeStore.instance.cartCount,
            onTap: switchTab,
          );
        },
      ),
    );
  }
}

class NazzeBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final int cartCount;
  final ValueChanged<int> onTap;

  const NazzeBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.cartCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.lightGrey)),
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.white,
          selectedItemColor: AppColors.black,
          unselectedItemColor: AppColors.grey,
          selectedFontSize: 10,
          unselectedFontSize: 10,
          elevation: 0,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Search',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border),
              activeIcon: Icon(Icons.favorite),
              label: 'Wishlist',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.shopping_bag_outlined),
                  if (cartCount > 0)
                    Positioned(
                      right: -8,
                      top: -5,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppColors.black,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$cartCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              label: 'Bag',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

/* =========================================================
   HOME
========================================================= */

class HomePage extends StatelessWidget {
  final ValueChanged<String> onOpenListing;
  final ValueChanged<int> onTab;

  const HomePage({super.key, required this.onOpenListing, required this.onTab});

  @override
  Widget build(BuildContext context) {
    final satin = productById('satin-blue');
    final linenTop = productById('linen-top');

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('NAZZE', style: AppText.logo),
              const Spacer(),
              IconButton(
                onPressed: () {
                  onTab(2);
                },
                icon: const Icon(Icons.favorite_border),
              ),
            ],
          ),
          const SizedBox(height: 20),
          InkWell(
            onTap: () {
              onTab(1);
            },
            child: const IgnorePointer(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search products',
                  prefixIcon: Icon(Icons.search, color: AppColors.grey),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final heroHeight = (constraints.maxWidth / 1.45)
                  .clamp(220.0, 280.0)
                  .toDouble();

              return Container(
                height: heroHeight,
                width: double.infinity,
                color: AppColors.lightGrey,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const SmoothAssetImage(
                      'assets/images/fashion_blue.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      cacheWidth: 820,
                    ),
                    Container(color: Colors.black.withOpacity(.18)),
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 22,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'NEW COLLECTION',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              letterSpacing: 1.8,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 7),
                          const Text(
                            'DISCOVER THE LATEST',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 13),
                          OutlinedButton(
                            onPressed: () {
                              onOpenListing('DRESSES');
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white),
                              shape: const RoundedRectangleBorder(),
                            ),
                            child: const Text('SHOP NOW'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 30),
          const Center(child: Text('SHOP BY CATEGORY', style: AppText.h2)),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: CategoryButton(
                  text: 'DRESSES',
                  onTap: () {
                    onOpenListing('DRESSES');
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CategoryButton(
                  text: 'TOPS',
                  onTap: () {
                    onOpenListing('TOPS');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: CategoryButton(
                  text: 'BOTTOMS',
                  onTap: () {
                    onOpenListing('BOTTOMS');
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CategoryButton(
                  text: 'SHOES',
                  onTap: () {
                    onOpenListing('SHOES');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Center(child: Text('NEW ARRIVALS', style: AppText.h2)),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: NewArrivalCard(product: satin)),
              const SizedBox(width: 12),
              Expanded(child: NewArrivalCard(product: linenTop)),
            ],
          ),
        ],
      ),
    );
  }
}

class CategoryButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const CategoryButton({super.key, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.black,
        backgroundColor: AppColors.white,
        side: const BorderSide(color: AppColors.black),
        shape: const RoundedRectangleBorder(),
        padding: const EdgeInsets.symmetric(vertical: 15),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: .8,
        ),
      ),
    );
  }
}

class NewArrivalCard extends StatelessWidget {
  final Product product;

  const NewArrivalCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        openProduct(context, product);
      },
      child: Container(
        color: AppColors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: AspectRatio(
                aspectRatio: 0.72,
                child: Container(
                  width: double.infinity,
                  color: AppColors.background,
                  child: SmoothAssetImage(
                    product.image,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    cacheWidth: 420,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 13),
              child: SizedBox(
                height: 50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: .4,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '\$${product.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* =========================================================
   PRODUCT LISTING
========================================================= */

class ProductListingPage extends StatelessWidget {
  final String category;
  final String selectedSize;
  final double maxPrice;
  final VoidCallback onBack;
  final ValueChanged<FilterResult> onFilterChanged;

  const ProductListingPage({
    super.key,
    required this.category,
    required this.selectedSize,
    required this.maxPrice,
    required this.onBack,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final visibleProducts = products
        .where(
          (product) =>
              product.category == category && product.price <= maxPrice,
        )
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              ),
              const SizedBox(width: 4),
              const Text('NAZZE', style: AppText.logo),
              const Spacer(),
              IconButton(
                onPressed: () async {
                  final result = await Navigator.push<FilterResult>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FilterScreen(
                        initialCategory: category,
                        initialSize: selectedSize,
                        initialMaxPrice: maxPrice,
                      ),
                    ),
                  );

                  if (result != null) {
                    onFilterChanged(result);
                  }
                },
                icon: const Icon(Icons.tune),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Row(
            children: [
              Text(category, style: AppText.h1),
              const Spacer(),
              Text(
                '${visibleProducts.length} ITEMS',
                style: const TextStyle(
                  fontSize: 11,
                  letterSpacing: .8,
                  color: AppColors.grey,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: visibleProducts.isEmpty
              ? const Center(
                  child: Text('No products available', style: AppText.body),
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 26),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 230,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 18,
                    childAspectRatio: .60,
                  ),
                  itemCount: visibleProducts.length,
                  itemBuilder: (_, index) {
                    return ProductGridCard(product: visibleProducts[index]);
                  },
                ),
        ),
      ],
    );
  }
}

class ProductGridCard extends StatelessWidget {
  final Product product;

  const ProductGridCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: NazzeStore.instance,
      builder: (context, _) {
        final liked = NazzeStore.instance.isWishlisted(product);

        return GestureDetector(
          onTap: () {
            openProduct(context, product);
          },
          child: Container(
            color: AppColors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      SmoothAssetImage(
                        product.image,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        cacheWidth: 420,
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Material(
                          color: Colors.white.withOpacity(.94),
                          shape: const CircleBorder(),
                          child: IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              NazzeStore.instance.toggleWishlist(product);
                            },
                            icon: Icon(
                              liked ? Icons.favorite : Icons.favorite_border,
                              color: AppColors.black,
                              size: 19,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

void openProduct(BuildContext context, Product product) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: product)),
  );
}

/* =========================================================
   PRODUCT DETAILS
========================================================= */

class ProductDetailsScreen extends StatefulWidget {
  final Product product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  String selectedSize = 'M';

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: NazzeStore.instance,
      builder: (context, _) {
        final liked = NazzeStore.instance.isWishlisted(widget.product);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () {
                          NazzeStore.instance.toggleWishlist(widget.product);
                        },
                        icon: Icon(
                          liked ? Icons.favorite : Icons.favorite_border,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 26),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AspectRatio(
                          aspectRatio: 0.88,
                          child: SmoothAssetImage(
                            widget.product.image,
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                            cacheWidth: 900,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                widget.product.name,
                                style: AppText.h2,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '\$${widget.product.price.toStringAsFixed(2)}',
                              style: AppText.h2,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(widget.product.description, style: AppText.body),
                        const SizedBox(height: 28),
                        const Text('SELECT SIZE', style: AppText.caption),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            for (final size in const [
                              'XS',
                              'S',
                              'M',
                              'L',
                              'XL',
                            ])
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: size == 'XL' ? 0 : 8,
                                  ),
                                  child: SizeButton(
                                    text: size,
                                    selected: selectedSize == size,
                                    onTap: () {
                                      setState(() {
                                        selectedSize = size;
                                      });
                                    },
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Container(
              color: AppColors.white,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
              child: PrimaryButton(
                text: 'ADD TO BAG',
                onTap: () {
                  NazzeStore.instance.addToBag(widget.product, selectedSize);

                  ScaffoldMessenger.of(context).hideCurrentSnackBar();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Added to bag'),
                      duration: Duration(milliseconds: 900),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class SizeButton extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const SizeButton({
    super.key,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: selected ? AppColors.white : AppColors.black,
        backgroundColor: selected ? AppColors.black : AppColors.white,
        side: const BorderSide(color: AppColors.black),
        shape: const RoundedRectangleBorder(),
        padding: const EdgeInsets.symmetric(vertical: 13),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }
}

/* =========================================================
   SEARCH
========================================================= */

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final controller = TextEditingController();
  final focusNode = FocusNode();

  String query = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        showSoftwareKeyboard(focusNode);
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    super.dispose();
  }

  void useRecent(String text) {
    controller.text = text;

    setState(() {
      query = text;
    });

    showSoftwareKeyboard(focusNode);
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = query.trim().isEmpty
        ? <Product>[]
        : products
              .where(
                (product) =>
                    product.name.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('SEARCH', style: AppText.h1),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.search,
              onTap: () {
                showSoftwareKeyboard(focusNode);
              },
              onChanged: (value) {
                setState(() {
                  query = value;
                });
              },
              decoration: const InputDecoration(
                hintText: 'Search products...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 28),
            if (query.trim().isEmpty) ...[
              const Text('RECENT SEARCHES', style: AppText.h2),
              const SizedBox(height: 12),
              SearchTextRow(
                text: 'Satin Dress',
                onTap: () {
                  useRecent('Satin Dress');
                },
              ),
              SearchTextRow(
                text: 'Linen Top',
                onTap: () {
                  useRecent('Linen Top');
                },
              ),
              const SizedBox(height: 28),
              const Text('POPULAR', style: AppText.h2),
              const SizedBox(height: 14),
              SearchProductTile(product: productById('satin-blue')),
              SearchProductTile(product: productById('linen-dress')),
            ] else if (searchResults.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Text('No products found', style: AppText.body),
              )
            else
              for (final product in searchResults)
                SearchProductTile(product: product),
          ],
        ),
      ),
    );
  }
}

class SearchTextRow extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const SearchTextRow({super.key, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.history, size: 20, color: AppColors.grey),
      title: Text(text, style: const TextStyle(fontSize: 14)),
      onTap: onTap,
    );
  }
}

class SearchProductTile extends StatelessWidget {
  final Product product;

  const SearchProductTile({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        openProduct(context, product);
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          children: [
            SizedBox(
              width: 78,
              height: 96,
              child: SmoothAssetImage(
                product.image,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                cacheWidth: 240,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(color: AppColors.grey),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

/* =========================================================
   WISHLIST
========================================================= */

class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: NazzeStore.instance,
      builder: (context, _) {
        final saved = products.where(NazzeStore.instance.isWishlisted).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 16),
              child: Text('WISHLIST', style: AppText.h1),
            ),
            Expanded(
              child: saved.isEmpty
                  ? const Center(
                      child: Text(
                        'Your wishlist is empty',
                        style: AppText.body,
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 26),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 230,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 18,
                            childAspectRatio: .60,
                          ),
                      itemCount: saved.length,
                      itemBuilder: (_, index) {
                        return ProductGridCard(product: saved[index]);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

/* =========================================================
   BAG
========================================================= */

class BagPage extends StatelessWidget {
  final VoidCallback onContinueShopping;

  const BagPage({super.key, required this.onContinueShopping});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: NazzeStore.instance,
      builder: (context, _) {
        final store = NazzeStore.instance;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 16),
              child: Text('SHOPPING BAG', style: AppText.h1),
            ),
            if (store.cart.isEmpty)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shopping_bag_outlined, size: 44),
                        const SizedBox(height: 16),
                        const Text('Your bag is empty', style: AppText.h2),
                        const SizedBox(height: 22),
                        SecondaryButton(
                          text: 'CONTINUE SHOPPING',
                          onTap: onContinueShopping,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
                  children: [
                    for (final line in store.cart) BagLineTile(line: line),
                    const SizedBox(height: 18),
                    SummaryRow(
                      label: 'SUBTOTAL',
                      value: '\$${store.subtotal.toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: 10),
                    const SummaryRow(label: 'DELIVERY', value: 'FREE'),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Divider(),
                    ),
                    SummaryRow(
                      label: 'TOTAL',
                      value: '\$${store.subtotal.toStringAsFixed(2)}',
                      bold: true,
                    ),
                    const SizedBox(height: 22),
                    PrimaryButton(
                      text: 'PROCEED TO CHECKOUT',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CheckoutScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    SecondaryButton(
                      text: 'CONTINUE SHOPPING',
                      onTap: onContinueShopping,
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class BagLineTile extends StatelessWidget {
  final CartLine line;

  const BagLineTile({super.key, required this.line});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppColors.white,
      padding: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            height: 126,
            child: SmoothAssetImage(
              line.product.image,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              cacheWidth: 300,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: SizedBox(
              height: 126,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line.product.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text('Size ${line.size}', style: AppText.body),
                  const SizedBox(height: 6),
                  Text('\$${line.product.price.toStringAsFixed(2)}'),
                  const Spacer(),
                  Row(
                    children: [
                      QuantityButton(
                        icon: Icons.remove,
                        onTap: () {
                          NazzeStore.instance.changeQuantity(line, -1);
                        },
                      ),
                      SizedBox(
                        width: 34,
                        child: Center(child: Text('${line.quantity}')),
                      ),
                      QuantityButton(
                        icon: Icons.add,
                        onTap: () {
                          NazzeStore.instance.changeQuantity(line, 1);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const QuantityButton({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.lightGrey),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }
}

/* =========================================================
   CHECKOUT
========================================================= */

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool placingOrder = false;

  Future<void> _placeOrder() async {
    if (placingOrder) {
      return;
    }

    setState(() {
      placingOrder = true;
    });

    await Future.delayed(const Duration(milliseconds: 1100));

    if (!mounted) {
      return;
    }

    final order = NazzeStore.instance.placeCurrentOrder();

    if (order == null) {
      if (!mounted) {
        return;
      }

      setState(() {
        placingOrder = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your bag is empty'),
          duration: Duration(milliseconds: 1200),
        ),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => OrderConfirmationScreen(order: order)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = NazzeStore.instance.subtotal;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: placingOrder
                      ? null
                      : () {
                          Navigator.pop(context);
                        },
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                ),
                const SizedBox(width: 8),
                const Text('CHECKOUT', style: AppText.h1),
              ],
            ),
            const SizedBox(height: 24),
            const Text('DELIVERY ADDRESS', style: AppText.h2),
            const SizedBox(height: 12),
            const InfoCard(
              title: 'Drake Graham',
              lines: ['24 George Street', 'Sydney NSW 2000'],
            ),
            const SizedBox(height: 26),
            const Text('PAYMENT METHOD', style: AppText.h2),
            const SizedBox(height: 12),
            const InfoCard(
              title: 'VISA',
              lines: ['•••• •••• •••• 4242'],
              icon: Icons.credit_card,
            ),
            const SizedBox(height: 30),
            SummaryRow(
              label: 'SUBTOTAL',
              value: '\$${total.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 10),
            const SummaryRow(label: 'DELIVERY', value: 'FREE'),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(),
            ),
            SummaryRow(
              label: 'TOTAL',
              value: '\$${total.toStringAsFixed(2)}',
              bold: true,
            ),
            const SizedBox(height: 26),
            LoadingPrimaryButton(
              text: 'PLACE ORDER',
              loadingText: 'PLACING ORDER',
              loading: placingOrder,
              onTap: _placeOrder,
            ),
          ],
        ),
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final String title;
  final List<String> lines;
  final IconData? icon;

  const InfoCard({
    super.key,
    required this.title,
    required this.lines,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 22),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                for (final line in lines) Text(line, style: AppText.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const SummaryRow({
    super.key,
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 13,
      fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
      color: AppColors.black,
    );

    return Row(
      children: [
        Text(label, style: style),
        const Spacer(),
        Text(value, style: style),
      ],
    );
  }
}

/* =========================================================
   ORDER CONFIRMATION
========================================================= */

class OrderConfirmationScreen extends StatelessWidget {
  final OrderRecord order;

  const OrderConfirmationScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 30, 24, 30),
          child: Column(
            children: [
              const Spacer(),
              const Icon(
                Icons.check_circle_outline,
                size: 76,
                color: AppColors.black,
              ),
              const SizedBox(height: 28),
              const Text(
                'ORDER CONFIRMED',
                style: AppText.h1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              const Text(
                'Thank you for your purchase. Your order has been placed successfully.',
                textAlign: TextAlign.center,
                style: AppText.body,
              ),
              const SizedBox(height: 20),
              Text(
                'ORDER #${order.id}',
                style: const TextStyle(
                  fontSize: 13,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text('\$${order.total.toStringAsFixed(2)}', style: AppText.body),
              const Spacer(),
              PrimaryButton(
                text: 'CONTINUE SHOPPING',
                onTap: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const MainShell()),
                    (_) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* =========================================================
   PROFILE
========================================================= */

class ProfilePage extends StatelessWidget {
  final VoidCallback onLogout;

  const ProfilePage({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PROFILE', style: AppText.h1),
          const SizedBox(height: 28),
          const Center(
            child: CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.black,
              child: Text(
                'J',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Center(
            child: Text(
              'Jamie Smith',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 5),
          const Center(child: Text('jamie@example.com', style: AppText.body)),
          const SizedBox(height: 30),
          ProfileRow(
            icon: Icons.receipt_long_outlined,
            text: 'My Orders',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
              );
            },
          ),
          ProfileRow(
            icon: Icons.location_on_outlined,
            text: 'Saved Addresses',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SavedAddressesScreen()),
              );
            },
          ),
          ProfileRow(
            icon: Icons.credit_card_outlined,
            text: 'Payment Methods',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PaymentMethodsScreen()),
              );
            },
          ),
          ProfileRow(
            icon: Icons.settings_outlined,
            text: 'Settings',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(height: 18),
          SecondaryButton(text: 'LOG OUT', onTap: onLogout),
        ],
      ),
    );
  }
}

class ProfileRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const ProfileRow({
    super.key,
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon, color: AppColors.black),
          title: Text(text),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
        const Divider(height: 1),
      ],
    );
  }
}

class ProfileScreenScaffold extends StatelessWidget {
  final String title;
  final Widget child;

  const ProfileScreenScaffold({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  ),
                  const SizedBox(width: 6),
                  Expanded(child: Text(title, style: AppText.h1)),
                ],
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  String _dateLabel(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  @override
  Widget build(BuildContext context) {
    return ProfileScreenScaffold(
      title: 'MY ORDERS',
      child: AnimatedBuilder(
        animation: NazzeStore.instance,
        builder: (context, _) {
          final orders = NazzeStore.instance.orders;

          if (orders.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 44,
                      color: AppColors.grey,
                    ),
                    SizedBox(height: 16),
                    Text('NO ORDERS YET', style: AppText.h2),
                    SizedBox(height: 8),
                    Text(
                      'Orders you place during this app session will appear here.',
                      textAlign: TextAlign.center,
                      style: AppText.body,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final order = orders[index];

              return Container(
                color: AppColors.white,
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'ORDER #${order.id}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: .8,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          color: AppColors.lightGrey,
                          child: Text(
                            order.status,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: .5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(_dateLabel(order.placedAt), style: AppText.body),
                    const SizedBox(height: 16),
                    for (final line in order.lines) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 58,
                            height: 72,
                            child: SmoothAssetImage(
                              line.product.image,
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                              cacheWidth: 180,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  line.product.name,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'Size ${line.size} · Qty ${line.quantity}',
                                  style: AppText.body,
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  '\$${(line.product.price * line.quantity).toStringAsFixed(2)}',
                                  style: AppText.caption,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    const Divider(),
                    const SizedBox(height: 8),
                    SummaryRow(
                      label: 'TOTAL',
                      value: '\$${order.total.toStringAsFixed(2)}',
                      bold: true,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class SavedAddressesScreen extends StatefulWidget {
  const SavedAddressesScreen({super.key});

  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  String name = 'Drake Graham';
  String address = '24 George Street';
  String city = 'Sydney NSW 2000';

  Future<void> _editAddress() async {
    final nameController = TextEditingController(text: name);
    final addressController = TextEditingController(text: address);
    final cityController = TextEditingController(text: city);

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          title: const Text('EDIT ADDRESS'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(hintText: 'Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressController,
                  keyboardType: TextInputType.streetAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(hintText: 'Street address'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cityController,
                  keyboardType: TextInputType.streetAddress,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    hintText: 'City / postcode',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('SAVE'),
            ),
          ],
        );
      },
    );

    if (saved == true) {
      setState(() {
        name = nameController.text.trim().isEmpty
            ? name
            : nameController.text.trim();
        address = addressController.text.trim().isEmpty
            ? address
            : addressController.text.trim();
        city = cityController.text.trim().isEmpty
            ? city
            : cityController.text.trim();
      });
    }

    nameController.dispose();
    addressController.dispose();
    cityController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ProfileScreenScaffold(
      title: 'SAVED ADDRESSES',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Text(
                      'DEFAULT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: .7,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(address, style: AppText.body),
                Text(city, style: AppText.body),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _editAddress,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.black,
                    side: const BorderSide(color: AppColors.black),
                    shape: const RoundedRectangleBorder(),
                  ),
                  child: const Text('EDIT ADDRESS'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  bool extraCardAdded = false;

  @override
  Widget build(BuildContext context) {
    return ProfileScreenScaffold(
      title: 'PAYMENT METHODS',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          PaymentCardTile(
            label: 'VISA',
            number: '•••• •••• •••• 4242',
            isDefault: true,
          ),
          if (extraCardAdded) ...[
            const SizedBox(height: 12),
            const PaymentCardTile(
              label: 'MASTERCARD',
              number: '•••• •••• •••• 1188',
              isDefault: false,
            ),
          ],
          const SizedBox(height: 18),
          SecondaryButton(
            text: extraCardAdded ? 'CARD ADDED' : 'ADD PAYMENT METHOD',
            onTap: () {
              if (extraCardAdded) {
                return;
              }

              setState(() {
                extraCardAdded = true;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Payment method added for this demo'),
                  duration: Duration(milliseconds: 1000),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class PaymentCardTile extends StatelessWidget {
  final String label;
  final String number;
  final bool isDefault;

  const PaymentCardTile({
    super.key,
    required this.label,
    required this.number,
    required this.isDefault,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          const Icon(Icons.credit_card_outlined),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 5),
                Text(number, style: AppText.body),
              ],
            ),
          ),
          if (isDefault)
            const Text(
              'DEFAULT',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: .6,
              ),
            ),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool orderUpdates = true;
  bool newArrivals = true;
  bool promotions = false;

  @override
  Widget build(BuildContext context) {
    return ProfileScreenScaffold(
      title: 'SETTINGS',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          Container(
            color: AppColors.white,
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Order updates'),
                  subtitle: const Text(
                    'Receive updates about your orders',
                    style: AppText.body,
                  ),
                  value: orderUpdates,
                  activeColor: AppColors.black,
                  onChanged: (value) {
                    setState(() {
                      orderUpdates = value;
                    });
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('New arrivals'),
                  subtitle: const Text(
                    'Get notified when new products arrive',
                    style: AppText.body,
                  ),
                  value: newArrivals,
                  activeColor: AppColors.black,
                  onChanged: (value) {
                    setState(() {
                      newArrivals = value;
                    });
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Promotions'),
                  subtitle: const Text(
                    'Receive promotional offers',
                    style: AppText.body,
                  ),
                  value: promotions,
                  activeColor: AppColors.black,
                  onChanged: (value) {
                    setState(() {
                      promotions = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* =========================================================
   FILTER
========================================================= */

class FilterResult {
  final String category;
  final String size;
  final double maxPrice;

  const FilterResult({
    required this.category,
    required this.size,
    required this.maxPrice,
  });
}

class FilterScreen extends StatefulWidget {
  final String initialCategory;
  final String initialSize;
  final double initialMaxPrice;

  const FilterScreen({
    super.key,
    required this.initialCategory,
    this.initialSize = 'M',
    this.initialMaxPrice = 150,
  });

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  late String category;
  late String size;
  late double maxPrice;

  @override
  void initState() {
    super.initState();
    category = widget.initialCategory;
    size = widget.initialSize;
    maxPrice = widget.initialMaxPrice;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close),
                  ),
                  const SizedBox(width: 6),
                  const Text('FILTER', style: AppText.h1),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                children: [
                  const Text('CATEGORY', style: AppText.h2),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final value in const [
                        'DRESSES',
                        'TOPS',
                        'BOTTOMS',
                        'SHOES',
                      ])
                        ChoiceChip(
                          label: Text(value),
                          selected: category == value,
                          showCheckmark: false,
                          onSelected: (_) {
                            setState(() {
                              category = value;
                            });
                          },
                          selectedColor: AppColors.black,
                          backgroundColor: AppColors.white,
                          labelStyle: TextStyle(
                            color: category == value
                                ? Colors.white
                                : AppColors.black,
                            fontSize: 12,
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                            side: BorderSide(color: AppColors.black),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text('SIZE', style: AppText.h2),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      for (final value in const ['XS', 'S', 'M', 'L', 'XL'])
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: value == 'XL' ? 0 : 8,
                            ),
                            child: SizeButton(
                              text: value,
                              selected: size == value,
                              onTap: () {
                                setState(() {
                                  size = value;
                                });
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text('PRICE', style: AppText.h2),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('\$0', style: AppText.body),
                      const Spacer(),
                      Text('\$${maxPrice.round()}', style: AppText.body),
                    ],
                  ),
                  Slider(
                    value: maxPrice,
                    min: 0,
                    max: 150,
                    divisions: 15,
                    activeColor: AppColors.black,
                    inactiveColor: AppColors.lightGrey,
                    onChanged: (value) {
                      setState(() {
                        maxPrice = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Container(
                color: AppColors.white,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                child: PrimaryButton(
                  text: 'APPLY FILTERS',
                  onTap: () {
                    Navigator.pop(
                      context,
                      FilterResult(
                        category: category,
                        size: size,
                        maxPrice: maxPrice,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* =========================================================
   BUTTONS
========================================================= */

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const PrimaryButton({super.key, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.black,
          foregroundColor: AppColors.white,
          elevation: 0,
          shape: const RoundedRectangleBorder(),
        ),
        child: Text(text, style: AppText.button),
      ),
    );
  }
}

class LoadingPrimaryButton extends StatelessWidget {
  final String text;
  final String loadingText;
  final bool loading;
  final VoidCallback onTap;

  const LoadingPrimaryButton({
    super.key,
    required this.text,
    required this.loadingText,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.black,
          disabledBackgroundColor: AppColors.black,
          foregroundColor: AppColors.white,
          disabledForegroundColor: AppColors.white,
          elevation: 0,
          shape: const RoundedRectangleBorder(),
        ),
        child: loading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(loadingText, style: AppText.button),
                ],
              )
            : Text(text, style: AppText.button),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const SecondaryButton({super.key, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.black,
          side: const BorderSide(color: AppColors.black),
          shape: const RoundedRectangleBorder(),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }
}
