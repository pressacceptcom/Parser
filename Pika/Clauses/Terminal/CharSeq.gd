tool
class_name PressAccept_Parser_Pika_CharSeq

extends PressAccept_Parser_Pika_Terminal

# |=============================|
# |                             |
# |    Press Accept: Parser     |
# | Parsing Algorithms In Godot |
# |                             |
# |=============================|
#
# "Terminal clause that matches a token in the input string."
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
# Class                  : CharSeq
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

# *************
# | Constants |
# *************

const STR_STRING      : String = 'charseq_string'
const STR_IGNORE_CASE : String = 'charseq_ignore_case'

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
static func charseq_instantiate(
		init_string      : String,
		init_ignore_case : bool = false) -> PressAccept_Parser_Pika_CharSeq:

	return Terminal.Mixer.instantiate(
		'res://addons/PressAccept/Parser/Pika/Clauses/Terminal/CharSeq.gd',
		[
			{
				STR_STRING      : init_string,
				STR_IGNORE_CASE : init_ignore_case
			}
		],
		true
	)


# *********************
# | Public Properties |
# *********************

var string: String

var ignore_case: bool = false

# ***************
# | Constructor |
# ***************


func __init(
		init_args: Dictionary) -> void:

	.__init(init_args)

	if STR_STRING in init_args:
		string = init_args[STR_STRING]

	if STR_IGNORE_CASE in init_args:
		ignore_case = init_args[STR_IGNORE_CASE]


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

	output_str += "\n" + prefix + tab_char + 'string: ' + string
	output_str += "\n" + prefix + tab_char + 'ignore_case: ' + str(ignore_case)

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

	return 'res://addons/PressAccept/Parser/Pika/Clauses/Terminal/CharSeq.gd'


# ******************
# | Public Methods |
# ******************


func determine_whether_can_match_zero_chars(): # -> void

	pass


func match(
		memo_table : MemoTable,
		memo_key   : Array, # : MemoKey,
		input      : String): # -> MemoMatch

	if memo_key[MemoTable.INT_START_POS_INDEX] <= input.length() - string.length() \
			and PressAccept_Utilizer_String.region_matches(
				input,
				ignore_case,
				memo_key[MemoTable.INT_START_POS_INDEX],
				string,
				0,
				string.length()
			):
		return MemoMatch.match_instantiate(memo_key, string.length())

	return null


func to_string() -> String:

	if not to_string_cached:
		to_string_cached += '"' \
			+ PressAccept_Parser_Pika_String.escape_string(string) + '"'

	return to_string_cached

