Vagrant::Config.run do |config|
  config.vm.box = "oneiric"
  config.vm.box_url = "http://timhuegdon.com/vagrant-boxes/Ubuntu-11.10.box"
  config.vm.forward_port 80, 8080

  config.vm.provision :chef_solo do |chef|
    chef.cookbooks_path = "cookbooks"
    chef.add_recipe("apt")
    chef.add_recipe("build-essential")
    chef.add_recipe("nginx::source")
    chef.add_recipe("redis::source")
    chef.add_recipe("postgresql::client")
    chef.add_recipe("postgresql::server")
  end
end
