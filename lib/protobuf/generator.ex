defmodule Protobuf.Generator do
  @moduledoc """
  Generates speed-optimized encode/1 and decode/1 functions for structs.

  This option only works for proto3. It is enabled via the `generators: true`
  option:


      defmodule My Message
        use Protobuf, generators: true, syntax: :proto3
        ...
      end

  And using `protoc`:

      protoc - --elixir_out=generators=true:./proto/

  This feature is experimental
  """

  alias Protobuf.Encoder

  @doc false
  defmacro __before_compile__(env) do
    fields = Module.get_attribute(env.module, :fields)
    |> Enum.sort_by(fn {name, tag, opts} -> tag end)
    |> Enum.reject(fn {_name, _tag, opts} -> not Keyword.has_key?(opts, :type) end)
    |> Enum.map(fn {name, tag, opts} ->
      special_type = Enum.find([:enum, :map], fn type -> opts[type] end)
      type = case special_type == nil do
        true -> opts[:type]
        false -> special_type
      end

      if opts[:repeated] do
        quote do
          Generator.encode_repeated_field(unquote(tag), unquote(type), struct.unquote(name), unquote(opts))
        end
      else
        quote do
          Generator.encode_field( unquote(tag), unquote(type), struct.unquote(name), unquote(opts))
        end
      end
    end)

    quote location: :keep do
      def encode_to_iodata(struct) do
        alias Protobuf.Generator
        [unquote_splicing(fields)]
      end

      def encode(struct) do
        :erlang.iolist_to_binary(encode_to_iodata(struct))
      end

      def decode(data) do
        # TODO
        Protobuf.Decoder.decode(data, __MODULE__)
      end
    end
  end

  def encode_field(_tag, _type, nil, _opts), do: <<>>
  def encode_field(_tag, :bool, false, _opts), do: <<>>
  def encode_field(_tag, :int32, 0, _opts), do: <<>>
  def encode_field(_tag, :int64, 0, _opts), do: <<>>
  def encode_field(_tag, :uint32, 0, _opts), do: <<>>
  def encode_field(_tag, :uint64, 0, _opts), do: <<>>
  def encode_field(_tag, :sint32, 0, _opts), do: <<>>
  def encode_field(_tag, :sint64, 0, _opts), do: <<>>
  def encode_field(_tag, :fixed32, 0, _opts), do: <<>>
  def encode_field(_tag, :fixed64, 0, _opts), do: <<>>
  def encode_field(_tag, :sfixed32, 0, _opts), do: <<>>
  def encode_field(_tag, :sfixed64, 0, _opts), do: <<>>
  def encode_field(_tag, :float, 0, _opts), do: <<>>
  def encode_field(_tag, :float, 0.0, _opts), do: <<>>
  def encode_field(_tag, :double, 0, _opts), do: <<>>
  def encode_field(_tag, :double, 0.0, _opts), do: <<>>

  def encode_field(tag, :bool, true, _opts) do
    [Encoder.encode_fnum(tag, :bool), <<1>>]
  end

  @int32_max 2_147_483_647
  @int32_min -2_147_483_648
  @int64_max 9_223_372_036_854_775_807
  @int64_min -9_223_372_036_854_775_808

  @uint32_max 4_294_967_295
  @uint64_max 18_446_744_073_709_551_615

  def encode_field(_tag, _type, nil, _opts) do
    <<>>
  end

  def encode_field(_tag, :int32, 0, _opts), do: <<>>
  def encode_field(_tag, :int64, 0, _opts), do: <<>>
  def encode_field(_tag, :uint32, 0, _opts), do: <<>>
  def encode_field(_tag, :uint64, 0, _opts), do: <<>>
  def encode_field(_tag, :sint32, 0, _opts), do: <<>>
  def encode_field(_tag, :sint64, 0, _opts), do: <<>>
  def encode_field(_tag, :fixed32, 0, _opts), do: <<>>
  def encode_field(_tag, :fixed64, 0, _opts), do: <<>>
  def encode_field(_tag, :sfixed32, 0, _opts), do: <<>>
  def encode_field(_tag, :sfixed64, 0, _opts), do: <<>>
  def encode_field(_tag, :float, 0, _opts), do: <<>>
  def encode_field(_tag, :float, 0.0, _opts), do: <<>>
  def encode_field(_tag, :double, 0, _opts), do: <<>>
  def encode_field(_tag, :double, 0.0, _opts), do: <<>>
  def encode_field(_tag, :string, <<>>, _opts), do: <<>>
  def encode_field(_tag, :bytes, <<>>, _opts), do: <<>>

  def encode_field(tag, :int32, val, _opts) when val <= @int32_max and val >= @int32_min do
    [Encoder.encode_fnum(tag, :int32), Encoder.encode_type(:int32, val)]
  end

  def encode_field(tag, :int64, val, _opts) when val <= @int64_max and val >= @int64_min do
    [Encoder.encode_fnum(tag, :int64), Encoder.encode_type(:int64, val)]
  end

  def encode_field(tag, :uint32, val, _opts) when val <= @uint32_max and val >= 0 do
    [Encoder.encode_fnum(tag, :uint32), Encoder.encode_type(:uint32, val)]
  end

  def encode_field(tag, :uint64, val, _opts) when val <= @uint64_max and val >= 0 do
    [Encoder.encode_fnum(tag, :uint64), Encoder.encode_type(:uint64, val)]
  end

  def encode_field(tag, :sint32, val, _opts) when val <= @int32_max and val >= @int32_min do
    [Encoder.encode_fnum(tag, :sint32), Encoder.encode_type(:sint32, val)]
  end

  def encode_field(tag, :sint64, val, _opts) when val <= @int64_max and val >= @int64_min do
    [Encoder.encode_fnum(tag, :sint64), Encoder.encode_type(:sint64, val)]
  end

  def encode_field(tag, :fixed32, val, _opts) when val <= @uint32_max and val >= 0 do
    [Encoder.encode_fnum(tag, :fixed32), Encoder.encode_type(:fixed32, val)]
  end

  def encode_field(tag, :fixed64, val, _opts) when val <= @uint64_max and val >= 0 do
    [Encoder.encode_fnum(tag, :fixed64), Encoder.encode_type(:fixed64, val)]
  end

  def encode_field(tag, :sfixed32, val, _opts) when val <= @int32_max and val >= @int32_min do
    [Encoder.encode_fnum(tag, :sfixed32), Encoder.encode_type(:sfixed32, val)]
  end

  def encode_field(tag, :sfixed64, val, _opts) when val <= @int64_max and val >= @int64_min do
    [Encoder.encode_fnum(tag, :sfixed64), Encoder.encode_type(:sfixed64, val)]
  end

  def encode_field(tag, :float, val, _opts) when is_number(val) do
    [Encoder.encode_fnum(tag, :float), Encoder.encode_type(:float, val)]
  end

  def encode_field(tag, :double, val, _opts) when is_number(val) do
    [Encoder.encode_fnum(tag, :double), Encoder.encode_type(:double, val)]
  end

  def encode_field(tag, type, %{__struct__: _} = val, _opts) do
    encoded = type.encode(val)
    byte_size = :erlang.iolist_size(encoded)
    [Encoder.encode_fnum(tag, :embedded), Encoder.encode_varint(byte_size), encoded]
  end

  def encode_field(tag, type, val, _opts) do
    [Encoder.encode_fnum(tag, type), encode_value(type, val)]
  end

  def encode_repeated_field(_tag, _type, nil, _opts) do
    <<>>
  end

  def encode_repeated_field(tag, :map, map, _opts) when map_size(map) == 0 do
    <<>>
  end

  # TODO: This can be much optimized
  def encode_repeated_field(tag, :map, map, opts) do
    type = opts[:type]
    encoded = Enum.reduce(map, [], fn {key, value}, acc ->
      encoded = type.encode(struct(type, %{key: key, value: value}))
      [encoded | acc]
    end)
    byte_size = :erlang.iolist_size(encoded)
    [Encoder.encode_fnum(tag, :embedded), Encoder.encode_varint(byte_size), encoded]
  end

  # not sure why these need to be special
  def encode_repeated_field(tag, type, enum, _opts) when type in [:bytes, :string] do
    Enum.reduce(enum, [], fn value, acc ->
      [Encoder.encode_fnum(tag, :embedded), encode_value(type, value)]
    end)
  end

  def encode_repeated_field(tag, type, map, _opts) do
    encoded = Enum.reduce(map, [], fn value, acc ->
      [acc, encode_value(type, value)]
    end)
    byte_size = :erlang.iolist_size(encoded)
    [Encoder.encode_fnum(tag, :embedded), Encoder.encode_varint(byte_size), encoded]
  end

  defp encode_value(type, value) do
    Encoder.encode_type(type, value)
  end
end
