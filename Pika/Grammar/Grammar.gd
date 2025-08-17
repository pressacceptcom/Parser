tool
class_name PressAccept_Parser_Pika_Grammar

# |=============================|
# |                             |
# |    Press Accept: Parser     |
# | Parsing Algorithms In Godot |
# |                             |
# |=============================|
#
# "A grammar. The parse(String) method runs the parser on the provided input
# string."
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
# Class                  : Grammar
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

const OrderedDictionary: Script = PressAccept_Utilizer_Data_OrderedDictionary

const PriorityQueue: Script = PressAccept_Utilizer_Data_PriorityQueue

const Throwable: Script = PressAccept_Utilizer_Mixins_Throwable
const THROWABLE: String = Throwable.STR_MIXIN_IDENTIFIER

# |-------------|
# | Parser/Pika |
# |-------------|

const Clause: Script = PressAccept_Parser_Pika_Clause

const GrammarUtilities: Script = PressAccept_Parser_Pika_GrammarUtilities

const MemoKey   : Script = PressAccept_Parser_Pika_MemoKey
const MemoMatch : Script = PressAccept_Parser_Pika_Match
const MemoTable : Script = PressAccept_Parser_Pika_MemoTable

const Nothing: Script = PressAccept_Parser_Pika_Nothing

const Rule: Script = PressAccept_Parser_Pika_Rule

const RuleRef: Script = PressAccept_Parser_Pika_RuleRef

const Terminal: Script = PressAccept_Parser_Pika_Terminal

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
static func grammar_instantiate(
		init_rules: Array) -> PressAccept_Parser_Pika_Grammar:

	return Mixer.instantiate(
		'res://addons/PressAccept/Parser/Pika/Grammar/Grammar.gd',
		[ init_rules ],
		true
	)


# *********************
# | Public Properties |
# *********************

# All rules in the grammar.
var all_rules: Array # : Rule

# A mapping from rule name (with any precedence suffix) to corresponding Rule.
var rule_name_with_precedence_to_rule: Dictionary # Map<String, Rule>

# All clausesin the grammar.
var all_clauses: Array # : Clause

# If true, print verbose debug output.
var DEBUG: bool = false

# **********************
# | Private Properties |
# **********************

# Currently being output (prevents recursion)
var _being_output: bool = false

# ***************
# | Constructor |
# ***************


