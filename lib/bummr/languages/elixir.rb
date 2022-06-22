require 'singleton'

module Bummr
  module Languages
    class Elixir
      include Singleton

      def bisect_command
        "sh -c \"#{install_dependencies_command} && #{test_command}\""
      end

      def detected_language
        :elixir
      end

      def get_package_version(name)
        `mix deps | grep "^\* #{name} "`.split(' ')[2]
      end

      def git_files
        %w( mix.exs mix.lock )
      end

      def install_dependencies_command
        "mix deps.get"
      end

      def test_command
        ENV["BUMMR_TEST"] || "mix test"
      end

      def update_command
        "mix deps.update"
      end

      def outdated_packages(options)
        results = []

        hex_options = ""
        hex_options << " --all" if options[:all_gems]

        Open3.popen2("mix hex.outdated" + hex_options) do |_std_in, std_out|
          while line = std_out.gets
            if hex = parse_hex_from(line)
              puts line
              results.push hex
            end
          end
        end

        results
      end

      private

      def parse_hex_from(line)
        regex = /(?:\s+\* )?(.*)\s+(\d[\d\.]*\d)\s+(\d[\d\.]*\d)\s.*/.match(line)

        unless regex.nil? or regex[2] == regex[3]
          { name: regex[1], newest: regex[3], installed: regex[2] }
        end
      end

    end
  end
end
