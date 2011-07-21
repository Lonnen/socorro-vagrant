<?php defined('SYSPATH') or die('No direct script access.');
/**
 * The hostname for backend data access
 */
$config['socorro_hostname'] = 'http://socorro-api/bpapi';

/**
 * Default settings for web service clients
 */
$config['defaults'] = array(
    'connection_timeout' => '3',
    'timeout' => '120'
);

/**
 * Basic Auth Credentials
 * Valid values: FALSE or an assoc array with username and password as keys
 */
$config['basic_auth'] = array('username' => 'example',
                          'password' => 'sekrit');
/**
 * Number of minutes to cache results to the
 * /200911/topcrash/sig/trend/rank/p/${product}/v/${version}/end/${end_date}/duration/${dur}/listsize/${limit}
 * service call.
 * This materialized views is updated every 60 minutes, so we'll cache the results for that long
 */
$config['topcrash_vers_rank_cache_minutes'] = 60;

/**
 * What implementation is used in the Middleware.
 * Can be 'ES' for ElasticSearch or 'PG' for PostgreSQL.
 * Used to hide some unimplemented fields in the UI.
 */
$config['middleware_implementation'] = 'PG';

?>
