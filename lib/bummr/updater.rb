module Bummr
  class Updater
    include Log
    include Scm

    def initialize(outdated_gems)
      @outdated_gems = outdated_gems
    end

    def update_gems
      puts "Updating outdated gems".color(:green)

      check_git_config

      @outdated_gems.each_with_index do |pkg, index|
        update_gem(pkg, index)
      end
    end

    def update_gem(pkg, index)
      puts "Updating #{pkg[:name]}: #{index+1} of #{@outdated_gems.count}"
      system("#{Bummr::Language.update_command} #{pkg[:name]}")

      updated_version = updated_version_for(pkg)

      if (updated_version)
        message = "Update #{pkg[:name]} from #{pkg[:installed]} to #{updated_version}"
      else
        message = "Update dependencies for #{pkg[:name]}"
      end

      if pkg[:installed] == updated_version
        log("#{pkg[:name]} not updated")
        return
      end

      if pkg[:newest] != updated_version
        log("#{pkg[:name]} not updated from #{pkg[:installed]} to latest: #{pkg[:newest]}")
      end

      Bummr::Language.git_files.each do |file|
        git.add(file)
      end
      git.commit(message)
    end

    def updated_version_for(pkg)
      begin
        Bummr::Language.get_package_version(pkg[:name])
      rescue Error
      end
    end

    private

    def check_git_config
      bail = false

      %w( user.name user.email ).each do |conf|
        `git config #{conf}`
        unless $?.success?
          puts "Missing git config '#{conf}'"
          bail = true
        end
      end

      exit 1 if bail
    end
  end
end

