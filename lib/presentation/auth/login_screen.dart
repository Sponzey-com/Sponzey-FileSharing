import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponzey_file_sharing/app/theme/app_colors.dart';
import 'package:sponzey_file_sharing/app/theme/app_radius.dart';
import 'package:sponzey_file_sharing/app/theme/app_spacing.dart';
import 'package:sponzey_file_sharing/application/auth/auth_controller.dart';
import 'package:sponzey_file_sharing/presentation/shared/sponzey_card.dart';
import 'package:sponzey_file_sharing/presentation/shared/sponzey_scroll_cue.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  static const routeName = 'login';
  static const routePath = '/login';

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final ScrollController _scrollController = ScrollController();

  final _loginUserIdController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _loginUserIdFocusNode = FocusNode(debugLabel: 'loginUserId');
  final _loginPasswordFocusNode = FocusNode(debugLabel: 'loginPassword');
  bool _canSubmit = false;

  @override
  void initState() {
    super.initState();
    _loginUserIdController.addListener(_updateCanSubmit);
    _loginPasswordController.addListener(_updateCanSubmit);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _loginUserIdFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _loginUserIdController.removeListener(_updateCanSubmit);
    _loginPasswordController.removeListener(_updateCanSubmit);
    _loginUserIdController.dispose();
    _loginPasswordController.dispose();
    _loginUserIdFocusNode.dispose();
    _loginPasswordFocusNode.dispose();
    super.dispose();
  }

  void _updateCanSubmit() {
    final nextCanSubmit =
        _loginUserIdController.text.trim().isNotEmpty &&
        _loginPasswordController.text.isNotEmpty;
    if (nextCanSubmit == _canSubmit) {
      return;
    }
    setState(() {
      _canSubmit = nextCanSubmit;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 960;

        final formCard = SponzeyCard(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('간단히 연결', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.lg),
              Text(
                '가입 없이 아이디와 비밀번호로 현재 실행 세션만 시작합니다. 자격 증명은 앱 메모리에서만 유지됩니다.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (authState.errorMessage != null) ...[
                _InlineMessage(message: authState.errorMessage!),
                const SizedBox(height: AppSpacing.md),
              ],
              _LoginForm(
                userIdController: _loginUserIdController,
                passwordController: _loginPasswordController,
                userIdFocusNode: _loginUserIdFocusNode,
                passwordFocusNode: _loginPasswordFocusNode,
                isBusy:
                    authState.isBusy ||
                    authState.status == AuthStatus.initializing,
                canSubmit: _canSubmit,
                onSubmit: _signIn,
              ),
              if (authState.status == AuthStatus.initializing) ...[
                const SizedBox(height: AppSpacing.md),
                const LinearProgressIndicator(),
              ],
            ],
          ),
        );

        final body = isCompact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _LoginTopBar(),
                  const SizedBox(height: AppSpacing.lg),
                  const _BrandPanel(),
                  const SizedBox(height: AppSpacing.lg),
                  formCard,
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(flex: 5, child: _BrandPanel()),
                  const SizedBox(width: AppSpacing.xxl),
                  Expanded(
                    flex: 5,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: formCard,
                    ),
                  ),
                ],
              );

        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(0),
              child: SponzeyScrollCue(
                controller: _scrollController,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxxl,
                    0,
                    AppSpacing.xxxl,
                    AppSpacing.xxxl,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      children: [
                        if (!isCompact) const _LoginTopBar(),
                        SizedBox(height: isCompact ? 0 : AppSpacing.xxxl),
                        body,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _signIn() async {
    final userId = _loginUserIdController.text.trim();
    final password = _loginPasswordController.text;

    if (userId.isEmpty || password.isEmpty) {
      ref.read(authControllerProvider.notifier).clearError();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('아이디와 비밀번호를 입력해 주세요.')));
      return;
    }

    await ref
        .read(authControllerProvider.notifier)
        .signIn(userId: userId, password: password);
  }
}

class _LoginTopBar extends StatelessWidget {
  const _LoginTopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(bottom: BorderSide(color: AppColors.techBorder)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: AppColors.techGreen,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text('로그인', style: Theme.of(context).textTheme.headlineMedium),
          const Spacer(),
          Text(
            '같은 이름과 비밀번호로 바로 연결',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.techTextMuted),
          ),
        ],
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.techDark,
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '내 기기로 시작',
              style: Theme.of(
                context,
              ).textTheme.displayMedium?.copyWith(color: AppColors.paper),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '주변 기기를 자동으로 찾고, 같은 비밀번호를 쓰는 기기끼리 파일을 주고받습니다.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.techTextOnDark),
            ),
            const SizedBox(height: 72),
            const _SignalCard(),
            const SizedBox(height: AppSpacing.xxxl),
            const _CyanCallout(label: '시작하기'),
          ],
        ),
      ),
    );
  }
}

class _SignalCard extends StatelessWidget {
  const _SignalCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.techDarkRaised,
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(color: AppColors.techBorder.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const _SignalDot(color: AppColors.techCyan),
          const SizedBox(width: AppSpacing.md),
          const _SignalDot(color: AppColors.techBlue),
          const SizedBox(width: AppSpacing.md),
          const _SignalDot(color: AppColors.techGreen),
          const Spacer(),
          Text(
            '주변 기기 3개',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.paper),
          ),
        ],
      ),
    );
  }
}

class _SignalDot extends StatelessWidget {
  const _SignalDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _CyanCallout extends StatelessWidget {
  const _CyanCallout({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.techCyan,
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(color: AppColors.techDark),
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.userIdController,
    required this.passwordController,
    required this.userIdFocusNode,
    required this.passwordFocusNode,
    required this.isBusy,
    required this.canSubmit,
    required this.onSubmit,
  });

  final TextEditingController userIdController;
  final TextEditingController passwordController;
  final FocusNode userIdFocusNode;
  final FocusNode passwordFocusNode;
  final bool isBusy;
  final bool canSubmit;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      child: Column(
        children: [
          TextFormField(
            key: const ValueKey('login-user-id-field'),
            controller: userIdController,
            focusNode: userIdFocusNode,
            enabled: !isBusy,
            readOnly: isBusy,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            enableSuggestions: false,
            onTap: userIdFocusNode.requestFocus,
            onFieldSubmitted: (_) => passwordFocusNode.requestFocus(),
            decoration: const InputDecoration(
              labelText: '아이디',
              hintText: 'admin',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            key: const ValueKey('login-password-field'),
            controller: passwordController,
            focusNode: passwordFocusNode,
            enabled: !isBusy,
            readOnly: isBusy,
            obscureText: true,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            enableSuggestions: false,
            onTap: passwordFocusNode.requestFocus,
            onFieldSubmitted: (_) {
              if (!isBusy) {
                onSubmit();
              }
            },
            decoration: const InputDecoration(
              labelText: '비밀번호',
              hintText: '••••••••',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: const ValueKey('login-submit-button'),
              onPressed: isBusy || !canSubmit ? null : onSubmit,
              icon: const Icon(Icons.login_rounded),
              label: const Text('내 기기 켜기'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger, width: 1.5),
      ),
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.danger),
      ),
    );
  }
}
