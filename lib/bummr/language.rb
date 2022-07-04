require 'singleton'

module Bummr
  class Language
    include Singleton

    PASSTHROUGH_METHODS = %i(
      bisect_command get_package_version git_files
      install_dependencies_command outdated_packages test_command update_command
    )

    @language = nil

    class << self
      Bummr::Language::PASSTHROUGH_METHODS.each do |method|
        define_method method do |*args|
          Bummr::Language.instance.send(method, *args)
        end
      end
    end

    Bummr::Language::PASSTHROUGH_METHODS.each do |method|
      define_method method do |*args|
        @language.send(method, *args)
      end
    end

    def initialize
      @language = detect_language
    end

    private

    def detect_language
      case ENV['BUMMR_LANG']
      when 'hex', 'elixir'
        Bummr::Languages::Elixir.instance
      when 'go', 'golang'
        Bummr::Languages::Golang.instance
      when 'ruby'
        Bummr::Languages::Ruby.instance
      else
        if File.exists?('mix.exs')
          Bummr::Languages::Elixir.instance
        elsif File.exists?('go.mod')
          Bummr::Languages::Golang.instance
        elsif File.exists?('Gemfile') or ENV['BUMMR_LANG'].nil?
          Bummr::Languages::Ruby.instance
        else
          raise "Unknown language"
        end
      end
    end
  end
end
