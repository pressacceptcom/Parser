tool
class_name PressAccept_Parser_Pika_Clause

# |=============================|
# |                             |
# |    Press Accept: Parser     |
# | Parsing Algorithms In Godot |
# |                             |
# |=============================|
#
# "Abstract superclass of all PEG operators and terminals."
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
# Class                  : Clause
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

const Comparable: Script = PressAccept_Utilizer_Mixins_Comparable
const COMPARABLE: String = Comparable.STR_MIXIN_IDENTIFIER

const Comparator: Script     = PressAccept_Comparator_Comparator
const DictComparator: Script = PressAccept_Comparator_Dictionary

const Conductable: Script = PressAccept_Conductor_Conductable
const CONDUCTABLE: String = Conductable.STR_MIXIN_IDENTIFIER

const Error     : Script = PressAccept_Error_Error
const Exception : Script = PressAccept_Error_Exception

const Mixer: Script = PressAccept_Mixer_Mixer

const Normalizer: Script = PressAccept_Normalizer_Normalizer

const Throwable: Script = PressAccept_Utilizer_Mixins_Throwable
const THROWABLE: String = Throwable.STR_MIXIN_IDENTIFIER

# |-------------|
# | Parser/Pika |
# |-------------|

const MemoTable : Script = PressAccept_Parser_Pika_MemoTable
const MemoKey   : Script = PressAccept_Parser_Pika_MemoKey
const MemoMatch : Script = PressAccept_Parser_Pika_Match

const Rule: Script = PressAccept_Parser_Pika_Rule

# ********************
# | Internal Classes |
# ********************

class ClauseComparator:
	extends Comparator


	static func __get_script() -> String:

		return 'res://addons/PressAccept/Parser/Pika/Clauses/Clause.gd'


	# by_ref is true for dictionaries, clauses will match references
	static func compare(
			a,
			b,
			by_ref: bool = false) -> int:

		var Self: Script = \
			load('res://addons/PressAccept/Parser/Pika/Clauses/Clause.gd') as Script

		if a is Self and b is Self:
			if a.clause_index == b.clause_index:
				return Comparator.ENUM_RELATION.EQUAL
			elif a.clause_index > b.clause_index:
				return Comparator.ENUM_RELATION.GREATER_THAN
			else:
				return Comparator.ENUM_RELATION.LESS_THAN

		return Comparator.compare(a, b, by_ref)


	# test whether two entities are equivalent
	static func equals(
			a,
			b,
			by_ref: bool = false) -> bool:

		return compare(a, b, by_ref) == Comparator.ENUM_RELATION.EQUAL


	# test whether a is less than b
	static func less_than(
			a,
			b) -> bool:

		return compare(a, b) == Comparator.ENUM_RELATION.LESS_THAN


	# test whether a is less than or equal to b
	static func less_than_or_equal(
			a,
			b) -> bool:

		var comparison: int = compare(a, b)

		return comparison == Comparator.ENUM_RELATION.LESS_THAN \
			or comparison == Comparator.ENUM_RELATION.EQUAL


	# test whether a is greater than b
	static func greater_than(
			a,
			b) -> bool:

		return compare(a, b) == Comparator.ENUM_RELATION.GREATER_THAN


	# test whether a is greater than or equal to b
	static func greater_than_or_equal(
			a,
			b) -> bool:

		var comparison: int = compare(a, b)

		return comparison == Comparator.ENUM_RELATION.GREATER_THAN \
			or comparison == Comparator.ENUM_RELATION.EQUAL


	# normalize a value in relation to the comparison method
	static func transform(
			value):

		return value


# *************
# | Constants |
# *************

# init argument key
const STR_SUBCLAUSES: String = 'clause_subclauses'

# __to_dict keys
const STR_LABELED_SUBCLAUSES_KEY   : String = 'labeled_subclauses'
const STR_RULES_KEY                : String = 'rules'
const STR_SEED_PARENT_CLAUSES_KEY  : String = 'seed_parent_clauses'
const STR_CAN_MATCH_ZERO_CHARS_KEY : String = 'can_match_zero_chars'
const STR_CLAUSE_INDEX_KEY         : String = 'clause_index'

# *************************
# | Meta Static Functions |
# *************************


# this is made up of the following mixins
static func __mixed_info() -> Array:

	return [
		# comparable, throwable dependency
		'res://addons/PressAccept/Conductor/Conductable.gd',
		# mixins
		'res://addons/PressAccept/Utilizer/Mixins/Comparable.gd',
		'res://addons/PressAccept/Utilizer/Mixins/Throwable.gd'
	]


