tool
class_name PressAccept_Parser_Pika_OneOrMore

extends PressAccept_Parser_Pika_Clause

# |=============================|
# |                             |
# |    Press Accept: Parser     |
# | Parsing Algorithms In Godot |
# |                             |
# |=============================|
#
# ""
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
# Class                  : OneOrMore
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

const Clause: Script = PressAccept_Parser_Pika_Clause

# *************************
# | Meta Static Functions |
# *************************


# this is made up of the following mixins
static func __mixed_info() -> Array:

	return Clause.__mixed_info()


# ***************************
# | Public Static Functions |
# ***************************


# wraps Mixin functionality to create a new object, use instead of new()
static func oneormore_instantiate(
		init_subclause: Clause) -> PressAccept_Parser_Pika_OneOrMore:

	return Clause.Mixer.instantiate(
		'res://addons/PressAccept/Parser/Pika/Clauses/Nonterminal/OneOrMore.gd',
		[
			{
				Clause.STR_SUBCLAUSES: [ init_subclause ]
			}
		],
		true
	)


# ***************
# | Constructor |
# ***************


func __init(
		init_args: Dictionary) -> void:

	.__init(init_args)


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
		return "\n" + prefix + 'OneOrMore:' + str(get_instance_id())

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

	return 'res://addons/PressAccept/Parser/Pika/Clauses/Nonterminal/OneOrMore.gd'


# ******************
# | Public Methods |
# ******************


func determine_whether_can_match_zero_chars(): # -> void

	can_match_zero_chars = labeled_subclauses[0].clause.can_match_zero_chars


func match(
		memo_table : MemoTable,
		memo_key   : Array, # : MemoKey,
		input      : String): # -> MemoMatch

	var subclause_memo_key : Array     = [
		labeled_subclauses[0].clause,
		memo_key[MemoTable.INT_START_POS_INDEX]
	] # MemoKey
	
	var subclause_match    : MemoMatch = \
		memo_table.lookup_best_match(subclause_memo_key)
	if subclause_match == null:
		# Zero matches at memoKey.startPos
		return null

	# Perform right-recursive match of the same OneOrMore clause, so that the
	# memo table doesn't fill up with O(M^2) entries in the number of subclause
	# matches M. If there are two or more matches, tailMatch will be non-null.
	var tail_match_memo_key: Array = [
		self,
		memo_key[MemoTable.INT_START_POS_INDEX] + subclause_match.length
	] # : MemoKey

	var tail_match: MemoMatch = \
		memo_table.lookup_best_match(tail_match_memo_key)

	# Return a new (right-recursive) match
	return MemoMatch.match_instantiate(
			memo_key,
			subclause_match.length,
			0,
			[ subclause_match ]
		) \
		if tail_match == null \
		else MemoMatch.match_instantiate(
			memo_key,
			subclause_match.length + tail_match.length,
			0,
			[ subclause_match, tail_match ]
		)


func to_string() -> String:

	if not to_string_cached:
		to_string_cached = \
			labeled_subclauses[0].to_string_with_ast_node_label(self) + '+'

	return to_string_cached

