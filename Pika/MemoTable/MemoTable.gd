tool
class_name PressAccept_Parser_Pika_MemoTable

# |=============================|
# |                             |
# |    Press Accept: Parser     |
# | Parsing Algorithms In Godot |
# |                             |
# |=============================|
#
# "A memo entry for a specific {@link Clause} at a specific start position."
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

const Collection: Script = PressAccept_Utilizer_Collection

const DataDictionary: Script = PressAccept_Utilizer_Data_Dictionary

const Exception: Script = PressAccept_Error_Exception

const OrderedDictionary: Script = PressAccept_Utilizer_Data_OrderedDictionary

const PriorityQueue: Script = PressAccept_Utilizer_Data_PriorityQueue

# |-------------|
# | Parser/Pika |
# |-------------|

const IntervalUnion: Script = PressAccept_Parser_Pika_IntervalUnion

const MemoKey   : Script = PressAccept_Parser_Pika_MemoKey

# *************
# | Constants |
# *************

const INT_CLAUSE_INDEX    : int = 0
const INT_START_POS_INDEX : int = 1

# ***************************
# | Public Static Functions |
# ***************************


# wraps Mixin functionality to create a new object, use instead of new()
static func memotable_instantiate(
		init_grammar, # : Grammar,
		init_input   : String) -> PressAccept_Parser_Pika_MemoTable:

	return load('res://addons/PressAccept/Parser/Pika/MemoTable/MemoTable.gd') \
		.new(
			init_grammar,
			init_input
		)


# *********************
# | Public Properties |
# *********************

# The grammar.
var grammar # : Grammar

# The input string.
var input: String

# The number of Match instances created.
var num_match_objs_created: int

# The number of Match instances added to the memo table (some will be
# overwritten by later matches).
var num_match_objs_memoized: int

# **********************
# | Private Properties |
# **********************

# A map from clause to startPos to a Match for the memo entry. (Use concurrent
# data structures so that terminals can be memoized in parallel during
# initialization.)
#
# Map<MemoKey, Match>
var _memo_table   : Dictionary # <Clause <Start_Position Match>>

# are we being output? (prevents recursion)
var _being_output : bool       = false

# ***************
# | Constructor |
# ***************


func _init(
		init_grammar, # : Grammar,
		init_input   : String) -> void:

	grammar = init_grammar
	input   = init_input
	_memo_table = {}


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
		return "\n" + prefix + 'MemoTable:' + str(get_instance_id())

	_being_output = true

	var output_str: String = ''
	
	output_str += "\n" + prefix + __get_script() \
		+ ' (' + str(get_instance_id()) + ') ='

	output_str += "\n" + prefix + tab_char + 'grammar: '
	if grammar:
		output_str += grammar.__output(prefix + tab_char + tab_char, tab_char)
	else:
		output_str += 'null'

	output_str += "\n" + prefix + tab_char + '_memo_table: '
	for clause in _memo_table:
		output_str += clause.__output(prefix + tab_char + tab_char, tab_char )
		for start_pos in _memo_table[clause]:
			output_str += "\n" + prefix + tab_char + tab_char + tab_char \
				+ 'start_pos: ' + str(start_pos)
			output_str += _memo_table[clause][start_pos].__output(
				prefix + tab_char + tab_char + tab_char + tab_char,
				tab_char
			)

	output_str += "\n" + prefix + tab_char + 'num_match_objs_created: ' \
		+ str(num_match_objs_created)
	output_str += "\n" + prefix + tab_char + 'num_match_objs_memoized: ' \
		+ str(num_match_objs_memoized)
	output_str += "\n" + prefix + tab_char + 'input: ' + "\n\n" + input

	_being_output = false
	
	return output_str


# ****************
# | Meta Methods |
# ****************


func __get_script():

	return 'res://addons/PressAccept/Parser/Pika/MemoTable/MemoTable.gd'


# ******************
# | Public Methods |
# ******************


# Look up the current best match for a given MemoKey in the memo table.
func lookup_best_match(
		memo_key: Array # MemoKey
		): # -> MemoMatch:

	# Find current best match in memo table
	# (null if there is no current best match)
	var best_match = _get_if_exists_or_null(memo_key) # : MemoMatch

	var NotFollowedBy: Script = \
		load('res://addons/PressAccept/Parser/Pika/Clauses/Nonterminal/NotFollowedBy.gd') as Script

	# If there is a current best match, return it
	if best_match:
		return best_match

	elif memo_key[INT_CLAUSE_INDEX] is NotFollowedBy:
		# Need to match NotFollowedBy top-down
		return memo_key[INT_CLAUSE_INDEX].match(self, memo_key, input)

	elif memo_key[INT_CLAUSE_INDEX].can_match_zero_chars:
		var MemoMatch: Script = \
			load('res://addons/PressAccept/Parser/Pika/MemoTable/Match.gd') as Script

		# If there is no match in the memo table for this clause, but this\
		# clause can match zero characters, then we need to return a new
		# zero-length match to the parent clause. (This is part of the strategy
		# for minimizing the number of zero-length matches that are memoized.)
		#
		# (N.B. this match will not have any subclause matches, which may be
		# unexpected, so conversion of parse tree to AST should be robust to
		# this.)
		return MemoMatch.match_instantiate(memo_key)

	return null


