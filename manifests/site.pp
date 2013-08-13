require boxen::environment
require homebrew
require gcc

Exec {
  group       => 'staff',
  logoutput   => on_failure,
  user        => $luser,

  path => [
    "${boxen::config::home}/rbenv/shims",
    "${boxen::config::home}/rbenv/bin",
    "${boxen::config::home}/rbenv/plugins/ruby-build/bin",
    "${boxen::config::home}/homebrew/bin",
    '/usr/bin',
    '/bin',
    '/usr/sbin',
    '/sbin'
  ],

  environment => [
    "HOMEBREW_CACHE=${homebrew::config::cachedir}",
    "HOME=/Users/${::luser}"
  ]
}

File {
  group => 'staff',
  owner => $luser
}

Package {
  provider => homebrew,
  require  => Class['homebrew']
}

Repository {
  provider => git,
  extra    => [
    '--recurse-submodules'
  ],
  require  => Class['git'],
  config   => {
    'credential.helper' => "${boxen::config::bindir}/boxen-git-credential"
  }
}

Service {
  provider => ghlaunchd
}

Homebrew::Formula <| |> -> Package <| |>

  # Homebrew::tap to get dupes
  define homebrew::tap (
    $ensure = present,
  ) {
    if $ensure == 'present' {
      exec { "homebrew_tap_${name}":
        command => "brew tap ${name}",
        unless  => "brew tap | grep ${name}",
      }
    } else {
      exec { "homebrew_untap_${name}":
        command => "brew untap ${name}",
        onlyif  => "brew tap | grep ${name}",
      }
    }
  }
 
  # Homebrew dupes to get rsync 3
  homebrew::tap { 'homebrew/dupes': }
  # Homebrew dupes to get rsync 3
  homebrew::tap { 'josegonzalez/php': }

