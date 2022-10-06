require "option_parser"

module Stifado
  APP_VERSION = {{read_file("#{__DIR__}/../../shard.yml").split("version: ")[1].split("\n")[0]}}

  # Responsible for parsing ARGV.
  class CLI
    getter android : Bool = true
    getter desktop : Bool = true
    getter db : String = ENV.fetch("STIFADO_DB", "")
    getter split : Bool = true
    getter dest : Path = Path["data"]
    getter mirror : Mirror? = nil
    getter overwrite : Bool = true
    getter split_limit : Int32 = 5_000_000
    getter locales : String | Array(String) = "EN-US"

    def initialize(args : Array(String) = ARGV)
      parse(args)
    end

    private def parse(args : Array(String))
      OptionParser.parse args do |opts|
        opts.banner = <<-BANNER
        STIFADO v#{APP_VERSION}
        Usage: stifado [arguments]
        Examples:
            STIFADO_DB=mongodb://user:pass@0.0.0.0:27017 stifado
            stifado -d mongodb://user:pass@0.0.0.0:27017
            stifado --no-android
            stifado --no-desktop --no-split
            stifado -o ./bianries
            stifado -m eff
        Arguments:
        BANNER

        opts.on("-d DATABASE", "--db=DATABASE", "Database url") do |database|
          @db = database
        end
        opts.on("-o OUTPUT", "--out=OUTPUT", "Binary destination") do |output|
          path = Path[output]
          @dest = path
        end
        opts.on("-m MIRROR", "--mirror=MIRROR", "Use a mirror. Available: #{Stifado::Mirror.names}") do |mirror|
          @mirror = Stifado::Mirror.parse?(mirror)
        end
        opts.on("-l LIMIT", "--limit=LIMIT", "Amount of *bytes* per part. Default: 5MB") do |limit|
          i = limit.to_i?
          abort "\"#{limit}\" is not a number" if i.nil?
          @split_limit = i
        end
        opts.on("--locales=LOCALES", "Locales to download seperated by a comma or 'ALL'. Default: en-US") do |locales|
          upcased_locales = locales.upcase
          @locales = locales.includes?(',') ? upcased_locales.split(',') : upcased_locales
        end
        opts.on("--no-overwrite", "Disable overwriting builds if they already exist") do
          @overwrite = false
        end
        opts.on("--no-android", "Disable grabbing Android builds") do
          @android = false
        end
        opts.on("--no-desktop", "Disable grabbing Desktop builds") do
          @desktop = false
        end
        opts.on("--no-split", "Disable splitting binaries into parts") do
          @split = false
        end
        opts.on("-h", "--help", "Shows this help") do
          puts opts
          exit 0
        end

        opts.invalid_option do |flag|
          STDERR.puts "#{flag} is not a valid option."
          STDERR.puts opts
          exit(1)
        end
      end
    end
  end
end
