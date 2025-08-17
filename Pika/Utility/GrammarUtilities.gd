tool
class_name PressAccept_Parser_Pika_GrammarUtilities

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

const Collection: Script = PressAccept_Utilizer_Collection

const Error     : Script = PressAccept_Error_Error
const Exception : Script = PressAccept_Error_Exception

const OrderedDictionary: Script = PressAccept_Utilizer_Data_OrderedDictionary

# |-------------|
# | Parser/Pika |
# |-------------|

const Clause: Script = PressAccept_Parser_Pika_Clause

const First: Script = PressAccept_Parser_Pika_First

const LabeledClause: Script = PressAccept_Parser_Pika_LabeledClause

const Rule: Script = PressAccept_Parser_Pika_Rule

const RuleRef: Script = PressAccept_Parser_Pika_RuleRef

const Terminal: Script = PressAccept_Parser_Pika_Terminal

# ***************************
# | Public Static Functions |
# ***************************

# Topologically sort all clauses into bottom-up order, from terminals up to the
# toplevel clause.
static func find_clause_topo_sort_order(
		top_level_rule            : Rule,
		all_rules                 : Array, # : List<Rule>,
		lowest_precedence_clauses : Array # HashSet<Clause>
		): #  -> Array: # List<Clause>

	var all_clauses_unordered : Array = [] # ArrayList<Clause>
	var top_level_visited     : Array = [] # HashSet<Clause>

	# Add toplevel rule
	if top_level_rule != null:
		all_clauses_unordered.append(top_level_rule.labeled_clause.clause)
		top_level_visited.append(top_level_rule.labeled_clause.clause)

	# Find any other toplevel clauses (clauses that are not a subclause of any
	# other clause)
	for rule in all_rules:
		_find_reachable_clauses(
			rule.labeled_clause.clause,
			top_level_visited,
			all_clauses_unordered
		)
	var top_level_clauses: Array = all_clauses_unordered.duplicate()
	for clause in all_clauses_unordered:
		for labeled_subclause in clause.labeled_subclauses:
			top_level_clauses.erase(labeled_subclause.clause)
	var dfs_roots: Array = top_level_clauses.duplicate()

	# Add to the end of the list of toplevel clauses all lowest-precedence
	# clauses, since top-down precedence climbing should start at each
	# lowest-precedence clause
	dfs_roots.append_array(lowest_precedence_clauses)

	# Finally, in case there are cycles in the grammar that are not part of a
	# precedence hierarchy, add to the end of the list of toplevel clauses the
	# set of all "head clauses" of cycles (the set of all clauses reached twice
	# in some path through the grammar)
	var cycle_discovered   : Array = [] # HashSet<Clause>
	var cycle_finished     : Array = [] # HashSet<Clause>
	var cycle_head_clauses : Array = [] # HashSet<Clause>
	for clause in top_level_clauses:
		var error = _find_cycle_head_clauses(
			clause,
			cycle_discovered,
			cycle_finished,
			cycle_head_clauses
		)

		if error:
			return error

	for rule in all_rules:
		var error = _find_cycle_head_clauses(
			rule.labeled_clause.clause,
			cycle_discovered,
			cycle_finished,
			cycle_head_clauses
		)

		if error:
			return error

	dfs_roots.append_array(cycle_head_clauses)

	# Topologically sort all clauses into bottom-up order, starting with
	# terminals (so that terminals are all grouped together at the beginning of
	# the list)
	var terminals_visited : Array = [] # HashSet<Clause>
	var terminals         : Array = [] # ArrayList<Clause>
	for rule in all_rules:
		_find_terminals(
			rule.labeled_clause.clause,
			terminals_visited,
			terminals
		)
	var all_clauses       : Array = terminals.duplicate() # ArrayList<Clause>
	var reachable_visited : Array = terminals.duplicate() # HashSet<Clause>
	for top_level_clause in dfs_roots:
		_find_reachable_clauses(
			top_level_clause,
			reachable_visited,
			all_clauses
		)

	# Give each clause an index in the topological sort order, bottom-up
	for i in range(all_clauses.size()):
		all_clauses[i].clause_index = i

	return all_clauses


# Check there are no cycles in the clauses of rules, before RuleRef instances
# are resolved to direct references.
static func check_no_ref_cycles(
		clause             : Clause,
		self_ref_rule_name : String,
		visited            : Array # Set<Clause>
		): # -> void:

	if not clause in visited:
		visited.append(clause)
		for labeled_subclause in clause.labeled_subclauses:
			var error = check_no_ref_cycles(
				labeled_subclause.clause,
				self_ref_rule_name,
				visited
			)

			if error is Exception:
				return error
	else:
		return Exception.create(
			{
				Exception.STR_EXCEPTION_CODE    : 'Illegal Argument',
				Exception.STR_EXCEPTION_MESSAGE : \
					'Rules should not contain cycles when they are created: ' \
						+ self_ref_rule_name
			},
			Error
		)

	visited.erase(clause)

	return null


