tool
class_name PressAccept_Parser_Pika_Rule

# |=============================|
# |                             |
# |    Press Accept: Parser     |
# | Parsing Algorithms In Godot |
# |                             |
# |=============================|
#
# "A grammar rule."
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
# Class                  : Rule
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

# ****************
# | Enumerations |
# ****************

enum ASSOCIATIVITY {
	LEFT,
	RIGHT
}

# ***************************
# | Public Static Functions |
# ***************************


# wraps Mixin functionality to create a new object, use instead of new()
static func rule_instantiate(
		init_rule_name  : String,
		init_clause, # : Clause,
		init_precedence : int = -1,
		init_associativity    = null) -> PressAccept_Parser_Pika_Rule:

	return load('res://addons/PressAccept/Parser/Pika/Grammar/Rule.gd') \
		.new(
			init_rule_name,
			init_clause,
			init_precedence,
			init_associativity
		)


# *********************
# | Public Properties |
# *********************

# The name of the rule.
var rule_name: String

# The precedence of the rule, or -1 for no specified precedence.
var precedence: int

# The associativity of the rule, or null for no specified associativity.
var associativity

# The toplevel clause of the rule, and any associated AST node label.
var labeled_clause # : LabeledClause

# *********************#
# | Private Properties |
# *********************#

var _being_output: bool = false

# ***************
# | Constructor |
# ***************

# Construct a rule with specified precedence and associativity.
#
# if only first two arguments provided:
#
#    Construct a rule with no specified precedence or associativity.
#
#    Use precedence of -1 for rules that only have one precedence
#    (this causes the precedence number not to be shown in the output of
#     toStringWithRuleNames())
func _init(
		init_rule_name  : String,
		init_clause, # : Clause,
		init_precedence : int = -1,
		init_associativity    = null) -> void:

	rule_name = init_rule_name
	precedence = init_precedence
	associativity = init_associativity

	var ASTNodeLabel: Script = \
		load('res://addons/PressAccept/Parser/Pika/Clauses/Resource/ASTNodeLabel.gd') as Script
	var LabeledClause: Script = \
		load('res://addons/PressAccept/Parser/Pika/AST/LabeledClause.gd') as Script
	var ast_node_label: String
	var clause_to_use = init_clause # : Clause
	if init_clause is ASTNodeLabel:
		# Transfer ASTNodeLabel.astNodeLabel to astNodeLabel
		ast_node_label = init_clause.ast_node_label
		# skip over ASTNodeLabel node when adding subClause to subClauses array
		clause_to_use = init_clause.labeled_subclauses[0].clause
	labeled_clause = LabeledClause.labeledclause_instantiate(
		clause_to_use,
		ast_node_label
	)


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

	output_str += "\n" + prefix + tab_char + 'rule_name: ' + rule_name
	output_str += "\n" + prefix + tab_char + 'precedence: ' + str(precedence)
	output_str += "\n" + prefix + tab_char + 'associativity: ' \
		+ str(associativity)
	output_str += labeled_clause.__output(prefix + tab_char, tab_char) \
		if labeled_clause else ''

	_being_output = false
	
	return output_str


# ****************
# | Meta Methods |
# ****************


func __get_script():

	return 'res://addons/PressAccept/Parser/Pika/Grammar/Rule.gd'


# ******************
# | Public Methods |
# ******************


func to_string() -> String:

	return rule_name + ' <- ' + labeled_clause.to_string()