func __init(
		init_rules: Array) -> void:

	if init_rules.size() == 0:
		self[THROWABLE].throw(
			{
				Exception.STR_EXCEPTION_CODE    : 'Illegal Argument',
				Exception.STR_EXCEPTION_MESSAGE : \
					'Grammar must consist of at least one rule'
			},
			Error
		)
		return

	# Construct a grammar from a set of rules. The first rule should be the \
	# toplevel rule.
	var top_level_rule: Rule = init_rules[0]

	# Group rules by name
	var rule_name_to_rules: Dictionary = {}
	for rule in init_rules:
		if not rule.rule_name:
			self[THROWABLE].throw(
				{
					Exception.STR_EXCEPTION_CODE    : 'Illegal Argument',
					Exception.STR_EXCEPTION_MESSAGE : 'All rules must be named'
				},
				Error
			)
			return

		if rule.labeled_clause.clause is RuleRef \
				and rule.labeled_clause.clause.ref_rule_name == rule.rule_name:
			# Make sure rule doesn't refer only to itself
			self[THROWABLE].throw(
				{
					Exception.STR_EXCEPTION_CODE    : 'Illegal Argument',
					Exception.STR_EXCEPTION_MESSAGE : \
						'Rule cannot refer only to itself: ' + rule.rule_name \
							+ '[' + str(rule.precedence) + ']'
				},
				Error
			)
			return

		if not rule.rule_name in rule_name_to_rules:
			rule_name_to_rules[rule.rule_name] = [ rule ]
		else:
			rule_name_to_rules[rule.rule_name].append(rule)

		# Make sure there are no cycles in the grammar before RuleRef instances
		# have been replaced with direct references (checking once up front
		# simplifies other recursive routines, so that they don't have to check
		# for infinite recursion)
		var error = GrammarUtilities.check_no_ref_cycles(
			rule.labeled_clause.clause,
			rule.rule_name,
			[]
		)

		if error:
			self[THROWABLE].rethrow(error)
			return

	all_rules = init_rules.duplicate()
	# HashMap<String, String>
	var rule_name_to_lowest_precedence_level_rule_name: Dictionary = {}
	var lowest_precedence_clauses: Array = [] # ArrayList<Clause>
	for rule_name in rule_name_to_rules:
		var rules_with_name: Array = rule_name_to_rules[rule_name]
		if rules_with_name.size() > 1:
			var error = GrammarUtilities.handle_precedence(
				rule_name,
				rules_with_name,
				lowest_precedence_clauses,
				rule_name_to_lowest_precedence_level_rule_name
			)

			if error is Exception:
				self[THROWABLE].rethrow(error)
				return

	# If there is more than one precedence level for a rule, the
	# handlePrecedence call above modifies rule names to include a
	# precedence suffix, and also adds an all-precedence selector clause
	# with the original rule name. All rule names should now be unique.
	rule_name_with_precedence_to_rule = {}
	for rule in all_rules:
		# The handlePrecedence call above added the precedence to the rule
		# name as a suffix
		if rule.rule_name in rule_name_with_precedence_to_rule:
			self[THROWABLE].throw(
				{
					Exception.STR_EXCEPTION_CODE    : 'Illegal Argument',
					Exception.STR_EXCEPTION_MESSAGE : \
						'Duplicate rule name ' + rule.rule_name
				},
				Error
			)

		rule_name_with_precedence_to_rule[rule.rule_name] = rule

	# Register each rule with its toplevel clause (used in the clause's
	# toString() method)
	for rule in all_rules:
		rule.labeled_clause.clause.register_rule(rule)

	# Intern clauses based on their toString() value, coalescing shared
	# sub-clauses into a DAG, so that effort is not wasted parsing different
	# instances of the same clause multiple times, and so that when a subclause
	# matches, all parent clauses will be added to the active set in the next
	# iteration. Also causes the toString() values to be cached, so that after
	# RuleRefs are replaced with direct Clause references, toString() doesn't
	# get stuck in an infinite loop.
	var to_string_to_clause: Dictionary = {} # HashMap<>
	for rule in all_rules:
		rule.labeled_clause.clause = GrammarUtilities.intern(
			rule.labeled_clause.clause,
			to_string_to_clause
		)

	# Resolve each RuleRef into a direct reference to the referenced clause
	var clauses_visited_resolverule_refs: Array = [] # HashSet<>
	for rule in all_rules:
		var error = GrammarUtilities.resolve_rule_refs(
			rule.labeled_clause,
			rule_name_with_precedence_to_rule,
			rule_name_to_lowest_precedence_level_rule_name,
			clauses_visited_resolverule_refs
		)

		if error is Exception:
			self[THROWABLE].rethrow(error)
			return

	# Topologically sort clauses, bottom-up, placing the result in allClauses
	var error = GrammarUtilities.find_clause_topo_sort_order(
		top_level_rule,
		all_rules,
		lowest_precedence_clauses
	)

	if error is Exception:
		self[THROWABLE].rethrow(error)
		return

	all_clauses = error

	# Find clauses that always match zero or more characters,
	# e.g. FirstMatch(X | Nothing). Importantly, allClauses is in reverse
	# topological order, i.e. traversal is bottom-up.
	for clause in all_clauses:
		error = clause.determine_whether_can_match_zero_chars()

		if error is Exception:
			self[THROWABLE].rethrow(error)
			return

	# Find seed parent clauses (in the case of Seq, this depends upon
	# alwaysMatches being set in the prev step)
	for clause in all_clauses:
		clause.add_as_seed_parent_clause()


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
	output_str += self[THROWABLE].__output(prefix + tab_char, tab_char)

	output_str += "\n" + prefix + tab_char + 'all_rules:'
	for element in all_rules:
		if element is Object and element.has_method('__output'):
			output_str += \
				element.__output(prefix + tab_char + tab_char, tab_char)
		else:
			output_str += "\n" + prefix + tab_char + tab_char + str(element)

	output_str += "\n" + prefix + tab_char \
		+ 'rule_name_with_precedence_to_rule:'
	for key in rule_name_with_precedence_to_rule:
		if key is Object and key.has_method('__output'):
			output_str += \
				key.__output(prefix + tab_char + tab_char, tab_char)
		else:
			output_str += "\n" + prefix + tab_char + tab_char + str(key)

		output_str + ' : '

		var element = rule_name_with_precedence_to_rule[key]

		if element is Object and element.has_method('__output'):
			output_str += \
				element.__output(
					prefix + tab_char + tab_char + tab_char, tab_char
				)
		else:
			output_str += str(element)

	output_str += "\n" + prefix + tab_char + 'all_clauses:'
	for element in all_clauses:
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

	return 'res://addons/PressAccept/Parser/Pika/Grammar/Grammar.gd'


