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
        type = case is_struct?(type) do
          true -> {:struct, type}
          false -> type
        end
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

  # awful
  defp is_struct?(type) do
    String.starts_with?(Atom.to_string(type), "Elixir.")
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

  def encode_repeated_field(_fnum, _type, [], _opts) do
    <<>>
  end

  # TODO: Push more of this at compile time. ktype, vtype, kfnum and vfnum can
  # all be derived at compile time. However, as-is, the data is no longer available
  # by the time our generator runs. All we have is the generated KeyValue "Entry"
  # type (which hasn't isn't available to query yet (because it's defined AFTER?))
  def encode_repeated_field(fnum, :map, map, opts) do
    props = opts[:type].__message_props__()

    ktype = props.field_props[1].type
    vtype = props.field_props[2].type

    kfnum = Encoder.encode_fnum(1, ktype)
    vfnum = Encoder.encode_fnum(2, vtype)

    Enum.reduce(map, [], fn {key, value}, acc ->
      encoded = [
        encode_field(kfnum, ktype, key, opts),
        encode_field(vfnum, value_type, value, opts)
      ]
      byte_size = :erlang.iolist_size(encoded)
      [[fnum, byte_size, encoded] | acc]
    end)
  end

  # In proto3, only scalar numeric types are packed.
  def encode_repeated_field(fnum, type, enum, _opts) when type in [:bytes, :string] do
    Enum.reduce(enum, [], fn value, acc ->
      [acc, fnum, encode_value(type, value)]
    end)
  end

  def encode_repeated_field(fnum, {:struct, type}, enum, opts) do
    Enum.reduce(enum, [], fn value, acc ->
      [acc, encode_field(fnum, type, value, opts)]
    end)
  end

  def encode_repeated_field(fnum, type, enum, _opts) do
    encoded = Enum.reduce(enum, [], fn value, acc ->
      [acc, encode_value(type, value)]
    end)
    byte_size = :erlang.iolist_size(encoded)
    [fnum, Encoder.encode_varint(byte_size), encoded]
  end

  defp encode_value(type, val) do
    Encoder.encode_type(type, val)
  end
end
