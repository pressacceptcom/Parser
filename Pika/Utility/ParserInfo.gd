tool
class_name PressAccept_Parser_Pika_ParserInfo

# |=============================|
# |                             |
# |    Press Accept: Parser     |
# | Parsing Algorithms In Godot |
# |                             |
# |=============================|
#
# "Utility methods for printing information about the result of a parse."
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
# Class                  : ParserInfo
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

const Error     : Script = PressAccept_Error_Error
const Exception : Script = PressAccept_Error_Exception

const OrderedDictionary: Script = PressAccept_Utilizer_Data_OrderedDictionary

# |-------------|
# | Parser/Pika |
# |-------------|

const ASTNode: Script = PressAccept_Parser_Pika_ASTNode

const Clause: Script = PressAccept_Parser_Pika_Clause

const IntervalUnion: Script = PressAccept_Parser_Pika_IntervalUnion

const MemoKey   : Script = PressAccept_Parser_Pika_MemoKey
const MemoMatch : Script = PressAccept_Parser_Pika_Match
const MemoTable : Script = PressAccept_Parser_Pika_MemoTable

# const Grammar: Script = PressAccept_Parser_Pika_Grammar

const Rule: Script = PressAccept_Parser_Pika_Rule

const Seq: Script = PressAccept_Parser_Pika_Seq

const Terminal: Script = PressAccept_Parser_Pika_Terminal

const TreeUtilities: Script = PressAccept_Parser_Pika_TreeUtilities

# ***************************
# | Public Static Functions |
# ***************************


# Print all the clauses in a grammar.
static func print_clauses(
		grammar # : Grammar
		) -> void:

	for i in range(grammar.all_clauses.size() - 1, -1, -1):
		var clause: Clause = grammar.all_clauses[i]
		print(str(i) + ' : ' + clause.to_string_with_rule_names())


# Print the memo table.
static func print_memo_table(
		memo_table: MemoTable) -> void:

	var strings      : Array = []
	strings.resize(memo_table.grammar.all_clauses.size())

	var margin_width : int = 0
	for i in range(memo_table.grammar.all_clauses.size()):
		strings[i] = ''
		strings[i] += str(memo_table.grammar.all_clauses.size() - 1 - i) + ' : '
		var clause: Clause = \
			memo_table.grammar.all_clauses[
				memo_table.grammar.all_clauses.size() - 1 - i
			]
		if clause is Terminal:
			strings[i] += '[terminal] '
		if clause.can_match_zero_chars:
			strings[i] += '[can_match_zero_chars] '
		strings[i] += clause.to_string_with_rule_names()
		margin_width = max(margin_width, strings[i].length() + 2)

	var table_width = margin_width + memo_table.input.length() + 1
	for i in range(memo_table.grammar.all_clauses.size()):
		while strings[i].length() < margin_width:
			strings[i] += ' '
		while strings[i].length() < table_width:
			strings[i] += '-'

	# Map<Clause, NavigableMap<Integer, Match>>
	var nonoverlapping_matches: Dictionary = \
		memo_table.get_all_nonoverlapping_matches()

	for clause_index in range(memo_table.grammar.all_clauses.size() - 1, -1, -1):
		var row                = \
			memo_table.grammar.all_clauses.size() - 1 - clause_index
		var clause             = memo_table.grammar.all_clauses[clause_index]
		var matches_for_clause: OrderedDictionary = \
			Collection.get_if_exists_or_null(
				nonoverlapping_matches,
				clause
			)

		if matches_for_clause:
			for match_entry in matches_for_clause.values():
				var match_start_pos = match_entry.memo_key[MemoTable.INT_START_POS_INDEX]
				var match_end_pos   = match_start_pos + match_entry.length

				if match_start_pos <= memo_table.input.length():
					strings[row][margin_width + match_start_pos] = '#'
					for j in range(match_start_pos + 1, match_end_pos):
						if j <= memo_table.input.length():
							strings[row][margin_width + j] = '='

		print(strings[row])

	var print_value: String = ''
	
	for j in range(margin_width):
		print_value += ' '

	for i in range(memo_table.input.length()):
		print_value += str(i % 10)

	print(print_value)

	print_value = ''
	for i in range(margin_width):
		print_value += ' '

	print(print_value + memo_table.input)


