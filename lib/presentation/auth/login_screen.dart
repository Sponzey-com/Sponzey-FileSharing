import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sponzey_file_sharing/app/theme/app_colors.dart';
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

  @override
  void initState() {
    super.initState();
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
    _loginUserIdController.dispose();
    _loginPasswordController.dispose();
    _loginUserIdFocusNode.dispose();
    _loginPasswordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 960;

        final formCard = SponzeyCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('로그인', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.xs),
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
                  const _BrandPanel(),
                  const SizedBox(height: AppSpacing.lg),
                  formCard,
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(flex: 4, child: _BrandPanel()),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    flex: 6,
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
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: SponzeyScrollCue(
                controller: _scrollController,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: EdgeInsets.zero,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - (AppSpacing.lg * 2),
                    ),
                    child: body,
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

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.pageGradient,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.ink, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Sponzey FileSharing',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '같은 네트워크 안에서 인증된 장치끼리 빠르게 파일을 주고받는 데스크톱 앱.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.xl),
            const _ValuePoint(
              title: 'Fast local transfer',
              description: '로컬 네트워크 중심의 빠른 파일 전송 흐름',
            ),
          ],
        ),
      ),
    );
  }
}

class _ValuePoint extends StatelessWidget {
  const _ValuePoint({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 14,
          height: 14,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: AppColors.brandYellow,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.ink, width: 2),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.xxs),
              Text(description, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
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
    required this.onSubmit,
  });

  final TextEditingController userIdController;
  final TextEditingController passwordController;
  final FocusNode userIdFocusNode;
  final FocusNode passwordFocusNode;
  final bool isBusy;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      child: Column(
        children: [
          TextFormField(
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
              onPressed: isBusy ? null : onSubmit,
              icon: const Icon(Icons.login_rounded),
              label: const Text('로그인'),
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
