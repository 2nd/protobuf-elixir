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
    |> Enum.sort_by(fn {_name, tag, _opts} -> tag end)
    |> Enum.reject(fn {_name, _tag, opts} -> not Keyword.has_key?(opts, :type) end)
    |> Enum.map(fn {name, tag, opts} ->
      special_type = Enum.find([:enum, :map], fn type -> opts[type] end)
      type = case special_type == nil do
        true -> opts[:type]
        false -> special_type
      end

      if opts[:repeated] do
        fnum = Encoder.encode_fnum(tag, :embedded)
        quote do
          Generator.encode_repeated_field(unquote(fnum), unquote(type), struct.unquote(name), unquote(opts))
        end
      else
        fnum = Encoder.encode_fnum(tag, type)
        quote do
          Generator.encode_field( unquote(fnum), unquote(type), struct.unquote(name), unquote(opts))
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

  def encode_field(_fnum, _type, nil, _opts), do: <<>>
  def encode_field(_fnum, :bool, false, _opts), do: <<>>
  def encode_field(_fnum, :int32, 0, _opts), do: <<>>
  def encode_field(_fnum, :int64, 0, _opts), do: <<>>
  def encode_field(_fnum, :uint32, 0, _opts), do: <<>>
  def encode_field(_fnum, :uint64, 0, _opts), do: <<>>
  def encode_field(_fnum, :sint32, 0, _opts), do: <<>>
  def encode_field(_fnum, :sint64, 0, _opts), do: <<>>
  def encode_field(_fnum, :fixed32, 0, _opts), do: <<>>
  def encode_field(_fnum, :fixed64, 0, _opts), do: <<>>
  def encode_field(_fnum, :sfixed32, 0, _opts), do: <<>>
  def encode_field(_fnum, :sfixed64, 0, _opts), do: <<>>
  def encode_field(_fnum, :float, 0, _opts), do: <<>>
  def encode_field(_fnum, :float, 0.0, _opts), do: <<>>
  def encode_field(_fnum, :double, 0, _opts), do: <<>>
  def encode_field(_fnum, :double, 0.0, _opts), do: <<>>

  def encode_field(fnum, :bool, true, _opts) do
    [fnum, <<1>>]
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

  def encode_field(_fnum, :int32, 0, _opts), do: <<>>
  def encode_field(_fnum, :int64, 0, _opts), do: <<>>
  def encode_field(_fnum, :uint32, 0, _opts), do: <<>>
  def encode_field(_fnum, :uint64, 0, _opts), do: <<>>
  def encode_field(_fnum, :sint32, 0, _opts), do: <<>>
  def encode_field(_fnum, :sint64, 0, _opts), do: <<>>
  def encode_field(_fnum, :fixed32, 0, _opts), do: <<>>
  def encode_field(_fnum, :fixed64, 0, _opts), do: <<>>
  def encode_field(_fnum, :sfixed32, 0, _opts), do: <<>>
  def encode_field(_fnum, :sfixed64, 0, _opts), do: <<>>
  def encode_field(_fnum, :float, 0, _opts), do: <<>>
  def encode_field(_fnum, :float, 0.0, _opts), do: <<>>
  def encode_field(_fnum, :double, 0, _opts), do: <<>>
  def encode_field(_fnum, :double, 0.0, _opts), do: <<>>
  def encode_field(_fnum, :string, <<>>, _opts), do: <<>>
  def encode_field(_fnum, :bytes, <<>>, _opts), do: <<>>

  def encode_field(fnum, :int32, val, _opts) when val <= @int32_max and val >= @int32_min do
    [fnum, Encoder.encode_type(:int32, val)]
  end

  def encode_field(fnum, :int64, val, _opts) when val <= @int64_max and val >= @int64_min do
    [fnum, Encoder.encode_type(:int64, val)]
  end

  def encode_field(fnum, :uint32, val, _opts) when val <= @uint32_max and val >= 0 do
    [fnum, Encoder.encode_type(:uint32, val)]
  end

  def encode_field(fnum, :uint64, val, _opts) when val <= @uint64_max and val >= 0 do
    [fnum, Encoder.encode_type(:uint64, val)]
  end

  def encode_field(fnum, :sint32, val, _opts) when val <= @int32_max and val >= @int32_min do
    [fnum, Encoder.encode_type(:sint32, val)]
  end

  def encode_field(fnum, :sint64, val, _opts) when val <= @int64_max and val >= @int64_min do
    [fnum, Encoder.encode_type(:sint64, val)]
  end

  def encode_field(fnum, :fixed32, val, _opts) when val <= @uint32_max and val >= 0 do
    [fnum, Encoder.encode_type(:fixed32, val)]
  end

  def encode_field(fnum, :fixed64, val, _opts) when val <= @uint64_max and val >= 0 do
    [fnum, Encoder.encode_type(:fixed64, val)]
  end

  def encode_field(fnum, :sfixed32, val, _opts) when val <= @int32_max and val >= @int32_min do
    [fnum, Encoder.encode_type(:sfixed32, val)]
  end

  def encode_field(fnum, :sfixed64, val, _opts) when val <= @int64_max and val >= @int64_min do
    [fnum, Encoder.encode_type(:sfixed64, val)]
  end

  def encode_field(fnum, :float, val, _opts) when is_number(val) do
    [fnum, Encoder.encode_type(:float, val)]
  end

  def encode_field(fnum, :double, val, _opts) when is_number(val) do
    [fnum, Encoder.encode_type(:double, val)]
  end

  def encode_field(fnum, type, %{__struct__: _} = val, _opts) do
    encoded = type.encode(val)
    byte_size = :erlang.iolist_size(encoded)
    [fnum, Encoder.encode_varint(byte_size), encoded]
  end

  def encode_field(fnum, type, val, _opts) do
    [fnum, encode_value(type, val)]
  end

  def encode_repeated_field(_fnum, _type, nil, _opts) do
    <<>>
  end

  def encode_repeated_field(_fnum, :map, map, _opts) when map_size(map) == 0 do
    <<>>
  end

  # TODO: This can be much optimized
  # TODO: Why can't this (or repeated bytes and repeated strings) be packed?
  #       it this a pbuf rule, or a bug in the library's decoder?
  def encode_repeated_field(fnum, :map, map, opts) do
    type = opts[:type]
    Enum.reduce(map, [], fn {key, value}, acc ->
      encoded = type.encode(struct(type, %{key: key, value: value}))
      [[fnum, byte_size(encoded), encoded] | acc]
    end)
  end

  # not sure why these need to be special
  def encode_repeated_field(fnum, type, enum, _opts) when type in [:bytes, :string] do
    Enum.reduce(enum, [], fn value, acc ->
      [acc, fnum, encode_value(type, value)]
    end)
  end

  def encode_repeated_field(fnum, type, map, _opts) do
    encoded = Enum.reduce(map, [], fn value, acc ->
      [acc, encode_value(type, value)]
    end)
    byte_size = :erlang.iolist_size(encoded)
    [fnum, Encoder.encode_varint(byte_size), encoded]
  end

  defp encode_value(type, value) do
    Encoder.encode_type(type, value)
  end
end
