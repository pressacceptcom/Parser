tool
class_name PressAccept_Parser_Pika_Match

# |=============================|
# |                             |
# |    Press Accept: Parser     |
# | Parsing Algorithms In Godot |
# |                             |
# |=============================|
#
# "A complete match of a Clause at a given start position."
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
# Class                  : Match
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

const Conductable: Script = PressAccept_Conductor_Conductable
const CONDUCTABLE: String = Conductable.STR_MIXIN_IDENTIFIER

const Mixer: Script = PressAccept_Mixer_Mixer

const Normalizer: Script = PressAccept_Normalizer_Normalizer

const Typer: Script = PressAccept_Typer_Typer

# |-------------|
# | Parser/Pika |
# |-------------|

const MemoTable : Script = PressAccept_Parser_Pika_MemoTable

# *************
# | Constants |
# *************

# There are no subclause matches for terminals. (Match[])
const ARR_NO_SUBCLAUSE_MATCHES: Array = []

# ***************************
# | Public Static Functions |
# ***************************


# wraps Mixin functionality to create a new object, use instead of new()
static func match_instantiate(
		init_memo_key                       : Array, # MemoKey
		init_length                         : int   = 0,
		init_first_matching_subclause_index : int   = 0,
		init_subclause_matches              : Array = ARR_NO_SUBCLAUSE_MATCHES
		) -> PressAccept_Parser_Pika_Match:

	return load('res://addons/PressAccept/Parser/Pika/MemoTable/Match.gd') \
		.new(
			init_memo_key,
			init_length,
			init_first_matching_subclause_index,
			init_subclause_matches
		)


# *********************
# | Public Properties |
# *********************

# The MemoKey.
var memo_key : Array # MemoKey

# The length of the match.
var length   : int

# **********************
# | Private Properties |
# **********************

# The subclause index of the first matching subclause (will be 0 unless
# #labeledClause} is a First, and the matching clause was not the first
# subclause).
var _first_matching_subclause_index: int

# The subclause matches. (Match[])
var _subclause_matches: Array

# Currently being output (prevents recursion)
var _being_output: bool = false

# ***************
# | Constructor |
# ***************


func _init(
		init_memo_key                       : Array, # MemoKey
		init_length                         : int   = 0,
		init_first_matching_subclause_index : int   = 0,
		init_subclause_matches              : Array = ARR_NO_SUBCLAUSE_MATCHES
		) -> void:

	memo_key                        = init_memo_key
	length                          = init_length
	_first_matching_subclause_index = init_first_matching_subclause_index
	_subclause_matches              = init_subclause_matches


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
		return "\n" + prefix + 'Match:' + str(get_instance_id())

	_being_output = true

	var output_str: String = ''
	
	output_str += "\n" + prefix + __get_script() \
		+ ' (' + str(get_instance_id()) + ') ='

	output_str += "\n" + prefix + tab_char + 'memo_key: '
	if memo_key:
		output_str += "\n" + tab_char + tab_char + 'clause: '
		if memo_key[MemoTable.INT_CLAUSE_INDEX]:
			output_str += memo_key[MemoTable.INT_CLAUSE_INDEX].__output(
				prefix + tab_char + tab_char + tab_char,
				tab_char
			)
		else:
			output_str += 'null'
		output_str += "\n" + tab_char + tab_char + 'start_pos: ' \
			+ str(memo_key[MemoTable.INT_START_POS_INDEX])
	else:
		output_str += 'empty'
	output_str += "\n" + prefix + tab_char + 'length: ' + str(length)

	_being_output = false
	
	return output_str


# ****************
# | Meta Methods |
# ****************


func __get_script():

	return 'res://addons/PressAccept/Parser/Pika/MemoTable/Match.gd'


# ******************
# | Public Methods |
# ******************