# Rewrite self-references in a precedence hierarchy into precedence-climbing
# form.
static func handle_precedence(
		rule_name_without_precedence : String,
		rules                        : Array, # List<Rule>
		lowest_precedence_clauses    : Array, # ArrayList<Clause>
		rule_name_to_lowest_precedence_level_rule_name: Dictionary # Map<String, String>
		): # -> void:

	# // Rewrite rules
	#
	# For all but the highest precedence level:
	#
	# E[0] <- E (Op E)+  =>  E[0] <- (E[1] (Op E[1])+) / E[1] 
	# E[0,L] <- E Op E   =>  E[0] <- (E[0] Op E[1]) / E[1] 
	# E[0,R] <- E Op E   =>  E[0] <- (E[1] Op E[0]) / E[1]
	# E[3] <- '-' E      =>  E[3] <- '-' (E[3] / E[4]) / E[4]
	#
	# For highest precedence level, next highest precedence wraps back to lowest precedence level:
	#
	# E[5] <- '(' E ')'  =>  E[5] <- '(' E[0] ')'

	# Check there are no duplicate precedence levels
	var precedence_to_rule: OrderedDictionary = \
		OrderedDictionary.ordereddictionary_instantiate() # TreeMap<Integer, Rule>
	for rule in rules:
		if rule.precedence in precedence_to_rule:
			return Exception.create(
				{
					Exception.STR_EXCEPTION_CODE    : 'Illegal Argument',
					Exception.STR_EXCEPTION_MESSAGE : \
						'Multiple rules with name ' \
							+ rule_name_without_precedence \
							+ ('' if rule.precedence == -1 \
								else ' and precedence ' + rule.precedence)
				},
				Error
			)
		precedence_to_rule.set_value(rule.precedence, rule, true)

	# Get rules in ascending order of precedence
	var precedence_order: Array = precedence_to_rule.values()

	# Rename rules to include precedence level
	var num_precedence_levels: int = rules.size()
	for precedence_index in range(num_precedence_levels):
		# Since there is more than one precedence level, update rule name to
		# include precedence
		var rule: Rule = precedence_order[precedence_index]
		rule.rule_name += '[' + str(rule.precedence) + ']'

	# Transform grammar rule to handle precedence
	for precedence_index in range(num_precedence_levels):
		var rule: Rule = precedence_order[precedence_index]

		# Count the number of self-reference operands
		var num_self_refs: int = _count_rule_self_references(
			rule.labeled_clause.clause,
			rule_name_without_precedence
		)

		var curr_prec_rule_name: String = rule.rule_name
		var next_highest_prec_rule_name = \
			precedence_order[
				(precedence_index + 1) % num_precedence_levels
		].rule_name

		# If a rule has 1+ self-references, need to rewrite rule to handle
		# precedence and associativity
		var is_highest_prec: bool = \
			precedence_index == num_precedence_levels - 1
		if num_self_refs >= 1:
			# Rewrite self-references to higher precedence or left- and
			# right-recursive forms. (the toplevel clause of the rule,
			# rule.labeledClause.clause, can't be a self-reference, since we
			# already checked for that, and IllegalArgumentException would have
			# been thrown.)
			_rewrite_self_references(
				rule.labeled_clause.clause,
				rule.associativity,
				0,
				num_self_refs,
				rule_name_without_precedence,
				is_highest_prec,
				curr_prec_rule_name,
				next_highest_prec_rule_name
			)

		# Defer to next highest level of precedence if the rule doesn't match,
		# except at the highest level of precedence, which is assumed to be a
		# precedence-breaking pattern (like parentheses), so should not defer
		# back to the lowest precedence level unless the pattern itself matches
		if not is_highest_prec:
			# Move rule's toplevel clause (and any AST node label it has) into
			# the first subclause of a First clause that fails over to the next
			# highest precedence level
			var first: First = First.first_instantiate(
				[
					rule.labeled_clause.clause,
					RuleRef.ruleref_instantiate(
						next_highest_prec_rule_name
					)
				]
			)
			# Move any AST node label down into first subclause of new First
			# clause, so that label doesn't apply to the final failover rule
			# reference
			first.labeled_subclauses[0].ast_node_label = \
				rule.labeled_clause.ast_node_label
			rule.labeled_clause.ast_node_label = ''
			# Replace rule clause with new First clause
			rule.labeled_clause.clause = first

	# Map the bare rule name (without precedence suffix) to the lowest
	# precedence level rule name
	var lowest_prec_rule: Rule = precedence_order[0]
	lowest_precedence_clauses.append(lowest_prec_rule.labeled_clause.clause)
	rule_name_to_lowest_precedence_level_rule_name[
		rule_name_without_precedence
	] = lowest_prec_rule.rule_name


