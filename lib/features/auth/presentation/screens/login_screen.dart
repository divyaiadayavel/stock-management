import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for SystemUiOverlayStyle
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/auth_controller.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import 'package:stock_management/features/dashboard/presentation/screens/main_navigation.dart';
import 'forgot_password_screen.dart';
import '../../../settings/domain/entities/business_profile.dart';
import '../../../../core/network/api_config.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final emailFocus = FocusNode();
  final passwordFocus = FocusNode();

  bool hidePassword = true;
  bool rememberMe = false;
  bool validateEmailNow = false;
  bool validatePasswordNow = false;
  bool _businessProfileReady = false;

  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  static const String _fallbackStoreName = "Catalystack";
  static const String _fallbackTagline = "Smart Billing for Modern Stores";

  BusinessProfile _profile = const BusinessProfile();
  String? get _logoUrl {
    return _resolveLogoUrl(_profile.logoPath);
  }

  String? _resolveLogoUrl(String logoPath) {
    final trimmedPath = logoPath.trim();

    if (trimmedPath.isEmpty) return null;

    if (trimmedPath.startsWith('http://') ||
        trimmedPath.startsWith('https://')) {
      return trimmedPath;
    }

    final normalizedPath = trimmedPath.startsWith("/")
        ? trimmedPath.substring(1)
        : trimmedPath;

    return "${ApiConfig.baseUrl}/$normalizedPath";
  }

  String get _storeName {
    final value = _profile.storeName.trim();
    return value.isEmpty ? _fallbackStoreName : value;
  }

  String get _tagline {
    final value = _profile.tagline.trim();
    return value.isEmpty ? _fallbackTagline : value;
  }

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -12, end: 12).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    loadBusinessProfile();

    emailFocus.addListener(() {
      if (!emailFocus.hasFocus) {
        setState(() => validateEmailNow = true);
        formKey.currentState?.validate();
      }
    });

    passwordFocus.addListener(() {
      if (!passwordFocus.hasFocus) {
        setState(() => validatePasswordNow = true);
        formKey.currentState?.validate();
      }
    });
  }

  Future<void> loadBusinessProfile() async {
    try {
      final bundle = await ref.read(settingsControllerProvider.future);

      final profile = bundle.profile;
      final logoUrl = _resolveLogoUrl(profile.logoPath);

      if (logoUrl != null && mounted) {
        try {
          await precacheImage(
            CachedNetworkImageProvider(logoUrl, cacheKey: logoUrl),
            context,
          );
        } catch (e) {
          debugPrint("Failed to precache business logo: $e");
        }
      }

      if (!mounted) return;

      setState(() {
        _profile = profile;
        _businessProfileReady = true;
      });
    } catch (e) {
      debugPrint("Failed to load business profile: $e");
      if (!mounted) return;
      setState(() => _businessProfileReady = true);
    }
  }

  Future<void> loginUser() async {
    setState(() {
      validateEmailNow = true;
      validatePasswordNow = true;
    });

    if (!formKey.currentState!.validate()) return;

    final success = await ref
        .read(authControllerProvider.notifier)
        .login(emailController.text.trim(), passwordController.text.trim());

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } else {
      final error =
          ref.read(authControllerProvider).error ?? "Invalid email or password";
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final size = MediaQuery.of(context).size;
    final topZone = size.height * 0.42;

    // Wrapped Scaffold in AnnotatedRegion to make status bar transparent
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, // Removes the black background
        statusBarIconBrightness: Brightness.light, // Android: white icons
        statusBarBrightness: Brightness.dark, // iOS: white icons
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            // ── Gradient background ──────────────────────────
            Container(
              width: size.width,
              height: size.height,
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.55), // glow sits behind logo
                  radius: 0.85,
                  colors: [
                    Color(0xFF1A6DD4), // bright blue glow center
                    Color(0xFF0D3A7A), // mid navy
                    Color(0xFF071229), // very dark navy edges
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),

            // ── Logo / store name / tagline (blue zone) ──────
            SizedBox(
              height: topZone,
              width: size.width,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // floating decorations + logo
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        // animated decorations
                        AnimatedBuilder(
                          animation: _floatAnimation,
                          builder: (context, child) => Transform.translate(
                            offset: Offset(0, _floatAnimation.value + 30),
                            child: child,
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // Cyan filled circle
                              Positioned(
                                top: 0,
                                left: 0,
                                child: Container(
                                  width: AppSizes.iconSm,
                                  height: AppSizes.iconSm,
                                  decoration: const BoxDecoration(
                                    color: AppColors.cyanDim,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              // Outlined circle
                              Positioned(
                                left: 0,
                                bottom: 50,
                                child: Container(
                                  width: AppSpacing.md,
                                  height: AppSpacing.md,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.textWhite.withOpacity(
                                        0.5,
                                      ),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                              // Triangle
                              Positioned(
                                right: 5,
                                bottom: 45,
                                child: const Icon(
                                  Icons.change_history,
                                  size: AppSizes.iconMd,
                                  color: AppColors.cyan,
                                ),
                              ),
                              // Parachute
                              Positioned(
                                top: -35,
                                right: -15,
                                child: AnimatedBuilder(
                                  animation: _floatAnimation,
                                  builder: (context, child) =>
                                      Transform.translate(
                                        offset: Offset(
                                          0,
                                          _floatAnimation.value,
                                        ),
                                        child: child,
                                      ),
                                  child: _buildThemedParachute(),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Logo circle (fixed, not floating)
                        _buildBusinessLogo(),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  _businessProfileReady
                      ? Text(
                          _storeName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        )
                      : _brandPlaceholder(width: 170, height: 30),

                  const SizedBox(height: AppSpacing.sm),

                  _businessProfileReady
                      ? Text(
                          _tagline,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.white70, // or Colors.white
                            height: 1.5,
                          ),
                        )
                      : _brandPlaceholder(width: 220, height: 16),
                ],
              ),
            ),

            // ── White card (slides up from bottom) ───────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: size.height * 0.50,
                decoration: const BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 24,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  AppSpacing.xxl,
                  AppSpacing.screenPadding,
                  MediaQuery.of(context).padding.bottom + AppSpacing.xl,
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Email ──────────────────────────────
                      Text(
                        "Email Address",
                        style: AppTextStyles.small.copyWith(
                          color: AppColors.textPrimaryDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.sm),

                      TextFormField(
                        controller: emailController,
                        focusNode: emailFocus,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.emailAddress,
                        style: AppTextStyles.cardValue,
                        autovalidateMode: validateEmailNow
                            ? AutovalidateMode.always
                            : AutovalidateMode.disabled,
                        validator: (value) =>
                            Validators.validateEmail(value ?? ''),
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(passwordFocus),
                        decoration: _inputDecoration(
                          "Enter your email",
                          Icons.email_outlined,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // ── Password ───────────────────────────
                      Text(
                        "Password",
                        style: AppTextStyles.small.copyWith(
                          color: AppColors.textPrimaryDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.sm),

                      TextFormField(
                        controller: passwordController,
                        focusNode: passwordFocus,
                        obscureText: hidePassword,
                        style: AppTextStyles.cardValue,
                        autovalidateMode: validatePasswordNow
                            ? AutovalidateMode.always
                            : AutovalidateMode.disabled,
                        validator: (value) =>
                            Validators.validateStrongPassword(value ?? ''),
                        decoration: _inputDecoration(
                          "Enter your password",
                          Icons.lock_outline,
                          suffix: IconButton(
                            icon: Icon(
                              hidePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: AppColors.textSecondary,
                              size: AppSizes.iconLg,
                            ),
                            onPressed: () =>
                                setState(() => hidePassword = !hidePassword),
                          ),
                        ),
                        onFieldSubmitted: (_) => loginUser(),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // ── Remember me + Forgot password ──────
                      Row(
                        children: [
                          SizedBox(
                            height: AppSizes.iconLg,
                            width: AppSizes.iconLg,
                            child: Checkbox(
                              value: rememberMe,
                              activeColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusSm,
                                ),
                              ),
                              side: const BorderSide(
                                color: AppColors.borderStrong,
                              ),
                              onChanged: (v) =>
                                  setState(() => rememberMe = v ?? false),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              "Remember this device",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.small,
                            ),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              minimumSize: Size.zero,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.sm,
                              ),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordScreen(),
                              ),
                            ),
                            child: Text(
                              "Forgot password?",
                              style: AppTextStyles.small.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // ── Login button (gradient) ─────────────
                      SizedBox(
                        width: double.infinity,
                        height: AppSizes.buttonHeightLg,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: AppColors.brandGradient,
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusMd,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.cyanDim.withOpacity(0.3),
                                blurRadius: AppSpacing.md,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: authState.isLoading ? null : loginUser,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusMd,
                                ),
                              ),
                            ),
                            child: authState.isLoading
                                ? const CircularProgressIndicator(
                                    color: AppColors.textWhite,
                                  )
                                : Text(
                                    "Sign in  →",
                                    style: AppTextStyles.button.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessLogo() {
    final logoUrl = _businessProfileReady ? _logoUrl : null;
    final cacheSize = (100 * MediaQuery.of(context).devicePixelRatio).round();

    return Container(
      width: 100,
      height: 100,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface2.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: !_businessProfileReady
          ? _logoFallback(showProgress: true)
          : logoUrl == null
          ? _logoFallback()
          : CachedNetworkImage(
              imageUrl: logoUrl,
              cacheKey: logoUrl,
              memCacheWidth: cacheSize,
              memCacheHeight: cacheSize,
              fit: BoxFit.cover,
              fadeInDuration: Duration.zero,
              fadeOutDuration: Duration.zero,
              useOldImageOnUrlChange: true,
              placeholder: (_, _) => _logoFallback(showProgress: true),
              errorWidget: (_, _, _) => _logoFallback(),
            ),
    );
  }

  Widget _logoFallback({bool showProgress = false}) {
    if (showProgress) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.textWhite,
          ),
        ),
      );
    }

    return const Icon(Icons.store, size: 45, color: AppColors.textWhite);
  }

  Widget _brandPlaceholder({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  InputDecoration _inputDecoration(
    String hint,
    IconData icon, {
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.cardTitle,
      prefixIcon: Icon(
        icon,
        color: AppColors.textSecondary,
        size: AppSizes.iconLg,
      ),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.surface2.withOpacity(0.5),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        borderSide: const BorderSide(color: AppColors.border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        borderSide: const BorderSide(color: AppColors.cyanDim, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        borderSide: const BorderSide(color: AppColors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        borderSide: const BorderSide(color: AppColors.red, width: 1.5),
      ),
      errorStyle: const TextStyle(
        color: AppColors.red,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      errorMaxLines: 2,
    );
  }

  // ── THEMED PARACHUTE WIDGET ──────────────────────────
  Widget _buildThemedParachute() {
    return Column(
      children: [
        Container(
          width: 50,
          height: 25,
          decoration: const BoxDecoration(
            color: AppColors.cyanDim,
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(25),
              top: Radius.circular(50),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: ColoredBox(color: AppColors.textWhite.withOpacity(0.8)),
              ),
              const Expanded(child: ColoredBox(color: AppColors.cyanDim)),
              Expanded(
                child: ColoredBox(color: AppColors.textWhite.withOpacity(0.8)),
              ),
              const Expanded(child: ColoredBox(color: AppColors.cyanDim)),
            ],
          ),
        ),
        SizedBox(
          width: 40,
          height: 15,
          child: CustomPaint(painter: _ParachutePainter()),
        ),
        Container(
          width: 28,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.cyanDim,
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: const Icon(
            Icons.bar_chart_rounded,
            color: AppColors.textWhite,
            size: AppSizes.iconSm,
          ),
        ),
      ],
    );
  }
}

class _ParachutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.surface2.withOpacity(0.5)
      ..strokeWidth = 1;

    canvas.drawLine(
      const Offset(0, 0),
      Offset(size.width * .35, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * .25, 0),
      Offset(size.width * .45, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * .75, 0),
      Offset(size.width * .55, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width * .65, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