# ***************************
# | Public Static Functions |
# ***************************


# wraps Mixin functionality to create a new object, use instead of new()
static func clause_instantiate(
		init_subclauses: Array) -> PressAccept_Parser_Pika_Clause:

	return Mixer.instantiate(
		'res://addons/PressAccept/Parser/Pika/Clauses/Clause.gd',
		[
			{ STR_SUBCLAUSES: init_subclauses }
		],
		true
	)


# *********************
# | Public Properties |
# *********************

# Subclauses, paired with their AST node label (if there is one).
var labeled_subclauses: Array = []

# Rules this clause is a toplevel clause of (used by toStringWithRuleNames(}
# method).
var rules: Array = []

# The parent clauses of this clause that should be matched in the same start
# position.
var seed_parent_clauses: Array = []

# If true, the clause can match while consuming zero characters.
var can_match_zero_chars: bool

# Index in the topological sort order of clauses, bottom-up.
var clause_index: int

# The cached result of the toString() method.
var to_string_cached: String

# **********************
# | Private Properties |
# **********************

# The cached result of the toStringWithRuleNames() method.
var _to_string_with_rule_name_cached: String = ''

# Currently being output (prevents recursion)
var _being_output: bool = false


# ***************
# | Constructor |
# ***************


func __init(
		init_args: Dictionary) -> void:

	if STR_SUBCLAUSES in init_args:
		var Nothing: Script = \
			load('res://addons/PressAccept/Parser/Pika/Clauses/Terminal/Nothing.gd') as Script
		var subclauses = init_args[STR_SUBCLAUSES]
		if subclauses.size() and subclauses[0] is Nothing:
			# Nothing can't be the first subclause, since we don't trigger
			# upwards expansion of the DP wavefront by seeding the memo table
			# by matching Nothing at every input position, to keep the memo
			# table small
			self[THROWABLE].throw(
				{
					Exception.STR_EXCEPTION_CODE    : 'Illegal Argument',
					Exception.STR_EXCEPTION_MESSAGE : \
						'Nothing cannot be the first subclause of any clause'
				}
			)
			return
		var ASTNodeLabel: Script = \
			load('res://addons/PressAccept/Parser/Pika/Clauses/Resource/ASTNodeLabel.gd') as Script
		var LabeledClause: Script = \
			load('res://addons/PressAccept/Parser/Pika/AST/LabeledClause.gd') as Script
		for subclause in subclauses:
			var ast_node_label: String = ''
			if subclause is ASTNodeLabel:
				# Transfer ASTNodeLabel.astNodeLabel to
				# LabeledClause.astNodeLabel field
				ast_node_label = subclause.ast_node_label
				# skip over ASTNodeLabel node when adding subClause to
				# subClauses array
				subclause = subclause.labeled_subclauses[0].clause
			labeled_subclauses.append(
				LabeledClause.labeledclause_instantiate(
					subclause,
					ast_node_label
				)
			)
	else:
		self[THROWABLE].throw(
			{
				Exception.STR_EXCEPTION_CODE    : 'Missing Argument',
				Exception.STR_EXCEPTION_MESSAGE : \
					'Clause constructor missing subclauses'
			},
			Error
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
		return "\n" + prefix + 'Clause:' + str(self.get_instance_id())

	_being_output = true

	var output_str: String = ''
	
	output_str += "\n" + prefix + self.__get_script() \
		+ ' (' + str(self.get_instance_id()) + ') ='

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

	return 'res://addons/PressAccept/Parser/Pika/Clauses/Clause.gd'


# |------------|
# | Comparable |
# |------------|


# can we compare a target value to this type?
func __is_comparable(
		target) -> bool:

	if self.filters.has(Comparable.STR_FILTER_IS_COMPARABLE_TARGET):
		target = self[CONDUCTABLE].filter(
			Comparable.STR_FILTER_IS_COMPARABLE_TARGET,
			target
		)

	var Self: Script = \
		load('res://addons/PressAccept/Parser/Pika/Clauses/Clause.gd') as Script

	return target is Self or target is Dictionary or target is String


# what value in this object are we comparaing against?
func __comparison_source(
		target):

	var return_value = self
	match typeof(target):
		TYPE_STRING:
			return_value = str(self)

		TYPE_DICTIONARY:
			return_value = Normalizer.normalize_to_dict(self)

	if self.hooks.has(Comparable.STR_HOOK_COMPARISON_SOURCE):
		self[CONDUCTABLE].hook(
			Comparable.STR_HOOK_COMPARISON_SOURCE,
			[ return_value, target ]
		)

	if self.filters.has(Comparable.STR_FILTER_SOURCE):
		return self[CONDUCTABLE].filter(
			Comparable.STR_FILTER_SOURCE,
			return_value
		)
	else:
		return return_value


func __comparator(
		target):

	if self.hooks.has(Comparable.STR_HOOK_GET_COMPARATOR):
		self[CONDUCTABLE].hook(Comparable.STR_HOOK_GET_COMPARATOR, [ target ])

	var return_value = ClauseComparator
	match typeof(target):
		TYPE_DICTIONARY:
			return_value = DictComparator

	if self.filters.has(Comparable.STR_FILTER_COMPARATOR):
		return self[CONDUCTABLE].filter(
			Comparable.STR_FILTER_COMPARATOR,
			return_value
		)
	else:
		return return_value


# |------------|
# | Normalizer |
# |------------|


# Normalizer.normalize_to_dict compatibility, returns dict with numbered indices
func __to_dict() -> Dictionary:

	return {
		STR_LABELED_SUBCLAUSES_KEY   = labeled_subclauses,
		STR_RULES_KEY                = rules,
		STR_SEED_PARENT_CLAUSES_KEY  = seed_parent_clauses,
		STR_CAN_MATCH_ZERO_CHARS_KEY = can_match_zero_chars,
		STR_CLAUSE_INDEX_KEY         = clause_index
	}


# Normalizer.normalize_to_string compatibility, returns string representation
func __to_string() -> String:

	return str(self)


# ******************
# | Public Methods |
# ******************


func hash() -> int:

	return Normalizer.normalize_to_dict(self).hash()


# Register this clause with a rule (used by toStringWithRuleNames()).
func register_rule(
		rule: Rule) -> void:

	rules.append(rule)


# Unregister this clause from a rule.
func unregister_rule(
		rule: Rule) -> void:

	rules.erase(rule)


# Find which subclauses need to add this clause as a "seed parent clause".
# Overridden in Seq.
func add_as_seed_parent_clause() -> void:

	# Default implementation: all subclauses will seed this parent clause.
	var added: Array = []
	for labeled_subclause in labeled_subclauses:
		# Don't duplicate seed parent clauses in the subclause
		if not labeled_subclause.clause in added:
			labeled_subclause.clause.seed_parent_clauses.append(self)
			added.append(labeled_subclause.clause)


# Sets canMatchZeroChars to true if this clause can match zero characters,
# i.e. always matches at any input position. Called bottom-up. Implemented in
# subclasses.
func determine_whether_can_match_zero_chars(): # -> void

	assert(false)


# Match a clause by looking up its subclauses in the memotable (in the case of
# nonterminals), or by looking at the input string (in the case of terminals).
# Implemented in subclasses.
func match(
		memo_table : MemoTable,
		memo_key   : Array, # : MemoKey,
		input      : String) -> MemoMatch:

	assert(false)

	return null

# Get the names of rules that this clause is the root clause of.
func get_rule_names() -> String:

	var return_value: String

	if rules.empty():
		return ''

	var rule_names: Array = rules.duplicate()
	for i in range(rule_names.size()):
		rule_names[i] = rule_names[i].rule_name
	rule_names.sort()
	return PressAccept_Utilizer_String.join(rule_names, ', ')


# Get the clause as a string, with rule names prepended if the clause is the
# toplevel clause of a rule.
func to_string_with_rule_names() -> String:

	if not _to_string_with_rule_name_cached:
		if not rules.empty():
			var MetaGrammar: Script = \
				load('res://addons/PressAccept/Parser/Pika/Grammar/MetaGrammar.gd') as Script

			_to_string_with_rule_name_cached = ''
			_to_string_with_rule_name_cached += get_rule_names()
			_to_string_with_rule_name_cached += ' <- '

			var added_ast_node_labels: bool = false
			for rule in rules:
				if rule.labeled_clause.ast_node_label:
					_to_string_with_rule_name_cached += ':'
					added_ast_node_labels = true
			var add_parens: bool = added_ast_node_labels \
				and MetaGrammar.need_to_add_parens_around_ast_node_label(self)
			if add_parens:
				_to_string_with_rule_name_cached += '('
			_to_string_with_rule_name_cached += to_string()
			if add_parens:
				_to_string_with_rule_name_cached += ')'
		else:
			_to_string_with_rule_name_cached = to_string()

	return _to_string_with_rule_name_cached


func to_string() -> String:

	assert(false, 'toString() needs to be overridden in subclasses')

	return ''