# Recursively call toString() on the clause tree for this Rule, so that
# toString() values are cached before RuleRef objects are replaced with direct
# references, and so that shared subclauses are only matched once.
static func intern(
		clause              : Clause,
		to_string_to_clause : Dictionary # Map<String, Clause>
		) -> Clause:

	# Call toString() on (and intern) subclauses, bottom-up
	for labeled_subclause in clause.labeled_subclauses:
		labeled_subclause.clause = \
			intern(labeled_subclause.clause, to_string_to_clause)

	# Call toString after recursing to child nodes
	var to_str: String = clause.to_string()

	var prev_interned_clause: Clause = null
	# Intern the clause based on the toString value
	if not to_str in to_string_to_clause:
		to_string_to_clause[to_str] = clause
	else:
		prev_interned_clause = to_string_to_clause[to_str]

	# Return the previously-interned clause, if present, otherwise the clause,
	# if it was just interned
	return prev_interned_clause if prev_interned_clause else clause


static func resolve_rule_refs(
		labeled_clause    : LabeledClause,
		rule_name_to_rule : Dictionary, # Map<String, Rule>
		rule_name_to_lowest_precedence_level_rule_name: Dictionary, # Map<String, String>
		visited           : Array # Set<Clause>
		):

	if labeled_clause.clause is RuleRef:
		# Follow a chain of from name in RuleRef objects until a non-RuleRef
		# is reached
		var curr_labeled_clause : LabeledClause = labeled_clause
		var visited_clauses     : Array         = [] # HashSet<Clause>
		while curr_labeled_clause.clause is RuleRef:
			if curr_labeled_clause.clause in visited_clauses:
				return Exception.create(
					{
						Exception.STR_EXCEPTION_CODE    : 'Illegal Argument',
						Exception.STR_EXCEPTION_MESSAGE : \
							'Reached toplevel RuleRef cycle: ' \
								+ curr_labeled_clause.clause.to_string()
					},
					Error
				)

			visited_clauses.append(curr_labeled_clause.clause)

			# Follow a chain of from name in RuleRef objects until a
			# non-RuleRef is reached
			var ref_rule_name: String = curr_labeled_clause.clause.ref_rule_name

			# Check if the rule is the reference to the lowest precedence rule
			# of a precedence hierarchy
			var lowest_prec_rule_name = Collection.get_if_exists_or_null(
				rule_name_to_lowest_precedence_level_rule_name,
				ref_rule_name
			)

			# Look up Rule based on rule name
			var referenced_rule: Rule = Collection.get_if_exists_or_null(
				rule_name_to_rule,
				ref_rule_name \
					if lowest_prec_rule_name == null \
					else lowest_prec_rule_name
			)

			if referenced_rule == null:
				return Exception.create(
					{
						Exception.STR_EXCEPTION_CODE    : 'Illegal Argument',
						Exception.STR_EXCEPTION_MESSAGE : \
							'Unknown rule name: ' + ref_rule_name
					},
					Error
				)

			curr_labeled_clause = referenced_rule.labeled_clause

		# Set current clause to a direct reference to the referenced rule
		labeled_clause.clause = curr_labeled_clause.clause

		# Copy across AST node label, if any
		if labeled_clause.ast_node_label == '':
			labeled_clause.ast_node_label = curr_labeled_clause.ast_node_label

		# Stop recursing at RuleRef

	else:
		if not labeled_clause.clause in visited:
			visited.append(labeled_clause.clause)
			var labeled_subclauses: Array = \
				labeled_clause.clause.labeled_subclauses
			for labeled_subclause in labeled_subclauses:
				resolve_rule_refs(
					labeled_subclause,
					rule_name_to_rule,
					rule_name_to_lowest_precedence_level_rule_name,
					visited
				)


# ****************************
# | Private Static Functions |
# ****************************


static func _find_terminals(
		clause        : Clause,
		visited       : Array,  # HashSet<Clause>
		terminals_out : Array   # List<Clause>
		) -> void:

	if not clause in visited:
		visited.append(clause)
		if clause is Terminal:
			terminals_out.append(clause)
		else:
			for labeled_subclause in clause.labeled_subclauses:
				_find_terminals(
					labeled_subclause.clause,
					visited,
					terminals_out
				)


# Find reachable clauses, and bottom-up (postorder), find clauses that always
# match in every position.
static func _find_reachable_clauses(
		clause             : Clause,
		visited            : Array,  # HashSet<Clause>
		rev_topo_order_out : Array   # List<Clause>
		) -> void:

	if not clause in visited:
		visited.append(clause)
		for labeled_subclause in clause.labeled_subclauses:
			_find_reachable_clauses(labeled_subclause.clause, visited, rev_topo_order_out)
		rev_topo_order_out.append(clause)


