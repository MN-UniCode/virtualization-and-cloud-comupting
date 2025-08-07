require 'yaml'

# Load configuration variables
config_file = 'config.yml'

if File.exist?(config_file)
  config = YAML.load_file(config_file)
else
  abort("Error: Configuration file #{config_file} not found!")
end

KEY_FILE_PATH = config['key_file_path']
MYNET = config['mynet']
NUM_TARGET = config['num_target']
PROVIDER = config['provider']
OS = config['os']
KEY_FILE_PATH_UBUNTU = config['key_file_path_ubuntu']

Vagrant.configure("2") do |config|
  (1..NUM_TARGET).each do |i|
    config.vm.define "target#{i}" do |node|
      config.vm.box = "enricorusso/VCCubuntu"
      config.vm.box_version = "24.04.01"   
      
      node.vm.hostname = "target#{i}"
      node.vm.base_mac = "00:0c:29:8b:0a:7#{i}"
      node.vm.base_address = "#{MYNET}.1#{i}"

      node.vm.provider PROVIDER do |v|
        v.gui = true
        v.vmx["displayname"] = "target#{i}"
        v.vmx["memsize"] = "2048"
        v.vmx["numvcpus"] = "2"
      
        # eth0
        v.vmx["ethernet0.present"] = "TRUE"
        v.vmx["ethernet0.addresstype"] = "static"
        v.vmx["ethernet0.address"] = "00:0c:29:8b:0a:7#{i}"
        v.vmx["ethernet0.connectiontype"] = "NAT"
      end  
      if File.exist?(KEY_FILE_PATH)
        node.vm.provision :file, :source => "#{KEY_FILE_PATH}", :destination => "/tmp/id.pub"
        node.vm.provision :shell, :inline => "cat /tmp/id.pub >> ~vagrant/.ssh/authorized_keys", :privileged => false
      end  
      node.vm.provision :shell, :inline => "grep #{MYNET}.1#{i} /etc/hosts || echo '#{MYNET}.1#{i} target#{i}.vcc.local' >> /etc/hosts"  

      if OS == 0
        if File.exist?(KEY_FILE_PATH_UBUNTU)
          node.vm.provision :file, :source => "#{KEY_FILE_PATH_UBUNTU}", :destination => "/tmp/id.pub"
          node.vm.provision :shell, :inline => "cat /tmp/id.pub >> ~vagrant/.ssh/authorized_keys", :privileged => false
        end  
      end

    end
  end

  config.vm.define "VCC-controlnode" do |controlnode|
    config.vm.box = "enricorusso/VCCubuntu"
    config.vm.box_version = "24.04.01"   
  
    controlnode.vm.hostname = "controlnode"
    controlnode.vm.base_mac = "00:0c:29:8b:0a:70"
    controlnode.vm.base_address = "#{MYNET}.10"

    controlnode.vm.provider PROVIDER do |v|
      v.gui = true
      v.vmx["displayname"] = 'VCC-controlnode'
      v.vmx["memsize"] = "1024"
      v.vmx["numvcpus"] = "1"
    
      v.vmx["ethernet0.present"] = "TRUE"
      v.vmx["ethernet0.addresstype"] = "static"
      v.vmx["ethernet0.address"] = "00:0c:29:8b:0a:70"
      v.vmx["ethernet0.connectiontype"] = "NAT"
    end
    if File.exist?(KEY_FILE_PATH)
      controlnode.vm.provision :file, :source => "#{KEY_FILE_PATH}", :destination => "/tmp/id.pub"
      controlnode.vm.provision :shell, :inline => "cat /tmp/id.pub >> ~vagrant/.ssh/authorized_keys", :privileged => false
    end
    if OS == 0
      if File.exist?(KEY_FILE_PATH_UBUNTU)
        controlnode.vm.provision :file, :source => "#{KEY_FILE_PATH_UBUNTU}", :destination => "/tmp/id.pub"
        controlnode.vm.provision :shell, :inline => "cat /tmp/id.pub >> ~vagrant/.ssh/authorized_keys", :privileged => false
      end 
    end 
    controlnode.vm.provision :shell, :inline => "apt-get update; apt-get -y install ansible sshpass make"
    controlnode.vm.provision :shell, :inline => "test -f /home/vagrant/.ssh/id_rsa || ssh-keygen -f /home/vagrant/.ssh/id_rsa -q -P \"\"", :privileged => false
    controlnode.vm.provision :shell, :inline => "grep #{MYNET}.10 /etc/hosts || echo '#{MYNET}.10 controlnode.vcc.local' >> /etc/hosts"    
    controlnode.vm.provision :shell, :inline => "echo -e '[defaults]\nhost_key_checking = False' >> ~/.ansible.cfg", :privileged => false      
  
    (1..NUM_TARGET).each do |i|
      controlnode.vm.provision :shell, :inline => "sshpass -p vagrant ssh-copy-id -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -f vagrant@#{MYNET}.1#{i}", :privileged => false
      controlnode.vm.provision :shell, :inline => "grep #{MYNET}.1#{i} /etc/hosts || echo '#{MYNET}.1#{i} target#{i}.vcc.local' >> /etc/hosts"      
    end
  end
end