# Print the parse tree in memo table form.
static func print_parse_tree_in_memo_table_form(
		memo_table: MemoTable): # -> void:

	if memo_table.grammar.all_clauses.size() == 0:
		return Exception.create(
			{
				Exception.STR_EXCEPTION_CODE    : 'Illegal Argument',
				Exception.STR_EXCEPTION_MESSAGE : 'Grammar is empty'
			},
			Error
		)

	var return_value: String = ''

	# Map from cycle depth (sorted in decreasing
	# order) -> clauseIdx -> startPos -> match
	var cycle_depth_to_matches: OrderedDictionary = \
		OrderedDictionary.ordereddictionary_instantiate()
	cycle_depth_to_matches.enable_autosort()
	cycle_depth_to_matches.enable_reverse_order()

	# Input spanned by matches found so far
	var input_spanned: IntervalUnion = IntervalUnion.intervalunion_instantiate()

	# Get all nonoverlapping matches rules, top-down.
	var nonoverlapping_matches: Dictionary = \
		memo_table.get_all_nonoverlapping_matches()
		# Map<Clause, NavigableMap<Integer, Match>>

	var max_cycle_depth: int = 0
	for clause_index in range(memo_table.grammar.all_clauses.size() - 1, -1, -1):
		var clause: Clause     = memo_table.grammar.all_clauses[clause_index]
		var matches_for_clause = \
			Collection.get_if_exists_or_null(nonoverlapping_matches, clause)

		if matches_for_clause:
			for match_entry in matches_for_clause.values():
				var match_start_pos : int = match_entry.memo_key[MemoTable.INT_START_POS_INDEX]
				var match_end_pos   : int = \
					match_start_pos + match_entry.length

				# Only add parse tree to chart if it doesn't overlap with input
				# spanned by a higher-level match
				if not input_spanned.range_overlaps(
						match_start_pos, match_end_pos):
					# Pack matches into the lowest cycle they will fit into
					var cycle_depth: int = _find_cycle_depth(
						match_entry,
						cycle_depth_to_matches
					)

					max_cycle_depth = max(max_cycle_depth, cycle_depth)

					# Add the range spanned by this match
					input_spanned.add_range(match_start_pos, match_end_pos)

	# Assign matches to rows
	var matches_for_row : Array = [] # List<Map<Integer, Match>>
	var clause_for_row  : Array = [] # List<Clause>

	for matches_for_depth in cycle_depth_to_matches.values():
		for matches_for_clause_index_entry in matches_for_depth.sequence:
			clause_for_row.append(
				memo_table.grammar.all_clauses.get_value(
					matches_for_clause_index_entry,
					true
				)
			)

			matches_for_row.append(
				matches_for_depth.get_value(
					matches_for_clause_index_entry,
					true
				)
			)

	# Set up row labels
	var row_label           : Array  = []
	row_label.resize(clause_for_row.size())
	var row_label_max_width : int    = 0

	for i in range(clause_for_row.size()):
		var clause: Clause = clause_for_row[i]

		row_label[i] = ''
		if clause is Terminal:
			row_label[i] += '[terminal] '
		if clause.can_match_zero_chars:
			row_label[i] + '[can_match_zero_chars] '
		row_label[i] += clause.to_string_with_rule_names()
		row_label_max_width = max(row_label_max_width, row_label[i].length())

	for i in range(clause_for_row.size()):
		var clause       : Clause = clause_for_row[i]
		var clause_index : int = clause.clause_index

		# Right-justify the row label
		var jj: int = row_label_max_width - row_label[i].length()
		for j in range(jj):
			row_label[i] = ' ' + row_label[i]
		row_label[i] = str(clause_index) + ' : ' + row_label[i]

	var empty_row_label: String = ''
	for i in range(row_label_max_width + 6):
		empty_row_label += ' '

	var edge_markers: String = ''
	edge_markers += ' '
	for i in range(1, memo_table.input.length() * 2):
		edge_markers += "\u2591"

	# Append one char for last column boundary, and two extra chars for
	# zero-length matches past end of string
	edge_markers += '   '

	# Add tree structure to right of row label
	for row in range(clause_for_row.size()):
		var matches        : OrderedDictionary = matches_for_row[row]
		var row_tree_chars : String            = ''

		row_tree_chars += edge_markers

		var zero_len_match_indexes: Array = [] # ArrayList<Integer>
		for _match in matches.values():
			var start_index : int = _match.memo_key[MemoTable.INT_START_POS_INDEX]
			var end_index   : int = start_index + _match.length

			if start_index == end_index:
				# Zero-length match
				zero_len_match_indexes.append(start_index)
			else:
				# Match consumes 1 or more characters
				for i in range(start_index, end_index + 1):
					var char_left: String = row_tree_chars[i * 2]
					row_tree_chars[i * 2] = (
						('├' if char_left == '│' \
							else ('┼' if char_left == '┤' \
								else ('┬' if char_left == '┐' \
									else '┌')
								)
						) if i == start_index \
							else (('┤' if char_left == '│' \
								else '┐') if i == end_index \
									else '─'
							)
					)

					if i < end_index:
						row_tree_chars[i * 2 + 1] = '─'

		return_value += empty_row_label
		return_value += row_tree_chars + "\n"

		for _match in matches.values():
			var start_index : int = _match.memo_key[MemoTable.INT_START_POS_INDEX]
			var end_index   : int = start_index + _match.length

			edge_markers[start_index * 2] = '│'
			edge_markers[end_index * 2] = '│'

			for i in range(start_index * 2 + 1, end_index * 2):
				var c: String = edge_markers[i]

				if c == '░' or c == '│':
					edge_markers[i] = ' '

		row_tree_chars = ''
		row_tree_chars += edge_markers

		for _match in matches.values():
			var start_index : int = _match.memo_key[MemoTable.INT_START_POS_INDEX]
			var end_index   : int = start_index + _match.length

			for i in range(start_index, end_index):
				row_tree_chars[i * 2 + 1] = memo_table.input[i]

		for zero_len_match_index in zero_len_match_indexes:
			row_tree_chars[zero_len_match_index * 2] = '▮'

		return_value += row_label[row]
		return_value += row_tree_chars + "\n"

	# Print input index digits

	for j in range(row_label_max_width + 6):
		return_value += ' '

	return_value += ' '

	for i in range(memo_table.input.length()):
		return_value += str(i % 10) + ' '

	return_value += "\n"

	# Print input string
	for i in row_label_max_width + 6:
		return_value += ' '

	return_value += ' '

	for i in range(memo_table.input.length()):
		return_value += memo_table.input[i]
		return_value += ' '

	return_value += "\n"

	print(return_value)


