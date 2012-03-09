#
# defines the base classes that all servers share
#

Exec { path => ["/data/jdk1.7.0_03/bin", "/bin", "/sbin", "/usr/bin",
                "/usr/sbin", "/usr/local/bin", "/usr/local/sbin"],
       environment => "JAVA_HOME=/data/jdk1.7.0_03/",
       logoutput => on_failure
}

class socorro-base {

    file {
        '/etc/profile.d/java.sh':
            owner => root,
            group => root,
            mode => 644,
            ensure => present,
            source => "/vagrant/files/etc_profile.d/java.sh";
            
	'/etc/hosts':
	    owner => root,
	    group => root,
	    mode => 644,
	    ensure => present,
	    source => "/vagrant/files/hosts";

	'/data':
            owner => root,
            group => root,
            mode  => 755,
            ensure => directory;

        '/data/socorro':
            owner => socorro,
            group => socorro,
            mode  => 755,
	    recurse=> false,
	    ensure => directory;

        '/etc/socorro':
            owner => socorro,
            group => socorro,
            mode  => 755,
	    recurse=> false,
	    ensure => directory;

	 '/etc/socorro/socorrorc':
	    ensure => link,
            require => Exec['socorro-install'],
	    target=> "/data/socorro/application/scripts/crons/socorrorc";

	'/etc/rsyslog.conf':
            require => Package[rsyslog],
	    owner => root,
	    group => root,
	    mode => 644,
	    ensure => present,
	    notify => Service[rsyslog],
	    source => "/vagrant/files/rsyslog.conf";

	 'hbase-configs':
            path => "/etc/hbase/conf/",
            recurse => true,
            require => Exec['install-hbase'],
            source => "/vagrant/files/etc_hbase_conf";

# FIXME break this out to separate classes
	 'etc_supervisor':
            path => "/etc/supervisor/conf.d/",
            recurse => true,
            require => [Package['supervisor'], Exec['socorro-install']],
	    notify => Service[supervisor],
            source => "/vagrant/files/etc_supervisor";

        '/var/log/socorro':
            mode  => 644,
	    recurse=> true,
	    ensure => directory;

	'/home/socorro/persistent':
	    owner => socorro,
	    group => socorro,
	    ensure => directory;

    }

    file {
        '/etc/apt/sources.list':
            ensure => file;
    }

    exec {
        '/usr/bin/pip install isodate':
            require => Package['python-pip'],
            logoutput => on_failure;
    }

    exec {
        '/usr/bin/apt-get update':
            alias => 'apt-get-update';
    }

    exec {
        '/usr/bin/curl http://download.oracle.com/otn-pub/java/jdk/7u3-b04/jdk-7u3-linux-x64.tar.gz | tar -C /data -zxf -':
            alias => 'install-oracle-jdk',
            unless => '/usr/bin/file /data/jdk1.7.0_03/',
            require => Package['curl'];
    }   

    package {
        ['rsyslog', 'libcurl4-openssl-dev', 'libxslt1-dev', 'build-essential',
         'supervisor', 'ant', 'python-software-properties', 'vim', 'emacs',
         'python-pip', 'curl', 'git-core']:
            ensure => latest,
            require => Exec['apt-get-update'];
    }

    service {
        supervisor:
            enable => true,
            stop => '/usr/bin/service supervisor force-stop',
            hasstatus => true,
            require => [Package['supervisor'], Service['postgresql'],
                        Exec['setup-schema'], Exec['hbase-schema']],
            subscribe => Exec['socorro-install'],
            ensure => running;

        rsyslog:
            enable => true,
            require => Package['rsyslog'],
            ensure => running;
    }

    group { 'puppet':
        ensure => 'present',
    }
}

class socorro-python inherits socorro-base {

    user { 'socorro':
	ensure => 'present',
	uid => '10000',
	shell => '/bin/bash',
        groups => 'admin',
	managehome => true;
    }

    file {
        '/home/socorro':
	    require => User[socorro],
            owner => socorro,
            group => socorro,
            mode  => 775,
	    recurse=> false,
	    ensure => directory;
    }

    file {
        '/home/socorro/dev':
	    require => File['/home/socorro'],
            owner => socorro,
            group => socorro,
            mode  => 775,
	    recurse=> false,
	    ensure => directory;
    }

# FIXME
#        '/etc/logrotate.d/socorro':
#            ensure => present,
#	    source => $fqdn ? {
#		/sjc1.mozilla.com$/ => "puppet://$server/modules/socorro/stage/etc-logrotated/socorro",
#		default => "puppet://$server/modules/socorro/prod/etc-logrotated/socorro",
#		};
    package {
        ['python-psycopg2', 'python-simplejson', 'subversion', 'libpq-dev',
         'python-virtualenv', 'python-dev']:
            ensure => latest,
            require => Exec['apt-get-update'];
    }

