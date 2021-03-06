# frozen_string_literal: true

module Appsignal
  # System environment detection module.
  #
  # Provides useful methods to find out more about the host system.
  #
  # @api private
  module System
    LINUX_TARGET = "linux".freeze
    MUSL_TARGET = "linux-musl".freeze
    FREEBSD_TARGET = "freebsd".freeze
    GEM_EXT_PATH = File.expand_path("../../../ext", __FILE__).freeze

    def self.heroku?
      ENV.key? "DYNO".freeze
    end

    # Detect agent and extension platform build
    #
    # Used by `ext/extconf.rb` to select which build it should download and
    # install.
    #
    # Use `export APPSIGNAL_BUILD_FOR_MUSL=1` if the detection doesn't work
    # and to force selection of the musl build.
    #
    # @api private
    # @return [String]
    def self.agent_platform
      return MUSL_TARGET if force_musl_build?

      host_os = RbConfig::CONFIG["host_os"].downcase
      local_os =
        case host_os
        when /#{LINUX_TARGET}/
          LINUX_TARGET
        when /darwin/
          "darwin"
        when /#{FREEBSD_TARGET}/
          FREEBSD_TARGET
        else
          host_os
        end
      if local_os =~ /linux/
        ldd_output = ldd_version_output
        return MUSL_TARGET if ldd_output.include? "musl"
        ldd_version = extract_ldd_version(ldd_output)
        if ldd_version && versionify(ldd_version) < versionify("2.15")
          return MUSL_TARGET
        end
      end

      local_os
    end

    # Returns whether or not the musl build was forced by the user.
    #
    # @api private
    def self.force_musl_build?
      %w[true 1].include?(ENV["APPSIGNAL_BUILD_FOR_MUSL"])
    end

    # @api private
    def self.versionify(version)
      Gem::Version.new(version)
    end

    # @api private
    def self.ldd_version_output
      `ldd --version 2>&1`
    end

    # @api private
    def self.extract_ldd_version(string)
      ldd_version = string.match(/\d+\.\d+/)
      ldd_version && ldd_version[0]
    end

    # @api private
    def self.jruby?
      RUBY_PLATFORM == "java"
    end

    # @api private
    def self.ruby_2_or_up?
      versionify(RUBY_VERSION) >= versionify("2.0")
    end
  end
end