# Print syntax errors obtained from MemoTable#getSyntaxErrors(String...).
static func print_syntax_errors(
		syntax_errors: OrderedDictionary # NavigableMap<Integer, Entry<Integer, String>>
		) -> void:

	var return_value: String = ''

	if not syntax_errors.empty():
		return_value += "\nSYNTAX ERRORS\n"
		for entry_key in syntax_errors.sequence:
			var start_pos        : int    = entry_key
			var end_pos          : int    = \
				syntax_errors.get_value(entry_key, true)[0]
			var syntax_error_str : String = \
				syntax_errors.get_value(entry_key, true)[1]

			# TODO: show line numbers
			print(str(start_pos) + '+' + str(end_pos - start_pos) + ' : ' \
				+ syntax_error_str)


# Print matches in the memo table for a given clause.
static func print_matches(
		clause           : Clause,
		memo_table       : MemoTable,
		show_all_matches : bool) -> void:

	var matches: Array = memo_table.get_all_matches(clause)

	if not matches.empty():
		print("\n====================================\n\nMatches for "
			+ clause.to_string_with_rule_names() + ' :')

		# Get toplevel AST node label(s), if present
		var ast_node_label: String = ''

		if clause.rules:
			for rule in clause.rules:
				if rule.labeled_clause.ast_node_label:
					if ast_node_label:
						ast_node_label += ':'
					ast_node_label += rule.labeled_clause.ast_node_label

		var prev_end_pos: int = -1
		for _match in matches:
			# Indent matches that overlap with previous longest match
			var overlaps_prev_match = _match.memo_key.start_pos < prev_end_pos
			if not overlaps_prev_match or show_all_matches:
				var indent : String = '    ' if overlaps_prev_match else ''
				var buf    : String = ''

				buf += TreeUtilities.render_tree_view(
					_match,
					null if ast_node_label.empty() else ast_node_label,
					memo_table.input,
					indent,
					true
				)

				print(buf)

			var new_end_pos: int = _match.memo_key[MemoTable.INT_START_POS_INDEX] + _match.length
			if new_end_pos > prev_end_pos:
				prev_end_pos = new_end_pos

	else:
		print("\n====================================\n\nNo matches for " \
			+ clause.to_string_with_rule_names())


# Print matches in the memo table for a given clause and its subclauses.
static func print_matches_and_subclause_matches(
		clause     : Clause,
		memo_table : MemoTable) -> void:

	print_matches(clause, memo_table, true)
	for subclause in clause.labeled_subclauses:
		print_matches(subclause.clause, memo_table, true)


