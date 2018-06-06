Code.require_file("proto_gen/test.pb.ex", __DIR__)
Code.require_file("proto_gen/proto3.pb.ex", __DIR__)

defmodule Protobuf.Protoc.IntegrationTest do
  use ExUnit.Case, async: true
  # @moduletag :integration

  alias My.Test.Everything

  # test "encode and decode My.Test.Request" do
  #   entry = %My.Test.Reply.Entry{
  #     key_that_needs_1234camel_CasIng: 1,
  #     value: -12345,
  #     _my_field_name_2: 21
  #   }

  #   reply = %My.Test.Reply{found: [entry], compact_keys: [1, 2, 3]}

  #   input =
  #     My.Test.Request.new(
  #       key: [123],
  #       hue: My.Test.Request.Color.value(:GREEN),
  #       hat: My.Test.HatType.value(:FEZ),
  #       deadline: 123.0,
  #       name_mapping: %{321 => "name"},
  #       msg_mapping: %{1234 => reply}
  #     )

  #   output = My.Test.Request.encode(input)
  #   assert My.Test.Request.__message_props__().field_props[14].map?
  #   assert My.Test.Request.__message_props__().field_props[15].map?
  #   assert My.Test.Request.NameMappingEntry.__message_props__().map?
  #   assert My.Test.Request.MsgMappingEntry.__message_props__().map?
  #   assert My.Test.Request.decode(output) == input
  # end

  # test "encode and decode My.Test.Communique(oneof)" do
  #   unions = [
  #     number: 42,
  #     name: "abc",
  #     temp_c: 1.2,
  #     height: 2.5,
  #     today: 1,
  #     maybe: true,
  #     delta: 123,
  #     msg: My.Test.Reply.new()
  #   ]

  #   Enum.each(unions, fn union ->
  #     input = %My.Test.Communique{union: union}
  #     output = My.Test.Communique.encode(input)
  #     assert My.Test.Communique.decode(output) == input
  #   end)
  # end

  test "generated encode with default values" do
    assert_defaults(encode_decode(%Everything{}), except: [])
  end

  test "generated encode with non-default values" do
    values = %{
      bool: true, int32: -21, int64: -9922232, uint32: 82882, uint64: 199922332321984,
      sint32: -221331, sint64: -29, fixed32: 4294967295, sfixed32: -2147483647,
      fixed64: 1844674407370955161, sfixed64: -9223372036854775807,
      float: 2.5, double: -3.551, string: "over", bytes: <<9, 0, 0, 0>>,

      bools: [true], int32s: [-21], int64s: [-9922232], uint32s: [82882], uint64s: [199922332321984],
      sint32s: [-221331], sint64s: [-29], fixed32s: [4294967295], sfixed32s: [-2147483647],
      fixed64s: [1844674407370955161], sfixed64s: [-9223372036854775807],
      floats: [2.5], doubles: [-3.551], strings: ["over"],
      bytess: [<<9, 0, 0, 0>>], map1: %{"over" => 9000}
    }

    everything = encode_decode(struct(Everything, values))
    assert_everything(everything, values)
  end

  test "generated encode with multi-value arrays" do
    values = %{
      bools: [true, false], int32s: [-21, 32], int64s: [-9922232, 9922232],
      uint32s: [82882, 323], uint64s: [199922332321984, 3223001],
      sint32s: [-221331, 221331], sint64s: [-29, 29],
      fixed32s: [4294967295, 0, 1], sfixed32s: [1, 2, 3, 4, 5],
      fixed64s: [192, 391, 12], sfixed64s: [-2, 2, 93, 11, -293321938],
      floats: [2.5, 0, -5.50, 299381.0], doubles: [-3.551, 3.551], strings: ["over", "9000", "", "!"],
      bytess: [<<9, 0, 0, 0>>, <<2, 0>>], map1: %{"over" => 9000, "spice" => 1337}
    }

    everything = encode_decode(struct(Everything, values))
    assert_everything(everything, values)
  end

  defp encode_decode(struct) do
    mod = struct.__struct__
    Protobuf.Decoder.decode(mod.encode(struct), mod)
  end

  @defaults [
    bool: false, int32: 0, int64: 0, uint32: 0, uint64: 0, sint32: 0, sint64: 0,
    fixed32: 0, sfixed32: 0, fixed64: 0, sfixed64: 0, float: 0.0, double: 0.0,
    string: "" , bytes: "", bools: [], int32s: [], int64s: [], uint32s: [],
    uint64s: [], sint32s: [], sint64s: [], fixed32s: [], sfixed32s: [], fixed64s: [],
    sfixed64s: [], floats: [], doubles: [], strings: [], bytess: [], map1: %{}
  ]

  defp assert_defaults(everything, [except: except]) do
    assert_everything(everything, Keyword.drop(@defaults, except))
  end

  defp assert_defaults(everything, [only: only]) do
    assert_everything(everything, Keyword.take(@defaults, only))
  end

  defp assert_everything(everything, expected) do
    Enum.each(expected, fn {k, v} ->
      actual = Map.get(everything, k)
      assert actual == v, "expect value of #{inspect(v)} for #{k}, got #{inspect(actual)}"
    end)
  end
end
