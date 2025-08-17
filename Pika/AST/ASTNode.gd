tool
class_name PressAccept_Parser_Pika_ASTNode

# |=============================|
# |                             |
# |    Press Accept: Parser     |
# | Parsing Algorithms In Godot |
# |                             |
# |=============================|
#
# "A node in the Abstract Syntax Tree (AST)."
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
# Class                  : ASTNode
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

const Error     : Script = PressAccept_Error_Error
const Exception : Script = PressAccept_Error_Exception

const Mixer: Script = PressAccept_Mixer_Mixer

const Throwable: Script = PressAccept_Utilizer_Mixins_Throwable
const THROWABLE: String = Throwable.STR_MIXIN_IDENTIFIER

# |-------------|
# | Parser/Pika |
# |-------------|

const MemoMatch: Script = PressAccept_Parser_Pika_Match
const MemoTable: Script = PressAccept_Parser_Pika_MemoTable

const TreeUtilities: Script = PressAccept_Parser_Pika_TreeUtilities

# *************************
# | Meta Static Functions |
# *************************


# this is made up of the following mixins
static func __mixed_info() -> Array:

	return [
		# throwable dependency
		'res://addons/PressAccept/Conductor/Conductable.gd',
		# mixins
		'res://addons/PressAccept/Utilizer/Mixins/Throwable.gd'
	]


# ***************************
# | Public Static Functions |
# ***************************


# wraps Mixin functionality to create a new object, use instead of new()
static func astnode_instantiate(
		init_label     : String,
		init_node_type, # : Clause,
		init_start_pos : int,
		init_length    : int,
		init_input     : String) -> PressAccept_Parser_Pika_ASTNode:

	return Mixer.instantiate(
		'res://addons/PressAccept/Parser/Pika/AST/ASTNode.gd',
		[
			init_label,
			init_node_type,
			init_start_pos,
			init_length,
			init_input
		],
		true
	)


# Recursively create an AST from a parse tree.
static func astnode_instantiate_recursively(
		init_label: String,
		init_match: MemoMatch,
		init_input: String) -> void:

	var this: PressAccept_Parser_Pika_ASTNode = \
		astnode_instantiate(
			init_label,
			init_match.memo_key[MemoTable.INT_CLAUSE_INDEX],
			init_match.memo_key[MemoTable.INT_START_POS_INDEX],
			init_match.length,
			init_input
		)

	add_nodes_with_ast_node_labels_recursive(this, init_match, init_input)


# Recursively convert a match node to an AST node.
static func add_nodes_with_ast_node_labels_recursive(
		parent_ast_node : PressAccept_Parser_Pika_ASTNode,
		parent_match    : MemoMatch,
		input           : String) -> void:

	# Recurse to descendants
	var subclause_matches_to_use = parent_match.get_subclause_matches()
	for subclause_match_entry in subclause_matches_to_use:
		var subclause_ast_node_label = subclause_match_entry[0]
		var subclause_match = subclause_match_entry[1]
		if subclause_ast_node_label:
			# Create an AST node for any labeled sub-clauses
			parent_ast_node.children.append(
				astnode_instantiate_recursively(
					subclause_ast_node_label,
					subclause_match,
					input
				)
			)
		else:
			# Do not add an AST node for parse tree nodes that are not labeled;
			# however, still need to recurse to their subclause matches
			add_nodes_with_ast_node_labels_recursive(
				parent_ast_node,
				subclause_match,
				input
			)


# *********************
# | Public Properties |
# *********************

var label: String

var node_type # : Clause

var start_pos: int

var length: int

var input: String

var children: Array

# **********************
# | Private Properties |
# **********************

# Currently being output (prevents recursion)
var _being_output: bool = false

# ***************
# | Constructor |
# ***************


func __init(
		init_label     : String,
		init_node_type, # : Clause,
		init_start_pos : int,
		init_length    : int,
		init_input     : String) -> void:

	label     = init_label
	node_type = init_node_type
	start_pos = init_start_pos
	length    = init_length
	input     = init_input


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
		return "\n" + prefix + 'ASTNode:' + str(get_instance_id())

	_being_output = true

	var output_str: String = ''

	output_str += "\n" + prefix + __get_script() \
		+ ' (' + str(get_instance_id()) + ') ='

	output_str += self[CONDUCTABLE].__output(prefix + tab_char, tab_char)
	output_str += self[THROWABLE].__output(prefix + tab_char, tab_char)

	output_str += "\n" + prefix + tab_char + 'label: ' + label
	output_str += "\n" + prefix + tab_char + 'start_pos: ' + str(start_pos)
	output_str += "\n" + prefix + tab_char + 'length: ' + str(length)
	if node_type:
		output_str += node_type.__output(prefix + tab_char, tab_char)
	else:
		output_str += "\n" + prefix + tab_char + 'node_type: null'

	output_str += "\n" + prefix + tab_char + 'children:'
	for element in children:
		if element is Object and element.has_method('__output'):
			output_str += \
				element.__output(prefix + tab_char + tab_char, tab_char)
		else:
			output_str += "\n" + prefix + tab_char + tab_char + str(element)

	_being_output = false
	
	return output_str


# ****************
# | Meta Methods |
# ****************


func __get_script():

	return 'res://addons/PressAccept/Parser/Pika/AST/ASTNode.gd'


# ******************
# | Public Methods |
# ******************


func get_child(
		index: int) -> PressAccept_Parser_Pika_ASTNode:

	if children.size() < index:
		self[THROWABLE].throw(
			{
				Exception.STR_EXCEPTION_CODE    : 'Illegal Argument',
				Exception.STR_EXCEPTION_MESSAGE : \
					'Expected at least ' + str(index) + ' children'
			},
			Error
		)

	return children[index]


func get_text() -> String:

	return input.substr(start_pos, length)


func to_string() -> String:

	return TreeUtilities.render_tree_view_ast(self, input, '', true)

