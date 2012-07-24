Vagrant::Config.run do |config|
  config.vm.box = "precise"
  config.vm.box_url = "http://files.vagrantup.com/precise32.box"
  config.vm.forward_port 80, 8080

  config.vm.provision :puppet do |puppet|
    puppet.manifests_path = "manifests"
    puppet.manifest_file  = "base.pp"
    puppet.module_path    = "manifests/modules"
  end
end