# ******************
# | Public Methods |
# ******************


func parse(
		input: String) -> MemoTable:

	var priority_queue: PriorityQueue = \
		PriorityQueue.priorityqueue_instantiate() # PriorityQueue<Clause>

	var memo_table = MemoTable.memotable_instantiate(self, input)

	var terminals: PriorityQueue = PriorityQueue.priorityqueue_instantiate()
	for clause in all_clauses:
		if clause is Terminal and not clause is Nothing:
			terminals.add(clause)

	# Main parsing loop
	for start_pos in range(input.length() - 1, -1, -1):
		#if DEBUG:
		print('=============== POSITION: ' + str(start_pos) \
				+ ' CHARACTER:[' \
				+ PressAccept_Parser_Pika_String \
					.escape_quoted_char(input[start_pos]) \
				+ '] ===============')

		priority_queue.sequence = terminals.sequence.duplicate()
		
		#for terminal in terminals:
		#	priority_queue.add(terminal)

		while not priority_queue.empty():
			# Remove a clause from the priority queue (ordered from terminals
			# to toplevel clauses)
			var clause     : Clause  = priority_queue.poll() # remove()?
			var memo_key   : Array   = [ clause, start_pos ] # : MemoKey
			var memo_match : MemoMatch = \
				clause.match(memo_table, memo_key, input)
			memo_table.add_match(memo_key, memo_match, priority_queue)

	return memo_table


# Get a rule by name.
func get_rule(
		rule_name_with_precedence: String): # -> Rule:

	if not rule_name_with_precedence in rule_name_with_precedence_to_rule:
		return self[THROWABLE].throw(
			{
				Exception.STR_EXCEPTION_CODE    : 'Illegal Argument',
				Exception.STR_EXCEPTION_MESSAGE : \
					'Unknown rule name: ' + rule_name_with_precedence
			},
			Error
		)

	return rule_name_with_precedence_to_rule[rule_name_with_precedence]


# Get the Match entries for all nonoverlapping matches of the named rule,
# obtained by greedily matching from the beginning of the string, then looking
# for the next match after the end of the current match.
func get_nonoverlapping_matches(
		rule_name  : String,
		memo_table : MemoTable): # -> Array:

	var rule = get_rule(rule_name)

	if rule is Exception:
		return rule

	return memo_table.get_nonoverlapping_matches(rule.labeled_clause.clause)


# Get all Match entries for the given clause, indexed by start position.
func get_navigable_matches(
		rule_name  : String,
		memo_table : MemoTable): # -> OrderedDictionary:

	var rule = get_rule(rule_name)

	if rule is Exception:
		return rule

	return memo_table.get_navigable_matches(rule.labeled_clause.clause)

