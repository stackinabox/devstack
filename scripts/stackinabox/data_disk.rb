# -*- mode: ruby -*-
# vi: set ft=ruby :

VM_NAME ||= ENV['VM_NAME'] || "stackinabox"

HOME = ENV['HOME']
DATA_DISK_PATH = "#{HOME}/VirtualBox VMs"
FileUtils.mkdir_p DATA_DISK_PATH
DATA_DISK_FILE = "#{DATA_DISK_PATH}/box-disk2.vmdk"
DATA_DISK_FORMAT = 'VMDK'
DATA_DISK_SIZE = 500 * 1024

def vbox_manage?
  @vbox_manage ||= ! `which VBoxManage`.chomp.empty?
end

def vm_boxes
  boxes = {}
  if vbox_manage?
    vms = `VBoxManage list vms`
    vms.split("\n").each do |vm|
      x = vm.split
      k = x[0].gsub('"','')      # vm name
      v = x[1].gsub(/[{}]/,'')   # vm UUID
      boxes[k] = v
    end
  end
  boxes
end

def vm_exists?
  vm_boxes[VM_NAME] ? true : false
end

def vm_info
  vm_exists? ? `VBoxManage showvminfo #{VM_NAME}` : ''
end

def vm_uuid
  vm_boxes[VM_NAME]
end

def vm_state
  case vm_exists?
  when true
    vm_state = vm_info.split("\n").select {|f| f =~ /^State:/}.first || ''
    vm_state.split[1]
  when false
    ''
  end
end

def vm_running?
  vm_state == "running"
end

def vm_start
  case vm_exists?
  when true
    cmd = "VBoxManage startvm #{VM_NAME}"
    vm_running? ? true : system(cmd)
  when false
    false
  end
end

def vm_stop
  case vm_exists?
  when true
    cmd = "VBoxManage controlvm #{VM_NAME} poweroff"
    vm_running? ? system(cmd) : true
  when false
    # it is 'stopped' if it doesn't exist, but
    # this return value is the status of this operation.
    false
  end
end

# Try to identify the data disk UUID;
# this can be done whether the vm exists or not.
def data_disk_uuid
  @data_disk_uuid ||= begin
    data_disk_uuid = nil
    if vbox_manage? && data_disk_created?
      hdds = `VBoxManage list hdds`.split("\n\n")
      hd = hdds.select {|d| d =~ /#{DATA_DISK_FILE}/ }
      if hd.length == 1
        fields = hd.first.split("\n")
        uuid = fields.select {|f| f =~ /^UUID:/ }.first
        data_disk_uuid = uuid.split[1]
      end
    end
    data_disk_uuid
  end
end

# Is the data disk attached to the vm?
def data_disk_attached?
  vm_info =~ /#{DATA_DISK_FILE}/ ? true : false
end

# Try to attach data disk, if necessary
def data_disk_attach
  data_disk_create
  if vm_exists? && ! data_disk_attached?
    vm_stop
    cmd = [
      'VBoxManage storageattach ' + vm_uuid,
      '--storagectl "SATA Controller"',
      '--port 1',
      '--device 0',
      '--type hdd',
      '--medium ', DATA_DISK_FILE
    ].join(' ')
    if system(cmd)
      puts 'Attached virtual data disk:'
      puts "File: #{DATA_DISK_FILE}"
      puts "UUID: #{data_disk_uuid}"
    end
  end
end

# Try to detach data disk
def data_disk_detach
  vm_stop
  if vm_exists? && data_disk_attached?
    cmd = [
      'VBoxManage storageattach ' + vm_uuid,
      '--storagectl "SATA Controller"',
      '--port 1',
      '--device 0',
      '--type hdd',
      '--medium none'
    ].join(' ')
    if system(cmd) && ! data_disk_attached?
      puts 'Detached virtual data disk:'
      puts "File: #{DATA_DISK_FILE}"
    end
  end
  ! data_disk_attached?
end

# Does the data disk exist?
def data_disk_created?
  File.exist?(DATA_DISK_FILE)
end

# Try to identify the data disk UUID
def data_disk_create
  if ! data_disk_created? && vbox_manage?
    cmd = [
      'VBoxManage createhd',
      '--filename ' + DATA_DISK_FILE,
      '--format ' + DATA_DISK_FORMAT,
      '--size ' + DATA_DISK_SIZE.to_s
    ].join(' ')
    if system(cmd) && data_disk_created?
      puts 'Created virtual data disk:'
      puts "File: #{DATA_DISK_FILE}"
      puts "UUID: #{data_disk_uuid}"
      puts "SIZE: #{DATA_DISK_SIZE}"
    end
  end
  data_disk_created?
end
