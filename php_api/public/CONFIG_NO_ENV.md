# TNPSC backend configuration (no .env required)

This project is configured for hosting where a `.env` file is not available.

## NVIDIA AI

1. Revoke the NVIDIA key that was previously pasted/exposed.
2. Create a NEW NVIDIA Build API key.
3. Open `src/Config/Secrets.php` on the server.
4. Replace:

`PASTE_NEW_NVIDIA_API_KEY_HERE`

with the new key.

The code uses `google/gemma-4-31b-it` for AI and Current Affairs translation.

## Current Affairs

The auto-fetcher now uses official PIB RSS feeds only:
- PIB Chennai Tamil
- PIB National English

Tamil PIB content is used directly; English PIB content is translated to Tamil by Gemma 4.

## Important

Do not paste an NVIDIA API key into the APK or Git repository.
The `.htaccess` blocks direct web access to `src/` and `php_api/`.
