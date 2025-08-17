tool
class_name PressAccept_Parser_Pika_CharSet

extends PressAccept_Parser_Pika_Terminal

# |=============================|
# |                             |
# |    Press Accept: Parser     |
# | Parsing Algorithms In Godot |
# |                             |
# |=============================|
#
# "Terminal clause that matches a character or sequence of characters."
#
# This source is ported from Luke Hutchison's reference implementation of the
# Pika parser. That software is licensed under the MIT license. This port of
# the software is also licensed under the MIT license. For full copyright
# disclosure and license information please consult LICENSE in the Parser/Pika
# root directory.
#
# For more information on the Pika parser please see:
#     https://github.com/lukehutch/pikaparser
#
# |------------------|
# | Meta Information |
# |------------------|
#
# Organization Namespace : PressAccept
# Package Namespace      : Parser
# Sub-Package Namespace  : Pika
# Class                  : CharSet
#
# Organization        : Press Accept
# Organization URI    : https://pressaccept.com/
# Organization Social : @pressaccept
#
# Author        : Asher Kadar Wolfstein
# Author URI    : https://wunk.me/ (Personal Blog)
# Author Social : https://incarnate.me/members/asherwolfstein/
#                 @asherwolfstein (Twitter)
#                 https://ko-fi.com/asherwolfstein
#
# Copyright : Press Accept: Parser © 2022 The Novelty Factor LLC
#                 (Press Accept, Asher Kadar Wolfstein)
# License   : MIT License
#
# |-----------|
# | Changelog |
# |-----------|
#

# ***********
# | Imports |
# ***********

# |-------------|
# | Parser/Pika |
# |-------------|

const Terminal: Script = PressAccept_Parser_Pika_Terminal

# ********************
# | Internal Classes |
# ********************

class BitSet:
	extends Reference

	var set: PoolByteArray

	var cardinality: int


	func _init(
			init_inverted: bool = false) -> void:

		set         = PoolByteArray()
		cardinality = 0


	func cardinality() -> int:

		return cardinality


	func size() -> int:

		return set.size() * 8


	func set_bit(
			index: int) -> void:

		var byte_index : int = _get_byte_index(index)
		var bit_index  : int = index % 8
		var mask       : int = 1 << bit_index
		set[byte_index] = set[byte_index] | mask
		cardinality += 1


	func set_bit_range(
			start : int,
			end   : int) -> void:

		for i in range(start, end):
			set_bit(i)


	func get_bit(
			index: int) -> bool:

		var byte_index : int = _get_byte_index(index)
		var bit_index  : int = index % 8
		var mask       : int = 1 << bit_index
		var ret        : int = set[byte_index] & mask
		return ret > 0


	func next_set_bit(
			index: int) -> int:

		var byte_index : int = _get_byte_index(index)
		var bit_index  : int = index % 8

		var i: int = byte_index
		while i < set.size():
			if set[i] > 0:
				for b in range(bit_index, 8):
					var mask : int = 1 << b
					var ret  : int = set[i] & mask
					if ret > 0:
						return i * 8 + b
			bit_index = 0
			i += 1

		return -1


	func _get_byte_index(
			index: int) -> int:

		var byte_index: int = int(index / 8)
		if byte_index + 1 > set.size():
			var size: int = set.size()
			set.resize(byte_index + 1)
			for i in range(size, byte_index + 1):
				set[i] = 0

		return byte_index


# *************
# | Constants |
# *************

const STR_CHARS    : String = 'charset_chars'
const STR_CHARSETS : String = 'charset_charsets'
const STR_BITSET   : String = 'charset_bitsets'

# *************************
# | Meta Static Functions |
# *************************


# this is made up of the following mixins
static func __mixed_info() -> Array:

	return Terminal.__mixed_info()


# ***************************
# | Public Static Functions |
# ***************************