# Add a new Match to the memo table, if the match is non-null. Schedule seed
# parent clauses for matching if the match is non-null or if the parent clause
# can match zero characters.
func add_match(
		memo_key       : Array,
		# memo_key       : MemoKey,
		new_match      , # : MemoMatch,
		priority_queue : PriorityQueue) -> void: # PriorityQueue<Clause>

	var match_updated: bool = false

	if new_match: # new_match != null
		# Track memoization
		num_match_objs_created += 1

		# Get the memo entry for memoKey if already present;
		# if not, create a new entry
		var old_match = _get_if_exists_or_null(memo_key) # : MemoMatch
		
		# If there is no old match, or the new match is better than old match
		if old_match == null or new_match.is_better_than(old_match):
			# Store the new match in the memo entry
			_set_value(memo_key, new_match)
			match_updated = true

			# Track memoization
			num_match_objs_memoized += 1

			if grammar.DEBUG:
				print('Setting new best match: ' \
					+ new_match.to_string_with_rule_names())

	for seed_parent_clause in memo_key[INT_CLAUSE_INDEX].seed_parent_clauses:
		# If there was a valid match, or if there was no match but the parent
		# clause can match zero characters, schedule the parent clause for
		# matching. (This is part of the strategy for minimizing the number of
		# zero-length matches that are memoized.)
		if match_updated or seed_parent_clause.can_match_zero_chars:
			priority_queue.add(seed_parent_clause)
			if grammar.DEBUG:
				print('    Following seed parent clause: ' \
					+ seed_parent_clause.to_string_with_rule_names())

	if grammar.DEBUG:
		print(
			'Matched: ' + new_match.to_string_with_rule_names() \
				if new_match != null \
				else 'Failed To Match: ' \
					+ memo_key[INT_CLAUSE_INDEX].to_string_with_rule_names() \
					+ ' : ' + str(memo_key[INT_START_POS_INDEX])
		)


# Get all Match entries, indexed by clause then start position.
func get_all_navigable_matches() -> Dictionary:
	# Map<Clause, NavigableMap<Integer, Match>>

	var clause_map: Dictionary = {}
	# HashMap<Clause, NavigableMap<Integer, Match>>

	for memo_match in _get_all_values():
		var start_pos_map = Collection.get_if_exists_or_null(
			clause_map,
			memo_match.memo_key[INT_CLAUSE_INDEX]
		)

		if start_pos_map == null:
			start_pos_map = \
				OrderedDictionary.ordereddictionary_instantiate() # TreeMap<>
			start_pos_map.enable_autosort()
			clause_map[memo_match.memo_key[INT_CLAUSE_INDEX]] = start_pos_map
		start_pos_map.set_value(
			memo_match.memo_key[INT_START_POS_INDEX],
			memo_match,
			true
		)

	return clause_map


# Get all nonoverlapping Match entries, indexed by clause then start position.
func get_all_nonoverlapping_matches() -> Dictionary:
	# Map<Clause, NavigableMap<Integer, Match>>

	var nonoverlapping_clause_map: Dictionary = {}
	# HashMap<Clause, NavigableMap<Integer, Match>>

	var entry_set: Dictionary = get_all_navigable_matches()
	for clause in entry_set:
		var start_pos_map: OrderedDictionary = entry_set[clause]
		var prev_end_pos : int               = 0

		var nonoverlapping_start_pos_map: OrderedDictionary \
			= OrderedDictionary.ordereddictionary_instantiate() # TreeMap<Integer, Match>
		nonoverlapping_start_pos_map.enable_autosort()

		for start_pos in start_pos_map.sequence:
			if start_pos >= prev_end_pos:
				# must access .map because start_pos is int
				var entry_match = start_pos_map.get_value(start_pos, true)
				nonoverlapping_start_pos_map.set_value(
					start_pos,
					entry_match,
					true
				)

				var end_pos = start_pos + entry_match.length
				prev_end_pos = end_pos

		nonoverlapping_clause_map[clause] = nonoverlapping_start_pos_map

	return nonoverlapping_clause_map


