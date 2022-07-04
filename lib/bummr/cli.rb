BASE_BRANCH = ENV["BASE_BRANCH"] || `git symbolic-ref refs/remotes/origin/HEAD`.chomp.split('/').last || "master"
HEADLESS = ENV["BUMMR_HEADLESS"] || false

module Bummr
  class CLI < Thor
    include Bummr::Log
    include Bummr::Prompt
    include Bummr::Scm

    desc "check", "Run automated checks to see if bummr can be run"
    def check(fullcheck=true)
      Bummr::Check.instance.check(fullcheck)
    end

    desc "update",
      "Update outdated gems, run tests, bisect if tests fail\n\n" +
      "--all: Update indirect dependencies\n" +
      "--group: Specify a group from the Gemfile to update\n" +
      "--gem: Specify a specific gem to update\n" +
      "\n"


    method_option :all, type: :boolean, default: false
    method_option :group, type: :string
    method_option :gem, type: :string

    def update
      system(Bummr::Language.install_dependencies_command)
      display_info

      if yes? "Are you ready to use Bummr? (y/n)"
        check
        log("Bummr update initiated #{Time.now}")

        outdated_packages = Bummr::Outdated.instance.outdated_packages(
          all_gems: options[:all], group: options[:group], gem: options[:gem]
        )

        if outdated_packages.empty?
          puts "No outdated gems to update".color(:green)
        else
          Bummr::Updater.new(outdated_packages).update_gems

          git.rebase_interactive(BASE_BRANCH)
          test
        end
      else
        puts "Thank you!".color(:green)
      end
    end

    desc "test", "Test for a successful build and bisect if necesssary"
    def test
      check(false)

      if yes? "Do you want to test the build now? (y/n)"
        system(Bummr::Language.install_dependencies_command)
        puts "Testing the build!".color(:green)

        if system(Bummr::Language.test_command) == false
          bisect
        else
          puts "Passed the build!".color(:green)
          puts "See log/bummr.log for details".color(:yellow)
        end
      end
    end

    desc "bisect", "Find the bad commit, remove it, test again"
    def bisect
      check(false)

      if yes? "Would you like to bisect in order to find which gem is causing " +
              "your build to break? (y/n)"
        Bummr::Bisecter.instance.bisect
      end
    end

    desc "remove_commit", "Remove a commit from the history"
    def remove_commit(sha)
      Bummr::Remover.instance.remove_commit(sha)
    end

    private

    def display_info
      puts "Bummr #{VERSION}"
      puts "To run Bummr, you must:"
      puts "- Be in the root path of a clean git branch off of " + "#{BASE_BRANCH}".color(:yellow)
      puts "- Have no commits or local changes"
      puts "- Have a 'log' directory, where we can place logs"
      puts "- Have your build configured to fail fast (recommended)"
      puts "- Have locked any Gem version that you don't wish to update in your Gemfile"
      puts "- It is recommended that you lock your versions of `ruby` and `rails` in your `Gemfile`"
      puts "\n"
      puts "Your test command is: " + "'#{Bummr::Language.test_command}'".color(:yellow)
      puts "\n"
      print_received_options
    end

    def print_received_options
      puts "Bummr will run with the following options:"

      options.each do |key, value|
        puts "--#{key.color(:yellow)}: #{value}"
      end

      puts "\nRun `#{"bummr help update".color(:yellow)}` for more information.\n\n"
    end
  end
end
