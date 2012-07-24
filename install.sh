# **install.sh** is a script executed after Debian/Ubuntu has been
# installed and restarted. There is no user interaction so all commands must
# be able to run in a non-interactive mode.
#
# If any package install time questions need to be set, you can use
# `preeseed.cfg` to populate the settings.

### Setup Variables

# The version of Ruby to be installed supporting the Chef and Puppet gems
ruby_ver="1.8.7-p358"

# The base path to the Ruby used for the Chef and Puppet gems
ruby_home="/opt/ruby"

# Enable truly non interactive apt-get installs
export DEBIAN_FRONTEND=noninteractive

# Determine the platform (i.e. Debian or Ubuntu) and platform version
platform="$(lsb_release -i -s)"
platform_version="$(lsb_release -s -r)"

# Run the script in debug mode
set -x

### Installing Ruby

#### Compiling Ruby

# Currently we must install Ruby 1.8 since Puppet doesn't fully support Ruby
# 1.9 yet.

# Install packages necessary to compile Ruby from source
case "$platform" in
  Debian)
    apt-get -y install build-essential zlib1g-dev libssl-dev \
      libreadline5-dev make curl git-core
    ;;
  Ubuntu)
    apt-get -y install build-essential zlib1g-dev libssl-dev \
      libreadline-dev make curl git-core
    ;;
esac

# Use ruby-build to install Ruby
clone_dir=/tmp/ruby-build-$$
git clone https://github.com/sstephenson/ruby-build.git $clone_dir
$clone_dir/bin/ruby-build "$ruby_ver" "$ruby_home"
rm -rf $clone_dir
unset clone_dir

### Installing Chef and Puppet Gems

# Install prerequisite gems used by Chef and Puppet
${ruby_home}/bin/gem install polyglot net-ssh-gateway mime-types --no-ri --no-rdoc

# Install puppet
${ruby_home}/bin/gem install puppet --no-ri --no-rdoc

# Add the Puppet group so Puppet runs without issue
groupadd puppet

# If a packaged Ruby or RVM is installed then the path to the Chef and Puppet
# binaries will be "lost". To guard against this, we'll add the compiled Ruby's
# bin directory to PATH.
echo "PATH=\$PATH:${ruby_home}/bin" >/etc/profile.d/ruby.sh

### Misc. Tweaks

# Install NFS client
apt-get -y install nfs-common

# Tweak sshd to prevent DNS resolution (speed up logins)
echo 'UseDNS no' >> /etc/ssh/sshd_config

### Clean up

# Remove the build tools to keep things pristine
apt-get -y autoremove
apt-get -y clean

# Removing leftover leases and persistent rules
rm -f /var/lib/dhcp3/*

# Make sure Udev doesn't block our network, see: http://6.ptmc.org/?p=164
rm /etc/udev/rules.d/70-persistent-net.rules
mkdir /etc/udev/rules.d/70-persistent-net.rules
rm -rf /dev/.udev/
rm /lib/udev/rules.d/75-persistent-net-generator.rules

# Add a 2 sec delay to the interface up, to make the dhclient happy
echo "pre-up sleep 2" >> /etc/network/interfaces

### Compress Image Size

# Zero out the free space to save space in the final image
dd if=/dev/zero of=/EMPTY bs=1M
rm -f /EMPTY


### use fire up

puppet apply --modulepath 'manifests/modules' manifests/base.pp

exit

# And we're done.
