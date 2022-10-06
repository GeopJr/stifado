require "json"
require "http/client"
require "file_utils"
require "ini"
require "log"

require "cryomongo"

require "./stifado/*"

module Stifado
  extend self

  CONFIG = CLI.new

  API           = "https://aus1.torproject.org/torbrowser/update_3/release/downloads.json"
  RELEASES_JSON = Path[CONFIG.dest, "releases.json"]
  BINARIES      = Path[CONFIG.dest, "browser"]
  VERSIONS_INI  = "https://gitlab.torproject.org/tpo/web/tpo/-/raw/main/databags/versions.ini"

  # Create the BINARIES path.
  Dir.mkdir_p(BINARIES)

  # Mirrors of the tor browser website.
  enum Mirror
    EFF
    CALYX
  end

  # Function that replaces the original url with
  # the provided mirror's.
  def use_mirror(mirror : Mirror, str : String) : String
    repl = case mirror
           in .eff?
             "https://tor.eff.org/dist/"
           in .calyx?
             "https://tor.calyxinstitute.org/dist/"
           end

    str.sub("https://dist.torproject.org/", repl)
  end

  # Downloads the *url* into *dest*.
  # It first saves it into .part
  # until it's finished then gets
  # moved to the dest (without .part).
  # (Used to avoid overwriting files
  # with half-downloaded ones).
  def download_binary(url : String, dest : Path) : Path
    name = url.split('/')[-1]
    path = dest / name
    part = "#{path}.part"
    safe_url = (mirror = CONFIG.mirror).nil? ? url : use_mirror(mirror, url)

    # If overwrite is off and the file exists,
    # return its path.
    if !CONFIG.overwrite && File.exists?(path)
      Log.info { "\"#{path}\" already exists. Skipping." }
      return path
    end

    HTTP::Client.get(safe_url) do |response|
      Log.info { "Started downloading #{safe_url}" }
      File.write(part, response.body_io)
    end
    Log.info { "Finished downloading #{safe_url}" }

    FileUtils.mv(part, path)
    path
  end

  # Responsible for downloading the binaries and creating
  # database entries from an array of links and other
  # metadata.
  def index(links : Array(String), platform : String, dest : Path, version : String, locale = "multi") : Array(Database::Binary | Database::Part)
    res = [] of Database::Binary | Database::Part
    links.each do |link|
      uuid = BSON::ObjectId.new

      end_path = download_binary(link, dest)
      is_sig = end_path.extension == ".asc"

      next if is_sig
      expanded_end_path = end_path.expand
      parts_no = 0

      if CONFIG.split
        splitter = Splitter.new(
          end_path,
          end_path.parent / "parts",
          CONFIG.split_limit
        )

        parts_no = splitter.parts.size

        splitter.parts.each_with_index do |part, i|
          res << Database::Part.new(
            _id: BSON::ObjectId.new,
            name: end_path.basename,
            version: version,
            path: part.expand.to_s,
            part_no: i,
            belongs_to: uuid,
            platform: platform
          )
        end
      end

      res << Database::Binary.new(
        _id: uuid,
        name: end_path.basename,
        version: version,
        path: expanded_end_path.to_s,
        sig: "#{expanded_end_path}.asc",
        locale: locale,
        parts: parts_no,
        platform: platform
      )
    end

    res
  end

  DB       = Database.new CONFIG.db.not_nil!
  RELEASES = Releases.new

  if CONFIG.android
    android_path = BINARIES / RELEASES.android_version / "android"
    Dir.mkdir_p(android_path)

    RELEASES.android.each do |arch, links|
      DB.insert index(links.values, "android-#{arch}", android_path, RELEASES.android_version)
    end
  end

  if CONFIG.desktop
    desktop_path = BINARIES / RELEASES.desktop.version / "desktop"
    Dir.mkdir_p(desktop_path)

    RELEASES.desktop.downloads.each do |platform, v|
      # Filter through the locales.
      # If ALL => return all values.
      # If it's a String => return
      #   the one that matches it.
      # If it's an Array => returm
      #   all the ones in it.
      locales = case CONFIG.locales
                when "ALL"
                  v
                when String
                  v.reject { |x, y| x.upcase != CONFIG.locales }
                when Array(String)
                  v.reject { |x, y| !CONFIG.locales.includes?(x.upcase) }
                end

      next if locales.nil?

      locales.each do |locale, links|
        DB.insert index([links.binary, links.sig], platform, desktop_path, RELEASES.desktop.version, locale)
      end
    end
  end
end
