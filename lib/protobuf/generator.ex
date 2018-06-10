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

      cond do
        opts[:map] ->
          ktype = opts[:ktype]
          vtype = opts[:vtype]
          knum = Encoder.encode_fnum(1, ktype)
          vnum = Encoder.encode_fnum(2, vtype)
          fnum = Encoder.encode_fnum(tag, :embedded)
          quote do
            Generator.encode_map_field(unquote(fnum), struct.unquote(name), unquote(knum), unquote(ktype), unquote(vnum), unquote(vtype))
          end
        opts[:repeated] ->
          type = case is_struct?(type) do
            true -> {:struct, type}
            false -> type
          end
          fnum = Encoder.encode_fnum(tag, :embedded)
          quote do
            Generator.encode_repeated_field(unquote(fnum), unquote(type), struct.unquote(name))
          end
        true ->
          fnum = Encoder.encode_fnum(tag, type)
          quote do
            Generator.encode_field( unquote(fnum), unquote(type), struct.unquote(name))
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

  def encode_field(_fnum, _type, nil), do: <<>>
  def encode_field(_fnum, :bool, false), do: <<>>
  def encode_field(_fnum, :int32, 0), do: <<>>
  def encode_field(_fnum, :int64, 0), do: <<>>
  def encode_field(_fnum, :uint32, 0), do: <<>>
  def encode_field(_fnum, :uint64, 0), do: <<>>
  def encode_field(_fnum, :sint32, 0), do: <<>>
  def encode_field(_fnum, :sint64, 0), do: <<>>
  def encode_field(_fnum, :fixed32, 0), do: <<>>
  def encode_field(_fnum, :fixed64, 0), do: <<>>
  def encode_field(_fnum, :sfixed32, 0), do: <<>>
  def encode_field(_fnum, :sfixed64, 0), do: <<>>
  def encode_field(_fnum, :float, 0), do: <<>>
  def encode_field(_fnum, :float, 0.0), do: <<>>
  def encode_field(_fnum, :double, 0), do: <<>>
  def encode_field(_fnum, :double, 0.0), do: <<>>

  def encode_field(fnum, :bool, true) do
    [fnum, <<1>>]
  end

  @int32_max 2_147_483_647
  @int32_min -2_147_483_648
  @int64_max 9_223_372_036_854_775_807
  @int64_min -9_223_372_036_854_775_808

  @uint32_max 4_294_967_295
  @uint64_max 18_446_744_073_709_551_615

  def encode_field(_tag, _type, nil) do
    <<>>
  end

  def encode_field(_fnum, :int32, 0), do: <<>>
  def encode_field(_fnum, :int64, 0), do: <<>>
  def encode_field(_fnum, :uint32, 0), do: <<>>
  def encode_field(_fnum, :uint64, 0), do: <<>>
  def encode_field(_fnum, :sint32, 0), do: <<>>
  def encode_field(_fnum, :sint64, 0), do: <<>>
  def encode_field(_fnum, :fixed32, 0), do: <<>>
  def encode_field(_fnum, :fixed64, 0), do: <<>>
  def encode_field(_fnum, :sfixed32, 0), do: <<>>
  def encode_field(_fnum, :sfixed64, 0), do: <<>>
  def encode_field(_fnum, :float, 0), do: <<>>
  def encode_field(_fnum, :float, 0.0), do: <<>>
  def encode_field(_fnum, :double, 0), do: <<>>
  def encode_field(_fnum, :double, 0.0), do: <<>>
  def encode_field(_fnum, :string, <<>>), do: <<>>
  def encode_field(_fnum, :bytes, <<>>), do: <<>>

  def encode_field(fnum, :int32, val) when val <= @int32_max and val >= @int32_min do
    [fnum, Encoder.encode_type(:int32, val)]
  end

  def encode_field(fnum, :int64, val) when val <= @int64_max and val >= @int64_min do
    [fnum, Encoder.encode_type(:int64, val)]
  end

  def encode_field(fnum, :uint32, val) when val <= @uint32_max and val >= 0 do
    [fnum, Encoder.encode_type(:uint32, val)]
  end

  def encode_field(fnum, :uint64, val) when val <= @uint64_max and val >= 0 do
    [fnum, Encoder.encode_type(:uint64, val)]
  end

  def encode_field(fnum, :sint32, val) when val <= @int32_max and val >= @int32_min do
    [fnum, Encoder.encode_type(:sint32, val)]
  end

  def encode_field(fnum, :sint64, val) when val <= @int64_max and val >= @int64_min do
    [fnum, Encoder.encode_type(:sint64, val)]
  end

  def encode_field(fnum, :fixed32, val) when val <= @uint32_max and val >= 0 do
    [fnum, Encoder.encode_type(:fixed32, val)]
  end

  def encode_field(fnum, :fixed64, val) when val <= @uint64_max and val >= 0 do
    [fnum, Encoder.encode_type(:fixed64, val)]
  end

  def encode_field(fnum, :sfixed32, val) when val <= @int32_max and val >= @int32_min do
    [fnum, Encoder.encode_type(:sfixed32, val)]
  end

  def encode_field(fnum, :sfixed64, val) when val <= @int64_max and val >= @int64_min do
    [fnum, Encoder.encode_type(:sfixed64, val)]
  end

  def encode_field(fnum, :float, val) when is_number(val) do
    [fnum, Encoder.encode_type(:float, val)]
  end

  def encode_field(fnum, :double, val) when is_number(val) do
    [fnum, Encoder.encode_type(:double, val)]
  end

  def encode_field(fnum, type, %{__struct__: _} = val) do
    encoded = type.encode(val)
    byte_size = :erlang.iolist_size(encoded)
    [fnum, Encoder.encode_varint(byte_size), encoded]
  end

  def encode_field(fnum, type, val) do
    [fnum, encode_value(type, val)]
  end

  def encode_map_field(_fnum, nil, _knum, _ktype, _vnum, _vtype) do
    <<>>
  end

  def encode_map_field(_fnum, map, _knum, _ktype, _vnum, _vtype) when map_size(map) == 0 do
    <<>>
  end

  def encode_map_field(fnum, map, knum, ktype, vnum, vtype) do
    Enum.reduce(map, [], fn {key, value}, acc ->
      encoded = [
        encode_field(knum, ktype, key),
        encode_field(vnum, vtype, value)
      ]
      byte_size = :erlang.iolist_size(encoded)
      [[fnum, byte_size, encoded] | acc]
    end)
  end

  def encode_repeated_field(_fnum, _type, nil) do
    <<>>
  end

  def encode_repeated_field(_fnum, _type, []) do
    <<>>
  end

  # In proto3, only scalar numeric types are packed.
  def encode_repeated_field(fnum, type, enum) when type in [:bytes, :string] do
    Enum.reduce(enum, [], fn value, acc ->
      [acc, fnum, encode_value(type, value)]
    end)
  end

  def encode_repeated_field(fnum, {:struct, type}, enum) do
    Enum.reduce(enum, [], fn value, acc ->
      [acc, encode_field(fnum, type, value)]
    end)
  end

  def encode_repeated_field(fnum, type, enum) do
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
