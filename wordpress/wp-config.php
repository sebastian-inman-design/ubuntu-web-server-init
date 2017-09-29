<?php
/**
 * The base configuration for WordPress
 *
 * The wp-config.php creation script uses this file during the
 * installation. You don't have to use the web site, you can
 * copy this file to "wp-config.php" and fill in the values.
 *
 * This file contains the following configurations:
 *
 * * MySQL settings
 * * Secret keys
 * * Database table prefix
 * * ABSPATH
 *
 * @link https://codex.wordpress.org/Editing_wp-config.php
 *
 * @package WordPress
 */

// ** MySQL settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
define('DB_NAME', '%DATABASE%');

/** MySQL database username */
define('DB_USER', '%USERNAME%');

/** MySQL database password */
define('DB_PASSWORD', '%MYSQL_PASSWORD%');

/** MySQL hostname */
define('DB_HOST', 'localhost');

/** Database Charset to use in creating database tables. */
define('DB_CHARSET', 'utf8mb4');

/** The Database Collate type. Don't change this if in doubt. */
define('DB_COLLATE', '');

/**#@+
 * Authentication Unique Keys and Salts.
 *
 * Change these to different unique phrases!
 * You can generate these using the {@link https://api.wordpress.org/secret-key/1.1/salt/ WordPress.org secret-key service}
 * You can change these at any point in time to invalidate all existing cookies. This will force all users to have to log in again.
 *
 * @since 2.6.0
 */

 define('AUTH_KEY',         'mux:_v~9C=*XzYkqP>glIP5-:=1|ZH.o92h{=7h:aO&>t~eR+hPY<mYij0q~YU6@');
 define('SECURE_AUTH_KEY',  'd!a-@l=~=.9:-vy9l7p7[lUzi{57m!IEzDCUJ`M|/xrcICAo_5:!hqa+b``lYu%N');
 define('LOGGED_IN_KEY',    '<rnVt3e-w1_ ]kvO]qi,ITZW.xc9O?]|b:=tN[Px%bYY_s!>duDk(y_<hFhaEB_#');
 define('NONCE_KEY',        ':,2(jz6qMn~dkP-n)vA|!=){}w`-3$=Kpb+8q^^r`QSW)>!wR<Pg_>vZ9m2;Y>Qd');
 define('AUTH_SALT',        '|i:B&ejBovRrL 9_=^m7?#~&h-K/[9:~J+ rW8r/[uwsu=mc!RKt ^KiaRJf*C/7');
 define('SECURE_AUTH_SALT', '5#~Npj1 fu:E&cqbTMdg{F8JNf{:6cU#D]C<,4 #KY|=!-ZNw!O~K-6AIh_2;hCu');
 define('LOGGED_IN_SALT',   '8;<4Tn6w[xWyO:26_j!.i^Wc=MQVa]!{y-3fMx+z8-l@^L!%Y.riak%FnNyuKG|~');
 define('NONCE_SALT',       'h~ `QEW2*R_(=8W:ZzF&P,!VNx^4AuSV|s#$MZ+-PhKTf53#9Xd=k2-`9n?xT@hy');

/**#@-*/

/**
 * WordPress Database Table prefix.
 *
 * You can have multiple installations in one database if you give each
 * a unique prefix. Only numbers, letters, and underscores please!
 */
$table_prefix  = 'seeds_';

/**
 * For developers: WordPress debugging mode.
 *
 * Change this to true to enable the display of notices during development.
 * It is strongly recommended that plugin and theme developers use WP_DEBUG
 * in their development environments.
 *
 * For information on other constants that can be used for debugging,
 * visit the Codex.
 *
 * @link https://codex.wordpress.org/Debugging_in_WordPress
 */
define('WP_DEBUG', false);
define('DISABLE_WP_CRON', true);

/* That's all, stop editing! Happy blogging. */

/** Absolute path to the WordPress directory. */
if ( !defined('ABSPATH') )
	define('ABSPATH', dirname(__FILE__) . '/');


/* Define SFTP login credentials */

define('FS_METHOD',  'ssh');
define('FTP_PRIKEY', '/home/%USERNAME%/.ssh/id_rsa');
define('FTP_PUBKEY', '/home/%USERNAME%/.ssh/id_rsa.pub');
define('FTP_BASE',   '/home/%USERNAME%/%SITE_DOMAIN%/public');
define('FTP_PASS',   '%SSH_PASSWORD%');
define('FTP_HOST',   'localhost:22');
define('FTP_USER',   '%USERNAME%');


/** Sets up WordPress vars and included files. */
require_once(ABSPATH . 'wp-settings.php');
