# Bounded navigation image evidence

Use only when the fixed scenario explicitly accepts visual evidence for an otherwise unknown navigation state. A definitive structured true or false takes its normal branch; do not seek an image to overturn it. Complete applicable bounded local supplementation first.

Discover session.screenshot and session.screenshot.navigation. Require already-granted screenshot permission and the allowed action. The first implementation supports only visible text-only navigation/tab/tablist refs; it rejects unsafe image/canvas/frame or sensitive regions. It is not a general full-page screenshot or coordinate-click tool.

Send one screenshot request with current ref and a stable verificationId for this state check. The CLI caps attempts at two per verificationId and eight per Run; scenario recovery/time limits can be stricter and never reset. Unsafe/failed attempts consume the budget. Do not change the identifier to bypass limits.

Actually open the returned local image pixels using the host file/image reader. Record target state=true/false/unknown, visible marker, path/hash and associated Run/page/generation/time. Receiving a path or a successful screenshot response is not visual verification. No external OCR/model service or upload is added.

Images are non-atomic observations and create no refs. Navigation, scrolling, target changes, stale images, unreadability, ambiguity or conflicting structured evidence invalidate a favorable conclusion. Reobserve once within the same budget; persistent uncertainty takes the scenario's safe stop/skip branch. Obtain current structured refs before any subsequent action.

X v1.6 permits only for-you-selected. Likes, follows and unfollows require current same-target structured post-state; a navigation image cannot prove those effects, server persistence or overall success. Never rewrite a terminal result from an image inspected after closure. Missing permission/capability or image-reader support preserves unknown without escalating or using another browser driver.
