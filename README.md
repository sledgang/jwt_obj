# jwt_obj

`jwt_obj` adds a high level mixin for your classes for easily encoding your objects with JWT claims.

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  jwt_obj:
    github: y32/jwt_obj
```

## Usage

```crystal
require "jwt_obj"

struct Session
  include JWT::Token

  JSON.mapping(foo: String)

  def initialize(@foo)
  end
end

session = Session.new("bar")
encoded = session.encode("secret", "none) do
  issued_at Time.now
  issuer "z64"
  audience ["GitHub", "snapcase"]
end

JWT.decode(encoded, "secret", "none")
#=> {{"foo" => "bar", "iat" => 1507264921, "iss" => "z64", "aud" => ["GitHub", "snapcase"]}, {"typ" => "JWT", "alg" => "none"}}
```

## Contributors

- [z64](https://github.com/z64) Zac Nowicki - creator, maintainer