# Get all Match entries for the given clause, indexed by start position.
func get_navigable_matches(
		clause) -> OrderedDictionary: # : Clause

	var tree_map: OrderedDictionary = \
		OrderedDictionary.ordereddictionary_instantiate()
	tree_map.enable_autosort()

	for memo_key in _get_all_memo_keys():
		if memo_key[INT_CLAUSE_INDEX] == clause:
			tree_map.set_value(
				memo_key[INT_START_POS_INDEX],
				_get_if_exists_or_null(memo_key),
				true
			)

	return tree_map


# Get the Match entries for all matches of this clause.
func get_all_matches(
		clause # : Clause
		) -> Array: # List<Match>

	var matches: Array = [] # ArrayList<Match>
	for entry in get_navigable_matches(clause).values():
		matches.append(entry)

	return matches


# Get the Match entries for all nonoverlapping matches of this clause, obtained
# by greedily matching from the beginning of the string, then looking for the
# next match after the end of the current match.
func get_nonoverlapping_matches(
		clause # : Clause
		) -> Array: # List<Match>

	var matches                : Array = get_all_matches(clause)
	# ArrayList<Match>

	var nonoverlapping_matches : Array = []

	for i in range(matches.size()):
		var _match          = matches[i] # : MemoMatch
		var start_pos : int = _match.memo_key[INT_START_POS_INDEX]
		var end_pos   : int = start_pos + _match.length

		nonoverlapping_matches.append(_match)
		while i < matches.size() - 1 \
				and matches[i + 1].memo_key[INT_START_POS_INDEX] < end_pos:
			i += 1

	return nonoverlapping_matches


# Get any syntax errors in the parse, as a map from start position to a tuple,
# (end position, span of input string between start position and end position).
func get_syntax_errors(
		syntax_coverage_rule_names: Array # String[]
		): # -> OrderedDictionary: # NavigableMap<Integer, Entry<Integer, String>>

	# Find the range of characters spanned by matches for each of the
	# coverageRuleNames
	var parsed_ranges: IntervalUnion = \
		IntervalUnion.intervalunion_instantiate()

	for coverage_rule_name in syntax_coverage_rule_names:
		var rule = grammar.get_rule(coverage_rule_name)

		if rule is Exception:
			return rule

		for _match in get_nonoverlapping_matches(rule.labeled_clause.clause):
			parsed_ranges.add_range(
				_match.memo_key[INT_START_POS_INDEX],
				_match.memo_key[INT_START_POS_INDEX] + _match.length
			)

	# Find the inverse of the parsed ranges -- these are the syntax errors
	var unparsed_ranges: OrderedDictionary = \
		parsed_ranges.invert(0, input.length()).get_nonoverlapping_ranges()

	# Extract the input string span for each unparsed range
	var syntax_error_spans = \
		OrderedDictionary.ordereddictionary_instantiate()
		# TreeMap<Integer, Entry<Integer, String>>
	syntax_error_spans.enable_autosort()

	for unparsed_range_key in unparsed_ranges.sequence:
		var unparsed_range_value: int = \
			unparsed_ranges.get_value(unparsed_range_key, true)
		syntax_error_spans.set_value(
			unparsed_range_key,
			[
				unparsed_range_value,
				input.substr(unparsed_range_key, unparsed_range_value)
			],
			true
		)

	return syntax_error_spans


func _get_all_memo_keys() -> Array:

	var return_value: Array = []

	for clause in _memo_table:
		for start_pos in _memo_table[clause]:
			return_value.append([ clause, start_pos ])

	return return_value


func _get_all_values() -> Array:

	var return_value: Array = []
	for clause in _memo_table:
		for start_pos in _memo_table[clause]:
			return_value.append(_memo_table[clause][start_pos])

	return return_value


func _get_if_exists_or_null(
		memo_key: Array): # -> MemoMatch:

	var clause = Collection.get_if_exists_or_null(
		_memo_table,
		memo_key[INT_CLAUSE_INDEX]
	) # : Clause

	if clause:
		return Collection.get_if_exists_or_null(
			clause,
			memo_key[INT_START_POS_INDEX]
		)

	return null


func _set_value(
		memo_key   : Array,
		memo_match # : MemoMatch
		) -> void:

	if not memo_key[INT_CLAUSE_INDEX] in _memo_table:
		_memo_table[memo_key[INT_CLAUSE_INDEX]] = {}

	_memo_table[
		memo_key[INT_CLAUSE_INDEX]
	][
		memo_key[INT_START_POS_INDEX]
	] = memo_match

