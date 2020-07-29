<?php
define( 'DB_NAME', 'testdb' );
define( 'DB_USER', 'testuser' );
define( 'DB_PASSWORD', 'test_password' );
define( 'DB_HOST', 'localhost' );
define( 'DB_CHARSET', 'utf8mb4' );
define( 'DB_COLLATE', 'utf8mb4_unicode_ci' );
define('FS_METHOD', 'direct');

define('AUTH_KEY',         '`xa]-#H-Zp`E]&$kgpIhK3!wgi@Kv=+:^|d|BjD$+Us_|lurD1%6mk1$:3&M:LE8');
define('SECURE_AUTH_KEY',  '_vju-47Zy{wh+:A-I.H^qP)K9fcVsoRE-|5aAXSEXbk+X`0k,{@:=>9aNF7G4wR:');
define('LOGGED_IN_KEY',    'o<S-5cJ[9sp(>u^]2t/I6Uv1Oo!RD9tM3vGi}!e?Ev+kFHG?fx[#B^/)=hkh.~QK');
define('NONCE_KEY',        ',Y@rl;]UYN]*.H%?u-R9<N[&0td;|&HNvIj}[u%<J/)^.a}2oIz[]u4|&c)JALp-');
define('AUTH_SALT',        'q@%MFM)z,Wt>ZDA`y3])j%O)+6ur|5(seP@z=Ql#`-N=fcRr&n<Eds^F!gX2K8|f');
define('SECURE_AUTH_SALT', 'sw}vyJ~w)8;8aB3P&CU-X/i-;!t17Bx3jxR{lYI^|@-m+Wz;ZZ}&3R6B@Ey+FL.@');
define('LOGGED_IN_SALT',   'Uvi]{u,)2K~&Ox6zjtT,|*ZWr>Y57bGy,$CS0Sc9E9/VvY5+[O-iCZ`p^nM3`{)i');
define('NONCE_SALT',       'AG7,20RS7CE`@g-!tB[VV*m&E-)!t;g5)v1eD|Q5d|@%UiU$5T1v^{w-k ZVeFE~');

$table_prefix = 'wp_';

define( 'WP_DEBUG', false );

if ( ! defined( 'ABSPATH' ) ) {
	define( 'ABSPATH', __DIR__ . '/' );
}

require_once ABSPATH . 'wp-settings.php';