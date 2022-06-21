require 'open3'
require 'singleton'
require 'bundler'

module Bummr
  class Outdated
    include Singleton

    def outdated_packages(options = {})
      Bummr::Language.outdated_packages(options)
    end
  end
end
