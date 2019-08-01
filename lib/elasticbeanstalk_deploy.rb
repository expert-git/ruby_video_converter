require "fileutils"
require "open3"
require "optparse"

class ElasticbeanstalkDeploy
  EB_CLI_CONFIG = ".elasticbeanstalk/config.yml".freeze
  ENVIRONMENTS = %w(production production-old staging).freeze

  def initialize(args)
    @args = args
    @options = Options.new
  end

  def call
    parse

    in_current_enviroment do
      validate

      deploy
    end
  end

  private

  attr_reader :args, :options

  Options = Struct.new(:environment_name, :force)
  private_constant :Options
  Error = Class.new(StandardError)
  private_constant :Error
  UnknownError = Class.new(Error)
  private_constant :UnknownError
  UnknownEnvironmentError = Class.new(Error)
  private_constant :UnknownEnvironmentError
  DeployFailedError = Class.new(Error)
  private_constant :DeployFailedError

  def parse
    parser = OptionParser.new do |opts|
      opts.banner = "Usage: bin/deploy [options]"

      opts.on("-e NAME", "--environment-name NAME", ENVIRONMENTS, "Name of the environment to deploy (#{ENVIRONMENTS.join(', ')})") do |v|
        options.environment_name = v
      end

      opts.on("-h", "--help", "Show this help") do |v|
        puts opts

        exit
      end
    end

    parser.parse!(args)

    validate_cli_options
  rescue OptionParser::MissingArgument, OptionParser::InvalidArgument => e
    puts e
    puts parser

    exit
  end

  def validate_cli_options
    msg = []

    msg << "Environment name not given" if options.environment_name.to_s.empty?

    unless msg.empty?
      puts msg.join("\n")

      raise OptionParser::InvalidArgument
    end
  end

  def in_current_enviroment
    FileUtils.ln_sf(current_environment_config, EB_CLI_CONFIG)

    yield
  ensure
    FileUtils.rm_f(EB_CLI_CONFIG)
  end

  def current_environment_config
    "config.yml.#{options.environment_name}".freeze
  end

  def known_eb_environments
    @known_eb_environments ||= fetch_known_eb_environments
  end

  def fetch_known_eb_environments
    command = ["eb", "list"]

    output, status = Open3.capture2(*command)

    raise UnknownError, output unless status.success?

    output.lines.map { |l| l.split(" ").last.strip }
  end

  def validate
    raise UnknownEnvironmentError, options.environment_name unless File.exist?(".elasticbeanstalk/#{current_environment_config}")
  end

  def deploy
    known_eb_environments.each do |env|
      puts "Deploying #{env}\n"

      command = ["eb", "deploy", env]

      system(*command) or raise DeployFailedError
    end
  end
end
