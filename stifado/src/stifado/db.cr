module Stifado
  # Responsible for connecting
  # and pushing to db.
  class Database
    # The db schemas.
    record Binary,
      name : String,
      version : String,
      platform : String,
      path : String,
      sig : String,
      parts : Int32 = 0,
      locale : String = "multi",
      _id : BSON::ObjectId = BSON::ObjectId.new,
      creation_date : Time = Time.utc do
      include BSON::Serializable
      include JSON::Serializable
    end

    record Part,
      name : String,
      version : String,
      platform : String,
      part_no : Int32,
      path : String,
      belongs_to : BSON::ObjectId,
      _id : BSON::ObjectId = BSON::ObjectId.new do
      include BSON::Serializable
      include JSON::Serializable
    end

    getter client
    getter db
    getter collections

    def initialize(db_url : String)
      @client = Mongo::Client.new db_url
      @db = @client["stifado"]
      @collections = {
        binaries: @db["binaries"],
        parts:    @db["parts"],
        # sigs:     DB["sigs"], # Sigs are part of binaries.
      }
    end

    def insert(items : Array(Binary | Part))
      Log.info { "Saving to database..." }

      binaries = items.reject { |x| !x.is_a?(Binary) }
      parts = items.reject { |x| !x.is_a?(Part) }

      @collections[:parts].insert_many(parts) if parts.size > 0

      @collections[:binaries].insert_many(binaries) if binaries.size > 0

      Log.info { "Finished saving to database." }
    end
  end
end
