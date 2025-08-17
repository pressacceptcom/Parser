tool
class_name PressAccept_Parser_Pika_LabeledClause

# |=============================|
# |                             |
# |    Press Accept: Parser     |
# | Parsing Algorithms In Godot |
# |                             |
# |=============================|
#
# "A container for grouping a subclause together with its AST node label."
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
# Class                  : LabeledClause
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

# ***************************
# | Public Static Functions |
# ***************************


# wraps Mixin functionality to create a new object, use instead of new()
static func labeledclause_instantiate(
		init_clause         : Clause,
		init_ast_node_label : String
		) -> PressAccept_Parser_Pika_LabeledClause:

	return load('res://addons/PressAccept/Parser/Pika/AST/LabeledClause.gd') \
		.new(
			init_clause,
			init_ast_node_label
		)


# *********************
# | Public Properties |
# *********************

var clause         : Clause

var ast_node_label : String

# **********************
# | Private Properties |
# **********************

# Currently being output (prevents recursion)
var _being_output: bool = false

# ***************
# | Constructor |
# ***************


func _init(
		init_clause         : Clause,
		init_ast_node_label : String
		) -> void:

	clause         = init_clause
	ast_node_label = init_ast_node_label


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
		return "\n" + prefix + 'LabeledClause:' + str(get_instance_id())

	_being_output = true

	var output_str: String = ''
	
	output_str += "\n" + prefix + __get_script() \
		+ ' (' + str(get_instance_id()) + ') ='

	output_str += "\n" + prefix + tab_char + 'clause:'
	if clause:
		output_str += clause.__output(prefix + tab_char + tab_char, tab_char)
	else:
		output_str += ' null'
	output_str += "\n" + prefix + tab_char + 'ast_node_label: ' \
		+ str(ast_node_label)

	_being_output = false
	
	return output_str


# ****************
# | Meta Methods |
# ****************


func __get_script():

	return 'res://addons/PressAccept/Parser/Pika/AST/LabeledClause.gd'


# ******************
# | Public Methods |
# ******************


# Call toString(), prepending any AST node label.
func to_string_with_ast_node_label(
		parent_clause: Clause) -> String:

	if clause == null:
		return 'LabeledClause: ast_node_label = ' + ast_node_label \
			+ ', clause = null'

	var MetaGrammar: Script = \
		load('res://addons/PressAccept/Parser/Pika/Grammar/MetaGrammar.gd') as Script

	var add_parens = parent_clause != null \
		and MetaGrammar\
			.need_to_add_parens_around_subclause(parent_clause, clause)

	if ast_node_label and not add_parens:
		return clause.to_string()

	var return_value: String = ''

	if ast_node_label:
		return_value += ast_node_label + ':'
		add_parens = add_parens \
			or MetaGrammar.need_to_add_parens_around_ast_node_label(clause)

	if add_parens:
		return_value += '('

	return_value += clause.to_string()

	if add_parens:
		return_value += ')'

	return return_value


func to_string() -> String:

	return to_string_with_ast_node_label(null)