# wraps Mixin functionality to create a new object, use instead of new()
static func charset_instantiate(
		chars: String) -> PressAccept_Parser_Pika_CharSet:

	return Terminal.Mixer.instantiate(
		'res://addons/PressAccept/Parser/Pika/Clauses/Terminal/CharSet.gd',
		[
			{
				STR_CHARS: chars
			}
		],
		true
	)


static func charset_instantiate_with_charsets(
		charsets: Array) -> PressAccept_Parser_Pika_CharSet:

	return Terminal.Mixer.instantiate(
		'res://addons/PressAccept/Parser/Pika/Clauses/Terminal/CharSet.gd',
		[
			{
				STR_CHARSETS: charsets
			}
		],
		true
	)


static func charset_instantiate_with_bitset(
		bitset: BitSet) -> PressAccept_Parser_Pika_CharSet:

	return Terminal.Mixer.instantiate(
		'res://addons/PressAccept/Parser/Pika/Clauses/Terminal/CharSet.gd',
		[
			{
				STR_BITSET: bitset
			}
		],
		true
	)


# *********************
# | Public Properties |
# *********************

var chars: BitSet

var inverted_chars: BitSet

# ***************
# | Constructor |
# ***************


func __init(
		init_args: Dictionary) -> void:

	.__init(init_args)

	if STR_CHARS in init_args:
		chars = BitSet.new()
		for i in range(init_args[STR_CHARS].length()):
			chars.set_bit(ord(init_args[STR_CHARS][i]))

	elif STR_CHARSETS in init_args:
		if init_args[STR_CHARSETS].size() == 0:
			self[THROWABLE].throw(
				{
					Exception.STR_EXCEPTION_CODE    : 'Illegal Argument',
					Exception.STR_EXCEPTION_MESSAGE : \
						'Must provide at least one char in CharSet'
				},
				Error
			)
			return

		chars = BitSet.new()
		for charset in init_args[STR_CHARSETS]:
			if charset.chars != null:
				var i: int = charset.chars.next_set_bit(0)
				while i >= 0:
					chars.set_bit(i)
					i = charset.chars.next_set_bit(i + 1)
				
			if charset.inverted_chars != null:
				if inverted_chars == null:
					inverted_chars = BitSet.new()
				var i: int = charset.inverted_chars.next_set_bit(0)
				while i >= 0:
					inverted_chars.set_bit(i)
					i = charset.inverted_chars.next_set_bit(i + 1)

	elif STR_BITSET in init_args:
		if init_args[STR_BITSET].cardinality() == 0:
			self[THROWABLE].throw(
				{
					Exception.STR_EXCEPTION_CODE    : 'Illegal Argument',
					Exception.STR_EXCEPTION_MESSAGE : \
						'Must provide at least one char in CharSet'
				},
				Error
			)

		chars = init_args[STR_BITSET]


# ********************
# | Built-In Methods |
# ********************


# dislay this array as a pretty-printed string
func _to_string() -> String:

	return __output('')


# pretty print the internal info prefaced by, and using a whitespace
func __output(
		prefix   : String,
		tab_char : String = "\t") -> String:

	if _being_output:
		return "\n" + prefix + 'CharSeq:' + str(get_instance_id())

	_being_output = true

	var output_str: String = ''
	
	output_str += "\n" + prefix + __get_script() \
		+ ' (' + str(get_instance_id()) + ') ='

	output_str += self[CONDUCTABLE].__output(prefix + tab_char, tab_char)
	output_str += self[COMPARABLE].__output(prefix + tab_char, tab_char)
	output_str += self[THROWABLE].__output(prefix + tab_char, tab_char)

	output_str += "\n" + prefix + tab_char + 'labeled_subclauses:'
	for element in labeled_subclauses:
		if element is Object and element.has_method('__output'):
			output_str += \
				element.__output(prefix + tab_char + tab_char, tab_char)
		else:
			output_str += "\n" + prefix + tab_char + tab_char + str(element)

	output_str += "\n" + prefix + tab_char + 'rules:'
	for element in rules:
		if element is Object and element.has_method('__output'):
			output_str += \
				element.__output(prefix + tab_char + tab_char, tab_char)
		else:
			output_str += "\n" + prefix + tab_char + tab_char + str(element)

	output_str += "\n" + prefix + tab_char + 'seed_parent_clauses:'
	for element in seed_parent_clauses:
		if element is Object and element.has_method('__output'):
			output_str += \
				element.__output(prefix + tab_char + tab_char, tab_char)
		else:
			output_str += "\n" + prefix + tab_char + tab_char + str(element)

	output_str += "\n" + prefix + tab_char + 'can_match_zero_chars: ' \
		+ str(can_match_zero_chars)
	output_str += "\n" + prefix + tab_char + 'clause_index: ' \
		+ str(clause_index)

	_being_output = false
	
	return output_str


