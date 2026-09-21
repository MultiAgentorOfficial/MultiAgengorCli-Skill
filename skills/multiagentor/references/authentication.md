# Authentication and visible OAuth login

Treat MultiAgentor service authentication and website authentication as separate flows.

## MultiAgentor account

1. Run the live `auth status` operation first. Continue only when login is required.
2. Inspect live help and require `auth oauth`. The current npm CLI uses an OAuth device flow and never asks the Agent for an email, password, token, or device code.
3. Prefer the bundled launcher:

```text
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/start-auth-login.ps1 -CliPath <launcher>
bash scripts/start-auth-login.sh --cli-path <launcher>
```

4. Parse the launcher JSON. `ready: true` means the visible OAuth terminal initialized; it does not mean login succeeded.
5. The CLI requests a device authorization, opens the trusted MultiAgentor authorization page in the user's default browser, and polls for approval. The user completes sign-in and consent in that browser. The Agent must not operate the authorization page or request credentials or codes in chat.
6. Keep the terminal open while the CLI polls. It must show success or failure and wait for Enter before closing.
7. After the user finishes, run `auth status` again from the Agent process. Login succeeds only when the live response contains `authenticated: true`.

If live help does not expose `auth oauth`, run the npm CLI update gate. If it remains unavailable, stop and report the installed version. Never fall back to an email/password command, token argument, environment variable, temporary credential file, clipboard, generated credential script, or shell history.

### Windows behavior

`start-auth-login.ps1` launches Windows PowerShell with `Start-Process`, `-WindowStyle Normal`, `-NoExit`, and `-EncodedCommand`. The encoded command prevents a path containing spaces from being reparsed into broken arguments. It creates a per-session directory under `%LOCALAPPDATA%\MultiAgentorAuth`, writes a non-sensitive `ready` marker after the child console initializes, and waits up to 15 seconds by default.

The session contains `open-login.cmd` as a visible fallback. When readiness times out, the launcher opens its folder in Explorer and returns `ready: false` plus the fallback path. The login window shows success or failure and waits for Enter before closing.

### macOS behavior

`start-auth-login.sh` creates a per-session `login.command` under `~/.multiagentor-auth`, sets the directory and command file to mode `700`, and opens it with `open -a Terminal`. The child writes a non-sensitive readiness marker, runs `auth oauth`, displays the result, and waits for Enter.

macOS and Windows may prevent applications from forcing focus. Treat the readiness marker as proof that the window process initialized, then direct the user to the visible Terminal or PowerShell window if focus stayed elsewhere.

## X/Twitter or other website account

Use a persistent MultiAgentBrowser Profile and launch it visibly through the live CLI. Never use headless mode for login. Do not enter, paste, read, capture, or relay website passwords, one-time codes, recovery codes, security keys, or CAPTCHA answers.

Pause whenever the site requests credentials, verification, consent, or CAPTCHA. Let the user complete those steps inside MultiAgentBrowser. Continue only after the user closes the manual browser, then verify the Profile is released and take a fresh snapshot when the automated run starts.

Do not interpret the browser opening, a successful navigation, or the window closing as proof of website login. Verify the resulting page state during the next visible or supervised browser session.
