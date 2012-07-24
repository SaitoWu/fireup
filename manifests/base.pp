# variables
$username = 'deployer'
$usergroup = 'admin'
$appname = 'example'
$mysql_root_password = "root"
$ruby_version = "ruby-1.9.3-p194"
$nginx_server_name = "localhost"
$app_root = "/home/$username/$appname"
$upstream_socket_file = "/tmp/$appname/unicorn.sock"
$nginx_root = "/home/$username/$appname/public/index.htm"

# user
user { $username:
  managehome => true,
  ensure     => present,
  shell      => "/bin/bash",
  gid        => $usergroup,
  home       => "/home/$username"
}

# rvm ruby
include rvm

rvm::system_user { $username: ; }

rvm_system_ruby { $ruby_version:
  ensure => present,
  default_use => true;
}

rvm_gem { 'bundler':
  ensure => installed,
  ruby_version => $ruby_version,
  require => Rvm_system_ruby[ $ruby_version ];
}

# mysql
class { 'mysql::ruby': }
class { 'mysql::server':
  config_hash => { 'root_password' => $mysql_root_password }
}

# unicorn
file { "/etc/init.d/unicorn":
  mode => "755",
  ensure => "present",
  content => template('base/unicorn.sh.erb');
}

# nginx
package { 'nginx':
  ensure => present;
}

file { "/etc/nginx/sites-enabled/default":
  ensure => absent;
}

file { "/etc/nginx/sites-enabled/$appname":
  ensure  => file,
  content => template('base/nginx.conf.erb'),
  require => Package['nginx'];
}

service { "nginx":
  ensure     => running,
  enable     => true,
  hasstatus  => true,
  hasrestart => true,
  subscribe  => File["/etc/nginx/sites-enabled/$appname"],
  require    => Package['nginx']
}
