module Bummr
  class Bisecter
    include Singleton

    MAX_BISECTS=100

    def bisect
      stop_tag = Bummr::Check.instance.stop_tag
      start_tag = Bummr::Check.instance.start_tag

      system("git tag #{stop_tag}")
      puts "Created tag #{stop_tag}".color(:green)

      system(Bummr::Language.install_dependencies_command)
      system("git bisect start")
      system("git bisect bad")
      system("git bisect good #{start_tag}")


      MAX_BISECTS.times do
        puts "Bad commits found! Bisecting...".color(:red)

        sha = nil

        Open3.popen2e("git bisect run #{Bummr::Language.bisect_command}") do |_std_in, std_out_err|
          while line = std_out_err.gets
            puts line

            sha_regex = Regexp::new("(.*) is the first bad commit\n").match(line)
            unless sha_regex.nil?
              sha = sha_regex[1]
            end

            if line == "bisect run success\n"
              if RECURSIVE_BISECT
                system("git checkout #{stop_tag}")
                system("git tag -D #{stop_tag}")
                output = `git rebase --onto #{sha}^ #{sha}` #pluck out that commit
                if $?.success?
                  puts "Plucked out commit #{sha}".color(:red)
                else
                  puts "Unable to plucked out commit #{sha}".color(:red)
                  puts output.color(:yellow)
                  exit 1
                end
                system("git tag #{stop_tag}")
              else
                Bummr::Remover.instance.remove_commit(sha)
              end
            end
          end
        end

        return unless sha or RECURSIVE_BISECT
      end
    end
  end
end
