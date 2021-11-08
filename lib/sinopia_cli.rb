# frozen_string_literal: true

require 'thor'
require 'resource'

# Base of the CLI
class SinopiaCli < Thor
  def self.exit_on_failure?
    true
  end

  desc 'resource SUBCOMMAND ...ARGS', 'commands for resources'
  subcommand 'resource', Resource
end