# ****************
# | Meta Methods |
# ****************


func __get_script():

	return 'res://addons/PressAccept/Parser/Pika/Clauses/Terminal/CharSet.gd'


# ******************
# | Public Methods |
# ******************


func invert() -> PressAccept_Parser_Pika_CharSet:

	var tmp: BitSet = chars
	chars = inverted_chars
	inverted_chars = tmp
	to_string_cached = ''
	return self


func determine_whether_can_match_zero_chars(): # -> void

	pass


func match(
		memo_table : MemoTable,
		memo_key   : Array, # : MemoKey,
		input      : String): # -> MemoMatch

	if memo_key[MemoTable.INT_START_POS_INDEX] < input.length():
		var c: String = input[memo_key[MemoTable.INT_START_POS_INDEX]]
		if (chars != null and chars.get_bit(ord(c))) \
				or (inverted_chars != null \
					and not inverted_chars.get_bit(ord(c))):
			# Terminals are not memoized (i.e. don't look in the memo table)
			return MemoMatch.match_instantiate(
				memo_key,
				1,
				0,
				MemoMatch.ARR_NO_SUBCLAUSE_MATCHES
			)

	return null


func to_string_with_args(
		_chars      : BitSet,
		cardinality : int,
		inverted    : bool) -> String:

	var return_value: String = ''

	var is_single_char: bool = not inverted and cardinality == 1

	if is_single_char:
		var c: String = char(_chars.next_set_bit(0))
		return_value += "'"
		return_value += PressAccept_Parser_Pika_String.escape_quoted_char(c)
		return_value += "'"
	else:
		return_value += '['
		if inverted:
			return_value += '^'
		var i: int = _chars.next_set_bit(0)
		while i >= 0:
			return_value += \
				PressAccept_Parser_Pika_String.escape_char_range_char(char(i))
			if i < _chars.size() - 1 and _chars.get_bit(i + 1):
				# Contiguous char range
				var end: int = i + 2
				while end < _chars.size() and _chars.get_bit(end):
					end += 1
				var num_chars_spanned: int = end - i
				if num_chars_spanned > 2:
					return_value += '-'
				return_value += \
					PressAccept_Parser_Pika_String \
						.escape_char_range_char(char(end - 1))
				i = end - 1
			i = _chars.next_set_bit(i + 1)

		return_value += ']'

	return return_value


func to_string() -> String:

	if not to_string_cached:
		var chars_cardinality: int = 0 \
			if chars == null \
			else chars.cardinality()
		var inverted_chars_cardinality: int = 0 \
			if inverted_chars == null \
			else inverted_chars.cardinality()
		var inverted_and_not: bool = \
			chars_cardinality > 0 and inverted_chars_cardinality > 0
		if inverted_and_not:
			to_string_cached += '('
		if chars_cardinality > 0:
			to_string_cached += \
				to_string_with_args(chars, chars_cardinality, false)
		if inverted_and_not:
			to_string_cached += ' | '
		if inverted_chars_cardinality > 0:
			to_string_cached += to_string_with_args(
				inverted_chars,
				inverted_chars_cardinality,
				true
			)
		if inverted_and_not:
			to_string_cached += ')'

	return to_string_cached

