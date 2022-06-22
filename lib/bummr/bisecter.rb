module Bummr
  class Bisecter
    include Singleton

    def bisect
      puts "Bad commits found! Bisecting...".color(:red)

      system(Bummr::Language.install_dependencies_command)
      system("git bisect start")
      system("git bisect bad")
      system("git bisect good #{BASE_BRANCH}")

      Open3.popen2e("git bisect run #{Bummr::Language.bisect_command}") do |_std_in, std_out_err|
        while line = std_out_err.gets
          puts line

          sha_regex = Regexp::new("(.*) is the first bad commit\n").match(line)
          unless sha_regex.nil?
            sha = sha_regex[1]
          end

          if line == "bisect run success\n"
            Bummr::Remover.instance.remove_commit(sha)
          end
        end
      end
    end
  end
end
