require "jwt"
require "./jwt_obj/*"

module JWT
  # Converter for moving `Time` objects to epoch time
  module EpochConverter
    extend self

    def to_json(value : Time, builder : JSON::Builder)
      builder.scalar(value.epoch)
    end
  end

  # Class representing the various possible JWT claims
  class Claims
    JSON.mapping(
      expiration: {key: "exp", type: Time?, converter: EpochConverter},
      not_before: {key: "nbf", type: Time?, converter: EpochConverter},
      issued_at: {key: "iat", type: Time?, converter: EpochConverter},
      issuer: {key: "iss", type: String?},
      audience: {key: "aud", type: String | Array(String) | Nil},
      subject: {key: "sub", type: String?},
      id: {key: "jti", type: String?}
    )

    def initialize(@expiration = nil, @not_before = nil, issued_at = nil,
                   @issuer = nil, @audience = nil, @subject = nil, @id = nil)
    end

    # Creates a series of setters so the claims object can be used in
    # a "DSL"-style way
    {% for attribute in {"expiration", "not_before", "issued_at", "issuer", "audience", "subject", "id"} %}
      # Sets the `{{attribute.id}}` property of this claim
      def {{attribute.id}}(value)
        @{{attribute.id}} = value
      end
    {% end %}
  end

  # Mixin for including methods to encode objects with JWT claims in a user
  # friendly way
  module Token
    getter claims = Claims.new

    # Encodes this object with the given `key` and `algorithm`.
    # Accepts a block that is yielded with a `Claims` instance, so you can use the
    # DSL setters to set claim properties.
    #
    # ```
    # struct Session
    #   include JWT::Token
    #
    #   JSON.mapping(foo: String)
    #
    #   def initialize(@foo)
    #   end
    # end
    #
    # session = Session.new("bar")
    # encoded = session.encode("secret", "none) do
    #   issued_at Time.now
    #   issuer "z64"
    #   audience ["GitHub", "snapcase"]
    # end
    #
    # JWT.decode(encoded, "secret", "none")
    # #=> {{"foo" => "bar", "iat" => 1507264921, "iss" => "z64", "aud" => ["GitHub", "snapcase"]}, {"typ" => "JWT", "alg" => "none"}}
    def encode(key : String, algorithm : String)
      with claims yield
      JWT.encode(self, key, algorithm)
    end

    # Combines to `#to_json` result of the including class with the
    # `#to_json` result of a `Claims` instance, using two `IO::Memory`.
    def to_json
      io = IO::Memory.new
      result_io = IO::Memory.new

      object_string = super(io)
      object_end = io.pos
      claims_string = claims.to_json(io)

      io.rewind

      IO.copy(io, result_io, object_end - 1)
      result_io.write(", ".to_slice)
      io.skip(2)
      IO.copy(io, result_io)

      result_io.to_s
    end
  end
end