node default {
  # core modules, needed for most things
  include dnsmasq
  include git
  include hub
  include nginx

  # node versions
#  include nodejs::v0_4
#  include nodejs::v0_6
#  include nodejs::v0_8
  include nodejs::v0_10

  # default ruby versions
#  include ruby::1_9_3
  include ruby::2_0_0

  # common, useful packages
  package {
    [
      'ack',
      'findutils',
      'gnu-tar'
    ]:
  }

  file { "${boxen::config::srcdir}/our-boxen":
    ensure => link,
    target => $boxen::config::repodir
  }

#  include property_list_key
#  include osx

#  homebrew::tap { 'josegonzalez/php':
#     source => 'https://github.com/josegonzalez/homebrew-php',
#   }
 
  # Rsync 3 from homebrew dupes
  package { 'homebrew/dupes/rsync':
    require => Homebrew::Tap['homebrew/dupes']
  }

  package {
    [ 'mysql',
      'postgresql',
      'mongodb',
      'redis',
      'fish',
      'php53 --with-pgsql --with-fpm',
      'php53-xdebug',
      'php53-intl',
      'wget',
      'pbzip2',
      'rbenv',
      'ruby-build',
    ]:
  }

package { 'RubyMine':
	ensure => installed,
	source => 'http://download.jetbrains.com/ruby/RubyMine-5.4.3.dmg',
	provider => appdmg
}
#package { 'PHPStorm EAP':
#  ensure => installed,
#  source => 'http://download.jetbrains.com/webide/PhpStorm-EAP-130.1293.dmg',
#  provider => appdmg
#}

package { 'PhpStorm':
	ensure => installed,
	source => 'http://download.jetbrains.com/webide/PhpStorm-6.0.3.dmg',
	provider => appdmg
}
package { 'Textual':
	ensure => installed,
	source => 'http://www.codeux.com/textual/private/downloads/builds/trial-versions/Textual-Trial-g441bee9.zip',
	provider => compressed_app
}
package { 'Sublime Text 3 build 3047':
  ensure => installed,
  source => 'http://c758482.r82.cf2.rackcdn.com/Sublime%20Text%20Build%203047.dmg',
  provider => appdmg
}
package { 'Dropbox':
  ensure => installed,
  source => 'https://d1ilhw0800yew8.cloudfront.net/client/Dropbox%202.0.26.dmg',
  provider => appdmg
}
package { 'Alfred':
  ensure => installed,
  source => 'http://cachefly.alfredapp.com/Alfred_2.0.6_203.zip',
  provider => compressed_app
}
package { 'iTerm2':
  ensure => installed,
  source => 'http://www.iterm2.com/downloads/beta/iTerm2-1_0_0_20130624.zip',
  provider => compressed_app
}
package { 'iStat Menus':
  ensure => installed,
  source => 'http://s3.amazonaws.com/bjango/files/istatmenus4/istatmenus4.06.zip',
  provider => compressed_app
}
package { 'OpenOffice 3.4.1':
  ensure => installed,
  source => 'http://downloads.sourceforge.net/project/openofficeorg.mirror/stable/3.4.1/Apache_OpenOffice_incubating_3.4.1_MacOS_x86_install_en-US.dmg',
  provider => compressed_app
}
package { 'Adium':
  ensure => installed,
  source => 'http://downloads.sourceforge.net/project/adium/Adium_1.5.7.dmg',
  provider => appdmg
}
package { 'Rdio':
  ensure => installed,
  source => 'http://www.rdio.com/media/static/desktop/mac/Rdio.dmg',
  provider => appdmg
}
package { 'Little Snitch':
  ensure => installed,
  source => 'http://www.obdev.at/downloads/LittleSnitch/LittleSnitch-3.1.1.dmg',
  provider => appdmg
}
exec { 'SHOW ALL FILES':
  command => 'defaults write com.apple.Finder AppleShowAllFiles YES',
  user => akreps
}
exec { 'git setup':
  command => 'git config --global user.name "Andrew Kreps"',
#  user => akreps
}
exec { 'git setup2':
  command => 'git config --global user.email andrew.kreps@gmail.com',
#  user => akreps
}
    

exec { 'postgres init':
  command => 'initdb /opt/boxen/homebrew/var/postgres -E utf8',
  user => akreps,
  require => Package['postgresql']
}
exec { 'postgres plist symlinks':
  command => 'ln -sfv /opt/boxen/homebrew/opt/postgresql/*.plist ~/Library/LaunchAgents',
  user => akreps,
  require => Exec['postgres init']
}
exec { 'postgres start':
  command => 'launchctl load ~/Library/LaunchAgents/homebrew.mxcl.postgresql.plist',
  user => akreps,
  require => Exec['postgres plist symlinks']
}

  # do not fail if FDE is not enabled
#  if $::root_encrypted == 'no' {
#    fail('Please enable full disk encryption and try again')
#  }
  file { "/Users/akreps/src/black-pepper":
      ensure => "directory",
  }
  file { "/Users/akreps/logs":
      ensure => "directory",
  }

  repository {
    'black pepper':
      source   => 'git@github.com:Athletepath/black-pepper',
      path     => '/Users/akreps/src/black-pepper',
      provider => 'git'
  }

  repository {
    'square peg':
      source   => 'git@github.com:Athletepath/square-peg',
      path     => '/Users/akreps/src/square-peg',
      provider => 'git'
  }

  repository {
    'athletepath':
      source   => 'git@github.com:Athletepath/Athletepath',
      path     => '/Users/akreps/src/athletepath',
      provider => 'git'
  }

  repository {
    'dotfiles':
      source   => 'git@github.com:onewheelskyward/dotfiles',
      path     => '/Users/akreps/src/dotfiles',
      provider => 'git'
  }
  repository {
    'browse':
      source   => 'git@github.com:primatelabs/browse',
      path     => '/Users/akreps/src/browse',
      provider => 'git'
  }
  osx_chsh { $::luser:
    shell   => '/opt/boxen/homebrew/bin/fish',
    require => Package['fish'],
  }

  file_line { 'add fish to /etc/shells':
    path    => '/etc/shells',
    line    => "${boxen::config::homebrewdir}/bin/fish",
    require => Package['fish'],
  }
  exec { 'start located':
    command => 'launchctl load -w /System/Library/LaunchDaemons/com.apple.locate.plist',
    user => root
  }
  file { '/opt/boxen/homebrew/etc/nginx/nginx.conf':
    ensure  => link,
    mode    => '0755',
    target  => "/Users/akreps/src/dotfiles/nginx.conf",
    require => Repository["/Users/akreps/src/dotfiles"],
  }
  file { '/opt/boxen/homebrew/etc/nginx/server.crt':
    ensure  => link,
    mode    => '0755',
    target  => "/Users/akreps/src/dotfiles/server.crt,
    require => Repository["/Users/akreps/src/dotfiles"],
  }
  file { '/opt/boxen/homebrew/etc/nginx/server.key':
    ensure  => link,
    mode    => '0755',
    target  => "/Users/akreps/src/dotfiles/server.key",
    require => Repository["/Users/akreps/src/dotfiles"],
  }
  file { '/opt/boxen/homebrew/etc/php/5.3/php.ini':
    ensure  => link,
    mode    => '0755',
    target  => "/Users/akreps/src/dotfiles/php.ini",
    require => Package['php53 --with-pgsql --with-fpm']
  }
  file { '/opt/boxen/homebrew/etc/php/5.3/php-fpm.conf':
    ensure  => link,
    mode    => '0755',
    target  => "/Users/akreps/src/dotfiles/php-fpm.conf",
    require => Package['php53 --with-pgsql --with-fpm']
  }
  file { '/opt/boxen/homebrew/etc/php/5.3/ext-xdebug.ini':
    ensure  => link,
    mode    => '0755',
    target  => "/Users/akreps/src/dotfiles/ext-xdebug.ini",
#    require => Repository["/Users/akreps/src/dotfiles"],
    require => Package['php53 --with-pgsql --with-fpm']
  }
  file { '/Users/akreps/.config':
    ensure => directory,
    mode => '0755'
  }
  file { '/Users/akreps/.config/fish':
    ensure => directory,
    mode => '0755',
    require => File['/Users/akreps/.config']
  }
  file { '/Users/akreps/.config/fish/config.fish':
    ensure  => link,
    mode    => '0755',
    target  => "/Users/akreps/src/dotfiles/config.fish",
#    require => Repository["/Users/akreps/src/dotfiles"],
    require => File['/Users/akreps/.config/fish']
  }
  file { '/Users/akreps/.config/fish/functions':
    ensure  => link,
    mode    => '0755',
    target  => "/Users/akreps/src/dotfiles/functions",
#    require => Repository["/Users/akreps/src/dotfiles"],
    require => File['/Users/akreps/.config/fish']
  }

## Athletepath Setup
  file { '/Users/akreps/src/athletepath/app/cache':
    ensure => directory,
    require => Repository['/Users/akreps/src/athletepath']
  }
  file { '/Users/akreps/src/athletepath/app/log':
    ensure => directory,
    require => Repository['/Users/akreps/src/athletepath']
  }
#chmod a+w app/cache/ app/logs/
#chmod a+x app/console
  exec { 'Athletepath: create parameters.yml file':
    command => 'cp /Users/akreps/src/athletepath/app/config/parameters.yml.dist /Users/akreps/src/athletepath/app/config/parameters.yml',
    user => akreps, 
   require => Repository['/Users/akreps/src/athletepath']
  }
  exec { 'get_composer':
    command => 'cd /Users/akreps/src/athletepath ; curl -Ss http://getcomposer.org/installer | php',
    user => akreps,
    require => Package['php53 --with-pgsql --with-fpm']
    }
#  exec { 'run composer':
#    command => 'cd /Users/akreps/src/athletepath ; php composer.phar',
#    user => akreps
#    }
  exec { 'run composer install':
    command => 'cd /Users/akreps/src/athletepath ; php composer.phar install --optimize-autoloader',
    user => akreps,
    require => Exec["get_composer"]
  }

  exec { 'create athletepath db':
    command => 'createdb athletepath',
    user => akreps
  }  
  exec { 'echo sandbox.athletepath.com':
    command => 'echo 127.0.0.1 sandbox.athletepath.com >> /etc/hosts',
    user => root
  }
#  exec {"load-repos":
#    command =>"git clone git@github.com:Athletepath/black-pepper /Users/akreps/",
#    require => Package["git-core"],
#  }
}
