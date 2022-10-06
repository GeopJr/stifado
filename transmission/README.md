# transmission-rpc bindings

```crystal
require "transmission"

foo = Client.new("http://127.0.0.1", user: "test", pass: "1234")
p foo.post("session-get", {"fields" => ["version"]}.to_json)
```
