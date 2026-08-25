<?php
namespace App\Config;

/**
 * Local configuration for hosting where no .env file is available.
 *
 * IMPORTANT:
 * - Do NOT put an NVIDIA API key in source control.
 * - The NVIDIA key that was previously exposed must be revoked.
 * - Paste a NEW key into NVIDIA_API_KEY below on the live server only.
 * - This file is PHP, so its values are not printed as source when PHP is
 *   configured normally. Direct access is also blocked by .htaccess.
 */
final class Secrets
{
    public const DB_HOST = 'localhost';
    public const DB_PORT = '3306';
    public const DB_NAME = 'aicazxokw_vetri_tnpsc';
    public const DB_USER = 'aicazxokw_vetri_user';
    public const DB_PASS = 'Prithika@1221';
    public const DB_SSL = false;

    public const JWT_SECRET = 'VetriTNPSC2026JwtSecretKeyChangeThisLater987';
    public const CRON_SECRET = 'VetriTNPSC2026CronKey555';
    public const NVIDIA_API_KEY = 'PASTE_NEW_NVIDIA_API_KEY_HERE';
}