# Get subclause matches. Automatically flattens the right-recursive structure
# of OneOrMore nodes, collecting the subclause matches into a single array of
# (AST node label, subclause match) tuples.
func get_subclause_matches() -> Array: # List<Entry<String, Match>>

	if _subclause_matches.size() == 0:
		# This is a terminal, or an empty placeholder match returned by 
		# MemoTable.lookUpBestMatch
		return []

	var OneOrMore: Script = \
		load('res://addons/PressAccept/Parser/Pika/Clauses/Nonterminals/OneOrMore.gd') as Script
	var First: Script = \
		load('res://addons/PressAccept/Parser/Pika/Clauses/Nonterminals/First.gd') as Script

	if memo_key[MemoTable.INT_CLAUSE_INDEX] is OneOrMore:
		# Flatten right-recursive structure of OneOrMore parse subtree
		var subclause_matches_to_use : Array = [] # ArrayList<Entry<String, Match>>
		var current: PressAccept_Parser_Pika_Match = self
		while current._subclause_matches.size() > 0:
			# Add head of right-recursive list to arraylist, paired with its\
			# AST node label, if present
			subclause_matches_to_use.append(
				[
					current.memo_key[MemoTable.INT_CLAUSE_INDEX] \
						.labeled_subclauses[0].ast_node_label,
					current._subclause_matches[0]
				]
			)

			# The last element of the right-recursive list will have a single
			# element, i.e. (head), rather than two elements, i.e. (head, tail)
			# -- see the OneOrMore.match method
			if current._subclause_matches.size() == 1:
				break

			# Move to tail of list
			current = current._subclause_matches[1]

		return subclause_matches_to_use

	elif memo_key[MemoTable.INT_CLAUSE_INDEX] is First:
		# For First, pair the match with the AST node label from the subclause
		# of idx firstMatchingSubclauseIdx
		return [
			[
				memo_key[MemoTable.INT_CLAUSE_INDEX].labeled_subclauses[
						_first_matching_subclause_index
					].ast_node_label,
				_subclause_matches[0]
			]
		]

	else:
		# For other clause types, return labeled subclause matches
		var memo_key_clause_subclauses       = \
			memo_key[MemoTable.INT_CLAUSE_INDEX].labeled_subclauses
		var num_sub_clauses          : int   = \
			memo_key_clause_subclauses.size()
		var subclause_matches_to_use : Array = [] # ArrayList<Entry<String, Match>>
		for i in range(num_sub_clauses):
			subclause_matches_to_use.append(
				[
					memo_key_clause_subclauses[i].ast_node_label,
					_subclause_matches[i]
				]
			)
		return subclause_matches_to_use


# Compare this Match to another Match of same Clause type and start position.
#
# return true if this Match is better match than older Match in memo table.
func is_better_than(
		old_match: PressAccept_Parser_Pika_Match) -> bool:

	if old_match == self:
		return false
	else:
		return length > old_match.length


func to_string_with_rule_names() -> String:

	if not memo_key:
		return 'memo_key = empty+' + str(length)

	if memo_key[MemoTable.INT_CLAUSE_INDEX] == null:
		return 'clause = null : start_pos = ' \
			+ str(memo_key[MemoTable.INT_START_POS_INDEX])

	return memo_key[MemoTable.INT_CLAUSE_INDEX].to_string_with_rule_names() \
		+ ' : ' + str(memo_key[MemoTable.INT_START_POS_INDEX]) + '+' \
		+ str(length)


func to_string() -> String:

	if not memo_key:
		return 'memo_key = empty+' + str(length)

	if memo_key[MemoTable.INT_CLAUSE_INDEX] == null:
		return 'clause = null : start_pos = ' \
			+ str(memo_key[MemoTable.INT_START_POS_INDEX])

	return memo_key[MemoTable.INT_CLAUSE_INDEX].to_string() + ' : ' \
		+ str(memo_key[MemoTable.INT_START_POS_INDEX]) + '+' + str(length)

