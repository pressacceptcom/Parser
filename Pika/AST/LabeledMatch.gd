tool
class_name PressAccept_Parser_Pika_LabeledMatch

# |=============================|
# |                             |
# |    Press Accept: Parser     |
# | Parsing Algorithms In Godot |
# |                             |
# |=============================|
#
# "A container for grouping a subclause match together with its AST node label."
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
# Class                  : LabeledMatch
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

const MemoMatch: Script = PressAccept_Parser_Pika_Match

# ***************************
# | Public Static Functions |
# ***************************


# wraps Mixin functionality to create a new object, use instead of new()
static func labeledmatch_instantiate(
		init_match          : MemoMatch,
		init_ast_node_label : String) -> PressAccept_Parser_Pika_LabeledMatch:

	return load('res://addons/PressAccept/Parser/Pika/AST/LabeledMatch.gd') \
		.new(
			init_match,
			init_ast_node_label
		)


# *********************
# | Public Properties |
# *********************

var memo_match     : MemoMatch

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
		init_match          : MemoMatch,
		init_ast_node_label : String) -> void:

	memo_match     = init_match
	ast_node_label = init_ast_node_label


# ********************
# | Built-In Methods |
# ********************


# display this array as a pretty-printed string
func _to_string() -> String:

	return __output('')


# pretty print the internal info prefaced by, and using a whitespace
func __output(
		prefix   : String,
		tab_char : String = "\t") -> String:

	if _being_output:
		return "\n" + prefix + 'LabeledMatch:' + str(get_instance_id())

	_being_output = true

	var output_str: String = ''
	
	output_str += "\n" + prefix + __get_script() \
		+ ' (' + str(get_instance_id()) + ') ='

	output_str += "\n" + prefix + tab_char \
		+ 'ast_node_label: ' + ast_node_label
	if memo_match:
		output_str += memo_match.__output(prefix + tab_char, tab_char)
	else:
		output_str += "\n" + prefix + tab_char + 'memo_match: null'

	_being_output = false
	
	return output_str


# ****************
# | Meta Methods |
# ****************


func __get_script():

	return 'res://addons/PressAccept/Parser/Pika/AST/LabeledMatch.gd'


# ******************
# | Public Methods |
# ******************


func to_string() -> String:

	if memo_match == null:
		return ast_node_label + ': memo_match = null' \
			if ast_node_label \
			else 'LabeledMatch: ast_node_label = "", memo_match = null'

	return ast_node_label + ':(' + memo_match.to_string() + ')' \
		if ast_node_label \
		else memo_match.to_string()