# Print matches in the memo table for a given Seq clause and its subclauses,
# including partial matches of the Seq.
static func print_matches_and_partial_matches(
		seq_clause: Seq,
		memo_table: MemoTable) -> void:

	var num_subclauses: int = seq_clause.labeled_subclauses.size()

	for subclause_0_match in \
			memo_table.get_all_matches(seq_clause.labeled_subclauses[0].clause):
		var subclause_matches: Array = [] # ArrayList<Match>

		subclause_matches.append(subclause_0_match)
		var curr_start_pos = \
			subclause_0_match.memo_key[MemoTable.INT_START_POS_INDEX] + subclause_0_match.length
		for i in range(1, num_subclauses):
			var subclause_i_match = memo_table.lookup_best_match(
				MemoKey.memokey_instantiate(
					seq_clause.labeled_subclauses[i].clause,
					curr_start_pos
				)
			)

			if subclause_i_match == null:
				break

			subclause_matches.append(subclause_i_match)

		print("\n====================================\n\nMatched " \
			+ ('all subclauses' if subclause_matches.size() == num_subclauses \
				else str(subclause_matches.size()) + " out of " \
					+ str(num_subclauses) + " subclauses") \
			+ " of clause (" + seq_clause.to_string() + ") at start pos " \
			+ subclause_0_match.memo_key[MemoTable.INT_START_POS_INDEX])

		print('')

		for i in range(subclause_matches.size()):
			var subclause_match : MemoMatch  = subclause_matches[i]

			print(
				TreeUtilities.render_tree_view(
					subclause_match,
					seq_clause.labeled_subclauses[i].ast_node_label,
					memo_table.input,
					'',
					true
				)
			)


# Print the AST for a given clause.
static func print_ast(
		ast_node_label : String,
		clause         : Clause,
		memo_table     : MemoTable) -> void:

	var matches = memo_table.get_nonoverlapping_matches(clause)

	for _match in matches:
		var ast: ASTNode = ASTNode.astnode_instantiate(
			ast_node_label,
			_match,
			memo_table.input
		)

		print(ast.to_string())


# Summarize a parsing result.
static func print_parse_result(
		top_level_rule_name        : String,
		memo_table                 : MemoTable,
		syntax_coverage_rule_names : Array,
		show_all_matches           : bool) -> void:

	var return_value: String = ''

	print("\nClauses:")
	print_clauses(memo_table.grammar)

	print("\nMemo Table:")
	print_memo_table(memo_table)

	# Print memo table
	print("\nMatch tree for rule " + top_level_rule_name + ':')
	print_parse_tree_in_memo_table_form(memo_table)

	# Print all matches for each clause
	for clause in memo_table.grammar.all_clauses:
		print_matches(clause, memo_table, show_all_matches)

	var rule: Rule = Collection.get_if_exists_or_null(
		memo_table.grammar.rule_name_with_precedence_to_rule,
		top_level_rule_name
	)

	if rule:
		print("\n====================================\n\nAST for rule \"" \
			+ top_level_rule_name + "\":\n")
		var rule_clause: Clause = rule.labeled_clause.clause
		print_ast(top_level_rule_name, rule_clause, memo_table)
	else:
		print("\nRule \"" + top_level_rule_name + "\" does not exist")

	var syntax_errors: OrderedDictionary = \
		memo_table.get_syntax_errors(syntax_coverage_rule_names)

	if not syntax_errors.empty():
		print_syntax_errors(syntax_errors)

	print("\nNum match objects created: " \
		+ str(memo_table.num_match_objects_created))
	print('Num match objects memoized:  ' \
		+ str(memo_table.num_match_objects_memoized))


# ****************************
# | Private Static Functions |
# ****************************


# Find the cycle depth of a given match (the maximum number of grammar cycles
# in any path between the match and any descendant terminal match).
static func _find_cycle_depth(
		memo_match             : MemoMatch,
		cycle_depth_to_matches : OrderedDictionary # Map<Integer, Map<Integer, Map<Integer, Match>>>
		) -> int:

	var cycle_depth: int = 0
	for subclause_match in memo_match.get_subclause_matches():
		var subclause_is_in_different_cycle = \
			memo_match.memo_key[MemoTable.INT_CLAUSE_INDEX].clause_index \
				<= subclause_match.memo_key[MemoTable.INT_CLAUSE_INDEX].clause_index
		var subclause_match_depth = _find_cycle_depth(
			subclause_match,
			cycle_depth_to_matches
		)

		cycle_depth = max(
			cycle_depth,
			subclause_match_depth + 1 \
				if subclause_is_in_different_cycle \
				else subclause_match_depth
		)

	if not cycle_depth_to_matches.contains(cycle_depth):
		var value: OrderedDictionary = \
			OrderedDictionary.ordereddictionary_instantiate()
		value.enable_autosort()
		value.enable_reverse_order()
		cycle_depth_to_matches.set_value(cycle_depth, value, true)

	var matches_for_depth = cycle_depth_to_matches.get_value(cycle_depth, true)

	var index: int = memo_match.memo_key[MemoTable.INT_CLAUSE_INDEX].clause_index
	if not matches_for_depth.contains(index):
		var value: OrderedDictionary = \
			OrderedDictionary.ordereddictionary_instantiate()
		value.enable_autosort()
		matches_for_depth.set_value(index, value, true)

	var matches_for_clause_index = matches_for_depth.get_value(index, true)
	matches_for_clause_index \
		.set_value(memo_match.memo_key[MemoTable.INT_START_POS_INDEX], memo_match, true)

	return cycle_depth

