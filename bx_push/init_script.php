<?php
define('NO_KEEP_STATISTIC', true);
define("NOT_CHECK_PERMISSIONS", true);
define("NOT_CHECK_FILE_PERMISSIONS", true);

$_SERVER["DOCUMENT_ROOT"] = __DIR__.'/www';
require_once($_SERVER["DOCUMENT_ROOT"]."/bitrix/modules/main/include/prolog_before.php");

$cfg =file_get_contents('/etc/sysconfig/push-server-multi');
$re = '/SECURITY_KEY=([A-Za-z0-9]+)/m';
preg_match_all($re, $cfg, $matches, PREG_SET_ORDER, 0);
$pushServerKey=$matches[0][1];
\Bitrix\Main\Config\Option::set('pull', 'signature_key', $pushServerKey);
