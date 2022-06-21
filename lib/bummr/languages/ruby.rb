require 'singleton'

module Bummr
  module Languages
    class Ruby
      include Singleton

      def bisect_command
        "sh -c \"#{install_dependencies_command} && #{test_command}\""
      end

      def detected_language
        :ruby
      end

      def get_package_version(name)
        `bundle list | grep " #{name} "`.split('(')[1].split(')')[0]
      end

      def git_files
        %w( Gemfile Gemfile.lock vendor/cache )
      end

      def install_dependencies_command
        "bundle install"
      end

      def test_command
        ENV["BUMMR_TEST"] || "bundle exec rake"
      end

      def update_command
        "bundle update"
      end

      def outdated_packages(options)
        results = []

        bundle_options =  ""
        bundle_options << " --parseable" if Gem::Version.new(Bundler::VERSION) >= Gem::Version.new("2")
        bundle_options << " --strict" unless options[:all_gems]
        bundle_options << " --group #{options[:group]}" if options[:group]
        bundle_options << " #{options[:gem]}" if options[:gem]

        Open3.popen2("bundle outdated" + bundle_options) do |_std_in, std_out|
          while line = std_out.gets
            gem = parse_gem_from(line)

            if gem && (options[:all_gems] || gemfile_contains(gem[:name]))
              results.push gem
            end
          end
        end

        results
      end

      private

      def parse_gem_from(line)
        regex = /(?:\s+\* )?(.*) \(newest (\d[\d\.]*\d)[,\s] installed (\d[\d\.]*\d)[\),\s]/.match line

        unless regex.nil?
          { name: regex[1], newest: regex[2], installed: regex[3] }
        end
      end

      def gemfile_contains(gem_name)
        /gem ['"]#{gem_name}['"]/.match gemfile
      end

      def gemfile
        `cat Gemfile`
      end
    end
  end
end
