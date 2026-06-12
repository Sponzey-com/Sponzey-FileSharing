enum TransitionDisposition { transitioned, noOp, warning, failure }

class TransitionIssue {
  const TransitionIssue({required this.code, required this.message});

  final String code;
  final String message;
}

class TransitionEffect {
  const TransitionEffect(this.name, {this.metadata = const {}});

  final String name;
  final Map<String, Object?> metadata;
}

class TransitionResult<TState> {
  const TransitionResult({
    required this.state,
    required this.disposition,
    this.effects = const [],
    this.issue,
  });

  final TState state;
  final TransitionDisposition disposition;
  final List<TransitionEffect> effects;
  final TransitionIssue? issue;

  bool get didTransition => disposition == TransitionDisposition.transitioned;

  bool get isFailure => disposition == TransitionDisposition.failure;

  factory TransitionResult.transitioned(
    TState state, {
    List<TransitionEffect> effects = const [],
  }) {
    return TransitionResult<TState>(
      state: state,
      disposition: TransitionDisposition.transitioned,
      effects: effects,
    );
  }

  factory TransitionResult.noOp(TState state, {TransitionIssue? issue}) {
    return TransitionResult<TState>(
      state: state,
      disposition: TransitionDisposition.noOp,
      issue: issue,
    );
  }

  factory TransitionResult.warning(
    TState state, {
    required TransitionIssue issue,
  }) {
    return TransitionResult<TState>(
      state: state,
      disposition: TransitionDisposition.warning,
      issue: issue,
    );
  }

  factory TransitionResult.failure(
    TState state, {
    required TransitionIssue issue,
  }) {
    return TransitionResult<TState>(
      state: state,
      disposition: TransitionDisposition.failure,
      issue: issue,
    );
  }
}

abstract interface class StateMachine<TState, TEvent> {
  TransitionResult<TState> transition(TState state, TEvent event);
}