# Find the Clause nodes that complete a cycle in the grammar.
static func _find_cycle_head_clauses(
		clause                 : Clause,
		discovered             : Array, # Set<Clause>
		finished               : Array, # Set<Clause>
		cycle_head_clauses_out : Array # Set<Clause>
		): # -> void:

	if clause is RuleRef:
		return Exception.create(
			{
				Exception.STR_EXCEPTION_CODE    : 'Illegal Argument',
				Exception.STR_EXCEPTION_MESSAGE : \
					'There should not be any RuleRef nodes lef tin the grammar'
			},
			Error
		)

	if not clause in discovered:
		discovered.append(clause)

	for labeled_subclause in clause.labeled_subclauses:
		var subclause: Clause = labeled_subclause.clause
		if subclause in discovered:
			# Reached a cycle
			if not subclause in cycle_head_clauses_out:
				cycle_head_clauses_out.append(subclause)
		elif not subclause in finished:
			var error = _find_cycle_head_clauses(
				subclause,
				discovered,
				finished,
				cycle_head_clauses_out
			)
			
			if error is Exception:
				return error

	discovered.erase(clause)

	if not clause in finished:
		finished.append(clause)


# Count number of self-references among descendant clauses.
static func _count_rule_self_references(
		clause                       : Clause,
		rule_name_without_precedence : String) -> int:

	if clause is RuleRef \
			and clause.ref_rule_name == rule_name_without_precedence:
		return 1
	else:
		var num_self_refs: int = 0
		for labeled_subclause in clause.labeled_subclauses:
			num_self_refs += _count_rule_self_references(
				labeled_subclause.clause,
				rule_name_without_precedence
			)
		return num_self_refs


# Rewrite self-references into precedence-climbing form.
static func _rewrite_self_references(
		clause                      : Clause,
		associativity               , # : int,
		num_self_refs_so_far        : int,
		num_self_refs               : int,
		self_ref_rule_name          : String,
		is_highest_prec             : bool,
		curr_prec_rule_name         : String,
		next_highest_prec_rule_name : String) -> int:

	# Terminate recursion when all self-refs have been replaced
	if num_self_refs_so_far < num_self_refs:
		for labeled_subclause in clause.labeled_subclauses:
			var subclause = labeled_subclause.clause
			if subclause is RuleRef:
				if subclause.ref_rule_name == self_ref_rule_name:
					if num_self_refs >= 2:
						# Change name of self-references to implement
						# precedence climbing:
						#
						# For leftmost operand of left-recursive rule:
						# E[i] <- E X E  =>  E[i] = E[i] X E[i+1]
						# For rightmost operand of right-recursive rule:
						# E[i] <- E X E  =>  E[i] = E[i+1] X E[i]
						#
						# For non-associative rule:
						# E[i] = E E  =>  E[i] = E[i+1] E[i+1]
						labeled_subclause.clause = \
							RuleRef.ruleref_instantiate(
								curr_prec_rule_name \
									if (associativity == Rule.ASSOCIATIVITY.LEFT \
											and num_self_refs_so_far == 0) \
										or (associativity == Rule.ASSOCIATIVITY.RIGHT \
											and num_self_refs_so_far == num_self_refs - 1) \
									else next_highest_prec_rule_name
							)

					else:
						# numSelfRefs == 1
						if not is_highest_prec:
							# Move subclause (and its AST node label, if any)
							# inside a First clause that climbs precedence to
							# the next level:
							#
							# E[i] <- X E Y  =>  E[i] <- X (E[i] / E[(i+1)%N]) Y
							subclause.ref_rule_name = curr_prec_rule_name
							labeled_subclause.clause = First.first_instantiate(
								[
									subclause,
									RuleRef.ruleref_instantiate(
										next_highest_prec_rule_name
									)
								]
							)
						else:
							# Except for highest precedence, just defer back to
							# lowest-prec level:
							#
							# E[N-1] <- '(' E ')'  =>  E[N-1] <- '(' E[0] ')'
							subclause.ref_rule_name = \
								next_highest_prec_rule_name
					num_self_refs_so_far += 1
				# Else don't rewrite the RuleRef, it is not a self-ref
			else:
				num_self_refs_so_far = _rewrite_self_references(
					subclause,
					associativity,
					num_self_refs_so_far,
					num_self_refs,
					self_ref_rule_name,
					is_highest_prec,
					curr_prec_rule_name,
					next_highest_prec_rule_name
				)
			subclause.to_string_cached = ''

	return num_self_refs_so_far

