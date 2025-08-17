tool
class_name PressAccept_Parser_Pika_Seq

extends PressAccept_Parser_Pika_Clause

# |=============================|
# |                             |
# |    Press Accept: Parser     |
# | Parsing Algorithms In Godot |
# |                             |
# |=============================|
#
# "The Seq (sequence) PEG operator."
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
static func seq_instantiate(
		init_subclauses: Array): # -> PressAccept_Parser_Pika_First:

	if init_subclauses.size() < 2:
		return Clause.Exception.create(
			{
				Clause.Exception.STR_EXCEPTION_CODE    : 'Illegal Argument',
				Clause.Exception.STR_EXCEPTION_MESSAGE : \
					'Seq expects 2 or more subclauses'
			},
			Clause.Error
		)

	return Clause.Mixer.instantiate(
		'res://addons/PressAccept/Parser/Pika/Clauses/Nonterminal/Seq.gd',
		[
			{
				Clause.STR_SUBCLAUSES: init_subclauses
			}
		],
		true
	)


# ***************
# | Constructor |
# ***************


func __init(
		init_args: Dictionary) -> void:

	if STR_SUBCLAUSES in init_args:
		if init_args[STR_SUBCLAUSES].size() < 2:
			self[THROWABLE].throw(
				{
					Exception.STR_EXCEPTION_CODE    : 'Illegal Argument',
					Exception.STR_EXCEPTION_MESSAGE : \
						'Seq expects 2 or more subclauses'
				},
				Error
			)

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
		return "\n" + prefix + 'Seq:' + str(get_instance_id())

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

	return 'res://addons/PressAccept/Parser/Pika/Clauses/Nonterminal/Seq.gd'


# ******************
# | Public Methods |
# ******************


func determine_whether_can_match_zero_chars():

	# For Seq, all subclauses must be able to match zero characters for the
	# whole clause to be able to match zero characters
	can_match_zero_chars = true
	for subclause in labeled_subclauses:
		if not subclause.clause.can_match_zero_chars:
			can_match_zero_chars = false
			break


func add_as_seed_parent_clause() -> void:

	# All sub-clauses up to and including the first clause that matches one or
	# more characters needs to seed its parent clause if there is a subclause
	# match
	var added: Array = []
	for subclause in labeled_subclauses:
		subclause = subclause.clause
		# Don't duplicate seed parent clauses in the subclause
		if not subclause in added:
			subclause.seed_parent_clauses.append(self)
			added.append(self)
		if not subclause.can_match_zero_chars:
			# Don't need to any subsequent subclauses to seed this parent clause
			break


func match(
		memo_table : MemoTable,
		memo_key   : Array, # : MemoKey,
		input      : String):

	var subclause_matches : Array = []
	var curr_start_pos    : int = memo_key[MemoTable.INT_START_POS_INDEX]

	for subclause in labeled_subclauses:
		# var subClause = labeledSubClauses[subClauseIdx].clause;
		subclause = subclause.clause
		var subclause_memo_key : Array     = \
			[ subclause, curr_start_pos ] # : MemoKey
		var subclause_match    : MemoMatch = \
			memo_table.lookup_best_match(subclause_memo_key)
		if subclause_match == null:
			# Fail after first subclause fails to match
			return null

		subclause_matches.append(subclause_match)
		curr_start_pos += subclause_match.length

	return MemoMatch.match_instantiate(
		memo_key,
		curr_start_pos - memo_key[MemoTable.INT_START_POS_INDEX],
		0,
		subclause_matches
	)


func to_string() -> String:

	if not to_string_cached:
		for i in range(labeled_subclauses.size()):
			if i > 0:
				to_string_cached += ' '
			to_string_cached += \
				labeled_subclauses[i].to_string_with_ast_node_label(self)

	return to_string_cached

