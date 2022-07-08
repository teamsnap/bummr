module Bummr
  class Bisecter
    include Singleton

    def bisect
      puts "Bad commits found! Bisecting...".color(:red)

      stop_tag = Bummr::Check.instance.stop_tag
      system("git tag #{stop_tag}")
      puts "Created tag #{stop_tag}".color(:green)

      system(Bummr::Language.install_dependencies_command)
      system("git bisect start")
      system("git bisect bad")
      system("git bisect good #{Bummr::Check.instance.start_tag}")

      Open3.popen2e("git bisect run #{Bummr::Language.bisect_command}") do |_std_in, std_out_err|
        while line = std_out_err.gets
          puts line

          sha_regex = Regexp::new("(.*) is the first bad commit\n").match(line)
          unless sha_regex.nil?
            sha = sha_regex[1]
          end

          if line == "bisect run success\n"
            puts "RUN SUCCESS?"
            Bummr::Remover.instance.remove_commit(sha)
          end
        end
      end
    end
  end
end
