module Spec
  module Sudo
    def self.present?
      @which_sudo ||= (`which sudo`.chomp rescue '')
      !@which_sudo.empty?
    end

    def self.test_sudo?
      present? && ENV['BUNDLER_SUDO_TESTS']
    end

    def sudo(cmd)
      raise "sudo not present" unless Sudo.present?
      sys_exec("sudo #{cmd}")
    end

    def chown_system_gems_to_root
      sudo "chown -R root #{system_gem_path}"
    end
  end
end
