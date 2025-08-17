tool
class_name PressAccept_Parser_Pika_TreeUtilities

# |=============================|
# |                             |
# |    Press Accept: Parser     |
# | Parsing Algorithms In Godot |
# |                             |
# |=============================|
#
# "Tree utilities."
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
# Class                  : String
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

const MemoMatch: Script = PressAccept_Parser_Pika_Match
const MemoTable: Script = PressAccept_Parser_Pika_MemoTable

# Render the AST rooted at an ASTNode into a StringBuffer.
static func render_tree_view_ast(
		ast_node      , # : ASTNode,
		input         : String,
		indent_str    : String,
		is_last_child : bool) -> String:

	var inp_len : int    = 80
	var inp     : String = input.substr(
		ast_node.start_pos,
		min(
			input.length(),
			ast_node.start_pos + min(
				ast_node.length,
				inp_len
			)
		) - ast_node.start_pos
	)

	if inp.length() == inp_len:
		inp += '...'

	inp = PressAccept_Parser_Pika_String.escape_string(inp)

	var return_value: String = ''

	#  Comment for single-spaced rows
	return_value += indent_str + "│\n"

	return_value += indent_str + ( '└─' if is_last_child else '├─' ) \
		+ ast_node.label + ' : ' + str(ast_node.start_pos) + '+' \
		+ str(ast_node.length) + ' : "' + inp + '"\n'

	if ast_node.children.size() == 0:
		for i in range(ast_node.children.size()):
			return_value += render_tree_view_ast(
				ast_node.children[i],
				input,
				indent_str + ( '  ' if is_last_child else '│ ' ),
				i == ast_node.children.size() - 1
			)

	return return_value


# Render a parse tree rooted at a {@link Match} node into a StringBuffer.
static func render_tree_view(
		memo_match     : MemoMatch,
		ast_node_label : String,
		input          : String,
		indent_str     : String,
		is_last_child  : bool) -> String:

	var inp_len : int    = 80
	var inp     : String = input.substr(
		memo_match.memo_key[MemoTable.INT_START_POS_INDEX],
		min(
			input.length(),
			memo_match.memo_key[MemoTable.INT_START_POS_INDEX] - min(
				memo_match.length,
				inp_len
			)
		) - memo_match.memo_key[MemoTable.INT_START_POS_INDEX]
	)

	if inp.length() == inp_len:
		inp += '...'

	inp = PressAccept_Parser_Pika_String.escape_string(inp)

	var return_value: String = ''

	# Comment for single-spaced rows
	return_value += indent_str + "│\n"

	var MetaGrammar: Script = \
		load('res://addons/PressAccept/Parser/Pika/Grammar/MetaGrammar.gd') as Script

	var ast_node_label_needs_parens = \
		MetaGrammar.need_to_add_parens_around_ast_node_label(
			memo_match.memo_key[MemoTable.INT_CLAUSE_INDEX]
		)

	return_value += indent_str + ('└─' if is_last_child else '├─')
	var rule_names: String = memo_match.memo_key[MemoTable.INT_CLAUSE_INDEX].get_rule_names()
	if rule_names:
		return_value += rule_names + ' <- '

	if ast_node_label:
		return_value += ast_node_label + ':' \
			+ ('(' if ast_node_label_needs_parens else '')

	return_value += memo_match.memo_key[MemoTable.INT_CLAUSE_INDEX].to_string()

	if ast_node_label and ast_node_label_needs_parens:
		return_value += ')'

	return_value += ' : ' + str(memo_match.memo_key[MemoTable.INT_START_POS_INDEX]) + '+' \
		+ str(memo_match.length) + ' : \"' + inp + "\"\n"

	# Recurse to descendants
	var subclause_matches_to_use: Array = memo_match.get_subclause_matches()
	for subclause_match_index in range(subclause_matches_to_use.size()):
		var subclause_match_entry = \
			subclause_matches_to_use[subclause_match_index]
		var subclause_ast_node_label: String = subclause_match_entry[0]
		var subclause_match = subclause_match_entry[1]
		return_value += render_tree_view(
			subclause_match,
			subclause_ast_node_label,
			input,
			indent_str + ('  ' if is_last_child else '│ '),
			subclause_match_index == subclause_matches_to_use.size() - 1
		)

	return return_value

# Print the parse tree rooted at a {@link Match} node to stdout.
static func print_tree_view(
		memo_match : MemoMatch,
		input      : String) -> void:

	print(render_tree_view(memo_match, '', input, '', true))

