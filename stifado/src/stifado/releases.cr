module Stifado
  # Responsible for consuming tor's releases.json
  # and manually getting the Android builds.
  class Releases
    class Links
      include JSON::Serializable

      property binary : String
      property sig : String
    end

    class Releases
      include JSON::Serializable

      property tag : String
      property version : String
      property downloads : Hash(String, Hash(String, Links))
    end

    getter desktop : Releases
    getter android : Hash(String, Hash(String, String))
    getter android_version : String

    def initialize
      # Renew if it doesn't exist.
      renew unless File.exists?(RELEASES_JSON)
      @desktop = Releases.from_json(File.read(RELEASES_JSON))

      android_builds = gen_android
      @android = android_builds[0]
      @android_version = android_builds[1]

      # Renew only if a day has passed since the last one.
      # (Useful if the CLI runs as part of a job, to avoid
      # spamming tor's servers)
      last_mod_plus_1_day = File.info(RELEASES_JSON).modification_time + 1.days
      renew if last_mod_plus_1_day.to_unix_ms < Time.local.to_unix_ms
    end

    # Renews/Re-downloads releases.json and parses it.
    def renew
      Log.info { "Renewed releases.json" }
      response = HTTP::Client.get(API)

      if response.status_code == 200
        res = response.body
        File.write(RELEASES_JSON, res)
      else
        res = File.read(RELEASES_JSON)
      end

      @desktop = Releases.from_json(res)
    end

    # Whether a platform + locale is available.
    def available?(platform : String, locale : String) : Bool
      !@desktop.downloads[platform]?.try &.[locale]?.nil?
    end

    # Generates the Android builds by parsing verions.ini.
    def gen_android : Tuple(Hash(String, Hash(String, String)), String)
      hash = Hash(String, Hash(String, String)).new
      version = @desktop.version

      response = HTTP::Client.get(VERSIONS_INI)

      if response.status_code == 200
        ini = INI.parse(response.body)
        version = ini["torbrowser-android-stable"]["version"] if ini["torbrowser-android-stable"]?.try &.["version"]?
      end

      {"aarch64", "armv7", "x86_64", "x86"}.each do |arch|
        hash[arch] = {
          "binary" => "https://dist.torproject.org/torbrowser/#{version}/tor-browser-#{version}-android-#{arch}-multi.apk",
          "sig"    => "https://dist.torproject.org/torbrowser/#{version}/tor-browser-#{version}-android-#{arch}-multi.apk.asc",
        }
      end

      {hash, version}
    end
  end
end