    exec {
        '/usr/bin/make minidump_stackwalk':
            alias => 'minidump_stackwalk-install',
            cwd => '/home/socorro/dev/socorro',
            creates => '/home/socorro/dev/socorro/stackwalk',
            timeout => '3600',
            require => [Package['libcurl4-openssl-dev'],
                        File['/data/socorro'], Package['build-essential'],
                        Package['subversion']],
            user => 'socorro';
    }

    exec {
        '/usr/bin/make install':
            alias => 'socorro-install',
            cwd => '/home/socorro/dev/socorro',
            timeout => '3600',
            require => [Package['ant'], File['/data/socorro'],
                        Exec['minidump_stackwalk-install']],
            logoutput => on_failure,
            user => 'socorro';
    }
}

class socorro-web inherits socorro-base {

    file { '/var/log/httpd':
        owner => root,
        group => root,
        mode  => 755,
        recurse=> true,
        ensure => directory;
    }

    package {
        'apache2':
            ensure => latest,
            require => [Exec['apt-get-update'], Exec['socorro-install']];

        ['libapache2-mod-php5', 'libapache2-mod-wsgi']:
            ensure => latest,
            require => [Exec['apt-get-update'], Package[apache2]];
    }

    service {
        apache2:
            enable => true,
            ensure => running,
            hasstatus => true,
            subscribe => Exec['socorro-install'],
            require => [Package[apache2], Exec[enable-mod-rewrite], 
                        Exec[enable-mod-headers], Exec[enable-mod-ssl],
                        Exec[enable-mod-php5],
                        Package[libapache2-mod-php5], Exec[enable-mod-proxy]];
    }

}

class socorro-php inherits socorro-web {

     file { 
        '/var/log/httpd/crash-stats':
            require => Package[apache2],
            owner => root,
            group => root,
            mode  => 755,
            ensure => directory;

        '/etc/apache2/sites-available/crash-stats':
            require => Package[apache2],
            alias => 'crash-stats-vhost',
            owner => root,
            group => root,
            mode  => 644,
            ensure => present,
	    notify => Service[apache2],
	    source => "/vagrant/files/etc_apache2_sites-available/crash-stats";

        '/var/log/socorro/kohana':
            require => Package[apache2],
            owner => www-data,
            group => www-data,
            mode  => 755,
            ensure => directory;

	'/etc/php.ini':
            require => Package[apache2],
	    owner => root,
	    group => root,
	    mode => 644,
	    ensure => present,
	    notify => Service[apache2],
	    source => "/vagrant/files/php.ini";

        '/data/socorro/htdocs/application/logs':
            require => Exec['socorro-install'],
            owner => socorro,
            group => www-data,
            mode => 664,
            ensure => directory;

# FIXME
#        '/etc/logrotate.d/kohana':
#            ensure => present,
#	    source => $fqdn ? {
#		/sjc1.mozilla.com$/ => "puppet://$server/modules/socorro/stage/etc-logrotated/kohana",
#		default => "puppet://$server/modules/socorro/prod/etc-logrotated/kohana",
#		};

    }

    exec {
        '/usr/sbin/a2ensite crash-stats':
            alias => 'enable-crash-stats-vhost',
            require => File['crash-stats-vhost'],
    }

    exec {
        '/usr/sbin/a2enmod rewrite':
            alias => 'enable-mod-rewrite',
            require => File['crash-stats-vhost'],
    }
    exec {
        '/usr/sbin/a2enmod php5':
            alias => 'enable-mod-php5',
            require => File['crash-stats-vhost'],
    }

    exec {
        '/usr/sbin/a2enmod proxy && /usr/sbin/a2enmod proxy_http':
            alias => 'enable-mod-proxy',
            require => File['crash-stats-vhost'],
    }

    exec {
        '/usr/sbin/a2enmod ssl':
            alias => 'enable-mod-ssl',
            require => File['crash-stats-vhost'],
    }

    exec {
        '/usr/sbin/a2enmod headers':
            alias => 'enable-mod-headers',
            require => File['crash-stats-vhost'],
    }

    service {
        memcached:
            enable => true,
            require => Package['memcached'],
            ensure => running;
    }

    package {
        ['memcached', 'libcrypt-ssleay-perl', 'php5-pgsql', 'php5-curl',
	 'php5-dev', 'php5-tidy', 'php-pear', 'php5-common', 'php5-cli',
	 'php5-memcache', 'php5', 'php5-gd', 'php5-mysql', 'php5-ldap',
         'phpunit']:
            ensure => latest,
            require => Exec['apt-get-update'];
    }
}
