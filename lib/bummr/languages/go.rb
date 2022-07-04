require 'singleton'

module Bummr
  module Languages
    class Golang
      include Singleton

      def bisect_command
        "sh -c \"#{install_dependencies_command} && #{test_command}\""
      end

      def get_package_version(name)
        `go list -m all | grep "^#{name} "`.split(' ').last
      end

      def git_files
        %w( go.mod go.sum )
      end

      def install_dependencies_command
        "go get"
      end

      def test_command
        ENV["BUMMR_TEST"] || "go test ./..."
      end

      def update_command
        "go get -u"
      end

      def outdated_packages(options)
        results = []

        go_options = ""
        go_options <<
          if options[:all_gems]
            " -m all"
          else
            " -m -f '{{if not .Indirect}}{{.}}{{end}}' all"
          end

        puts "Getting list of outdated packages, this can take a while for golang..."
        Open3.popen2("go list -u" + go_options) do |_std_in, std_out|
          while line = std_out.gets
            if hex = parse_godep_line(line)
              puts line
              results.push hex
            end
          end
        end

        results
      end

      private

      def parse_godep_line(line)
        regex = /(?:\s+\* )?([^\s]+)\s+(v\d[\d\.]*\d[-a-f0-9]*)\s+\[(v\d[\d\.]*\d[-a-f0-9]*)\]/.match(line)

        unless regex.nil? or regex[2] == regex[3]
          { name: regex[1], newest: regex[3], installed: regex[2] }
        end
      end

    end
  end
end
