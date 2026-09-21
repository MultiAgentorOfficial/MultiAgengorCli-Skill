# Authentication and visible login windows

Treat MultiAgentor service authentication and website authentication as separate flows.

## MultiAgentor account

1. Run the live `auth status` operation first. Continue only when login is required.
2. Inspect `auth login --help`. Accept only a mode that keeps the password out of process arguments, such as `--password-stdin`, an interactive secure prompt, browser OAuth, or a device code.
3. Prefer the bundled launcher:

```text
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/start-auth-login.ps1 -CliPath <launcher>
bash scripts/start-auth-login.sh --cli-path <launcher>
```

4. Parse the launcher JSON. `ready: true` means the visible input window initialized; it does not mean login succeeded.
5. Let the user enter the MultiAgentor email and password in that local window. Never request or type those values in chat.
6. After the user finishes, run `auth status` again from the Agent process. Login succeeds only when the live response contains `authenticated: true`.

If the CLI exposes only `--password <value>`, stop and report that the installed npm version lacks secure login. Do not fall back to a password argument, environment variable, temporary credential file, clipboard, generated script, or shell history.

### Windows behavior

`start-auth-login.ps1` launches Windows PowerShell with `Start-Process`, `-WindowStyle Normal`, `-NoExit`, and `-EncodedCommand`. The encoded command prevents a path containing spaces from being reparsed into broken arguments. It creates a per-session directory under `%LOCALAPPDATA%\MultiAgentorAuth`, writes a non-sensitive `ready` marker after the child console initializes, and waits up to 15 seconds by default.

The session contains `open-login.cmd` as a visible fallback. When readiness times out, the launcher opens its folder in Explorer and returns `ready: false` plus the fallback path. The login window shows success or failure and waits for Enter before closing.

### macOS behavior

`start-auth-login.sh` creates a per-session `login.command` under `~/.multiagentor-auth`, sets the directory and command file to mode `700`, and opens it with `open -a Terminal`. The child uses `read -s`, writes a non-sensitive readiness marker, displays the result, and waits for Enter.

macOS and Windows may prevent applications from forcing focus. Treat the readiness marker as proof that the window process initialized, then direct the user to the visible Terminal or PowerShell window if focus stayed elsewhere.

## X/Twitter or other website account

Use a persistent MultiAgentBrowser Profile and launch it visibly through the live CLI. Never use headless mode for login. Do not enter, paste, read, capture, or relay website passwords, one-time codes, recovery codes, security keys, or CAPTCHA answers.

Pause whenever the site requests credentials, verification, consent, or CAPTCHA. Let the user complete those steps inside MultiAgentBrowser. Continue only after the user closes the manual browser, then verify the Profile is released and take a fresh snapshot when the automated run starts.

Do not interpret the browser opening, a successful navigation, or the window closing as proof of website login. Verify the resulting page state during the next visible or supervised browser session.
