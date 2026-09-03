# User instructions

- This and other systems get their configuration from the user's git-tracked chezmoi repo (`~/.local/share/chezmoi`, see [[machine-config-repo]]) — whenever we edit a config file there, ask if I want to save it; if I say yes, save the changes, commit, and push, then watch CI for a secrets leak and notify me if one is found.

## Coding conventions

- Guard clauses first: put validation/error checks at the top of a function and exit early (`if (bad) return err;` / `if (bad) throw ...;` depending on language/project convention) rather than nesting the happy path inside conditionals.
- One function per purpose, but avoid trivial pass-through wrappers that just rename a single call with no added logic (e.g. `openFile(path) { return fopen(path); }`) — a function should earn its abstraction, not just relabel an existing one.
- Group related functions under a shared namespace instead of scattering them: e.g. in OOP, `create`/`deactivate`/`delete` for an account go together on one `Account` class (as `Account.create`, `Account.deactivate`, etc.), with the noun on the class/module and short verbs as the method names — not `createAccount`/`deactivateAccount` as loose top-level functions.
- No catch-all `Utils`/`Helpers` classes or files. A utility function belongs on the class/module named for what it does — e.g. an `encrypt` helper goes on an `Encrypt` class, not dumped in a generic `Utils`.

### Error handling by language

- C/C++: return the actual data as the function's return value; report errors via an `err` out-parameter (pointer) — `NULL`/`nullptr` on success, pointing to the error info when one occurred. Avoid exceptions in C++ for this.
- JS/TS: prefer promises that resolve to a `(data, error)` pair instead of throwing/rejecting — `error` is `null`/`undefined` on success, populated on failure. Caller checks `error` rather than wrapping in `try/catch`.
- Java: keep exceptions, but use typed/custom exceptions per operation rather than generic ones — e.g. a user-creation failure throws `UserCreationException`, carrying the reason it failed and wrapping the underlying cause (e.g. a DB connection failure) as its cause/sub-exception, not just a bare `Exception("failed")`.
- Scala: prefer `Either[Error, T]` (or `Try[T]` when wrapping something that already throws) over exceptions — idiomatic Scala and composes with `map`/`flatMap`.
- Other languages: follow the guard-clause rule above — `return err` or `throw`, whichever is idiomatic for that language/project.

## Microservices / observability

- Set up Prometheus metrics for services by default.
- Use a standardized ("omologated") log format across services — structured JSON logs — and always include the trace ID in every log line so a request can be followed across service boundaries.
- When a service calls another microservice (e.g. checkout calling inventory to check stock), log the call's execution time, the calling service's name, and the trace ID — so cross-service latency is visible and attributable.
