# StartupGate

Runs one application-supplied startup task and renders loading, ready or error
content. The ready value can represent an authenticated session, a signed-out
state or any other app decision. Gicho does not interpret it.

Supply localized loading and error widgets, plus a ready builder. The error
builder receives a retry callback. A retry invalidates earlier completions;
disposing the gate also ignores late results. Recreate the gate with a new key
when account or environment context changes. Startup tasks with external side
effects must handle their own cancellation.

```dart
StartupGate<Session?>(
  load: client.session,
  loadingBuilder: (context) => const StartupSplash(title: 'My app'),
  errorBuilder: (context, error, retry) => TextButton(
    onPressed: retry,
    child: const Text('Try again'),
  ),
  readyBuilder: (context, session) => session == null
      ? const SignInScreen()
      : const HomeScreen(),
)
```
