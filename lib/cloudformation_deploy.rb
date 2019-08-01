require "json"
require "open3"
require "optparse"
require "shellwords"
require "tempfile"
require "yaml"

class CloudformationDeploy
  Error = Class.new(StandardError)
  private_constant :Error
  StackNotFound = Class.new(Error)
  private_constant :StackNotFound
  ExecuteFailed = Class.new(Error)
  private_constant :ExecuteFailed
  S3DeployFailed = Class.new(Error)
  private_constant :S3DeployFailed
  OptionsValidationError = Class.new(Error)
  private_constant :OptionsValidationError

  Options = Struct.new(:command, :stack_name, :environment_name, :force) do
    def stack_name=(value)
      self[:stack_name] = Shellwords.escape(value)
    end

    def environment_name=(value)
      self[:environment_name] = Shellwords.escape(value)
    end
  end
  private_constant :Options

  COMMANDS = %w(create update delete).freeze
  ENVIRONMENTS = %w(production staging).freeze

  def initialize(args)
    @args = args
    @options = Options.new
  end

  def call
    parse

    validate

    path = convert_to_json

    deploy_to_s3

    execute(path)

    wait do
      print_status
    end
  rescue => e
    raise e unless e.is_a?(Error)
  end

  private

  attr_reader :args, :options

  def parse
    parser = OptionParser.new do |opts|
      opts.banner = "Usage: bin/cloudformation-deploy [options]"

      opts.on("-c NAME", "--command NAME", COMMANDS, "Command to execute (#{COMMANDS.join(',')})") do |v|
        options.command = v
      end

      opts.on("-s NAME", "--stack-name NAME", String, "Name of the stack to deploy") do |v|
        options.stack_name = v
      end

      opts.on("-e NAME", "--environment-name NAME", ENVIRONMENTS, "Name of the environment to deploy (#{ENVIRONMENTS.join(',')})") do |v|
        options.environment_name = v
      end

      opts.on("-f", "--force", "Force command without asking for params") do |v|
        options.force = true
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

  def validate
    ensure_stack_exists

    ensure_params_uptodate
  end

  def validate_cli_options
    msg = []

    msg << "Command not given" if options.command.to_s.empty?

    msg << "Stack name not given" if options.stack_name.to_s.empty?

    msg << "Environment name not given" if options.environment_name.to_s.empty?

    unless msg.empty?
      puts msg.join("\n")

      raise OptionParser::InvalidArgument
    end
  end

  def ensure_stack_exists
    return if options.command == "create"

    command = [
      "aws", "cloudformation", "describe-stacks",
      "--stack-name", options.stack_name,
    ]

    _, status = Open3.capture2(*command)

    raise StackNotFound unless status.success?
  end

  def ensure_params_uptodate
    unless File.exist?(params_yaml)
      puts "Download the params file to #{params_yaml} and try again"

      raise OptionsValidationError
    end

    unless options.force
      puts "Are you sure #{params_yaml} is up-to-date (Skip check with --force)? (y/N)"

      unless gets.start_with?("y")
        puts "Update the #{params_yaml} and try again"

        raise OptionsValidationError
      end
    end
  end

  def convert_to_json
    json = Tempfile.new(["cldfrmtn", ".json"])

    params = YAML.load(File.read(params_yaml))

    json.write(JSON.dump(params))

    json.close

    json.path
  end

  def execute(params_json_path)
    command = [
      "aws", "cloudformation",
      "#{options.command}-stack",
      "--stack-name", options.stack_name,
    ]

    unless options.command == "delete"
      command += [
        "--template-url", "https://s3.amazonaws.com/#{s3_path}",
        "--parameters", "file://#{params_json_path}",
        "--capabilities", "CAPABILITY_IAM"
      ]
    end

    _, status = Open3.capture2(*command)

    raise ExecuteFailed unless status.success?
  end

  def deploy_to_s3
    command = [
      "aws",
      "s3",
      "cp",
      template_path,
      "s3://#{s3_path}"
    ]

    _, status = Open3.capture2(*command)

    raise S3DeployFailed unless status.success?
  end

  def wait
    pid = fork { wait_command }

    Thread.new { yield }

    Process.wait(pid)
  end

  def wait_command
    command = [
      "aws", "cloudformation", "wait",
      "stack-#{options.command}-complete",
      "--stack-name", options.stack_name,
    ]

    _, status = Open3.capture2(*command)
    return unless status.success?
  end

  def print_status
    last_id = do_print_status(lines: 10)

    loop do
      last_id = do_print_status(lines: 1, last_id: last_id)

      sleep 2
    end
  end

  def do_print_status(lines:, last_id: "")
    stdout, status = Open3.capture2(
      "aws", "cloudformation", "describe-stack-events",
      "--stack-name", options.stack_name,
      "--max-items", lines.to_s
    )
    return if status && !status.success?

    events = JSON.parse(stdout)

    events["StackEvents"].reverse.each do |event|
      break if event["EventId"] == last_id

      print event.values_at("Timestamp", "ResourceStatus", "ResourceType", "LogicalResourceId").join("\t")
      print "\n"

      last_id = event["EventId"]
     end

    last_id
  end

  def params_yaml
    @params_yaml ||= "cloudformation/elasticbeanstalk_params_#{options.environment_name}.yml"
  end

  def template_path
    File.expand_path("cloudformation/#{template_file}")
  end

  def template_file
    "ElasticBeanstalk_GAFV.template.yml"
  end

  def s3_path
    "gafv-cfn-#{options.environment_name}/#{template_file}"
  end
end
