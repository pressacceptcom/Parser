tool
class_name PressAccept_Parser_Pika_MetaGrammar

# |=============================|
# |                             |
# |    Press Accept: Parser     |
# | Parsing Algorithms In Godot |
# |                             |
# |=============================|
#
# "A "meta-grammar" that produces a runtime parser generator, allowing a
# grammar to be defined using ASCII notation."
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
# Class                  : MetaGrammar
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

const Error     : Script = PressAccept_Error_Error
const Exception : Script = PressAccept_Error_Exception


const ASTNode: Script = PressAccept_Parser_Pika_ASTNode

const ASTNodeLabel: Script = PressAccept_Parser_Pika_ASTNodeLabel

const Clause: Script = PressAccept_Parser_Pika_Clause

const Factory: Script = PressAccept_Parser_Pika_ClauseFactory

const First: Script = PressAccept_Parser_Pika_First

const FollowedBy: Script = PressAccept_Parser_Pika_FollowedBy

const Grammar: Script = PressAccept_Parser_Pika_Grammar

const MemoTable: Script = PressAccept_Parser_Pika_MemoTable

const NotFollowedBy: Script = PressAccept_Parser_Pika_NotFollowedBy

const OneOrMore: Script = PressAccept_Parser_Pika_OneOrMore

const ParserInfo: Script = PressAccept_Parser_Pika_ParserInfo

const Rule: Script = PressAccept_Parser_Pika_Rule

const RuleRef: Script = PressAccept_Parser_Pika_RuleRef

const Seq: Script = PressAccept_Parser_Pika_Seq

const Terminal: Script = PressAccept_Parser_Pika_Terminal

# *************
# | Constants |
# *************

# Rule names:

const STR_GRAMMAR            : String = 'GRAMMAR'
const STR_WSC                : String = 'WSC'
const STR_COMMENT            : String = 'COMMENT'
const STR_RULE               : String = 'RULE'
const STR_CLAUSE             : String = 'CLAUSE'
const STR_IDENT              : String = 'IDENT'
const STR_PREC               : String = 'PREC'
const STR_NUM                : String = 'NUM'
const STR_NAME_CHAR          : String = 'NAME_CHAR'
const STR_CHAR_SET           : String = 'CHARSET'
const STR_HEX                : String = 'HEX'
const STR_CHAR_RANGE         : String = 'CHAR_RANGE'
const STR_CHAR_RANGE_CHAR    : String = 'CHAR_RANGE_CHAR'
const STR_QUOTED_STRING      : String = 'QUOTED_STR'
const STR_ESCAPED_CTRL_CHAR  : String = 'ESCAPED_CTRL_CHAR'
const STR_SINGLE_QUOTED_CHAR : String = 'SINGLE_QUOTED_CHAR'
const STR_STR_QUOTED_CHAR    : String = 'STR_QUOTED_CHAR'
const STR_NOTHING            : String = 'NOTHING'
const STR_START              : String = 'START'

# AST node names:

const STR_RULE_AST               : String = 'RuleAST'
const STR_PREC_AST               : String = 'PrecAST'
const STR_R_ASSOC_AST            : String = 'RAssocAST'
const STR_L_ASSOC_AST            : String = 'LAssocAST'
const STR_IDENT_AST              : String = 'IdentAST'
const STR_LABEL_AST              : String = 'LabelAST'
const STR_LABEL_NAME_AST         : String = 'LabelNameAST'
const STR_LABEL_CLAUSE_AST       : String = 'LabelClauseAST'
const STR_SEQ_AST                : String = 'SeqAST'
const STR_FIRST_AST              : String = 'FirstAST'
const STR_FOLLOWED_BY_AST        : String = 'FollowedByAST'
const STR_NOT_FOLLOWED_BY_AST    : String = 'NotFollowedByAST'
const STR_ONE_OR_MORE_AST        : String = 'OneOrMoreAST'
const STR_ZERO_OR_MORE_AST       : String = 'ZeroOrMoreAST'
const STR_OPTIONAL_AST           : String = 'OptionalAST'
const STR_SINGLE_QUOTED_CHAR_AST : String = 'SingleQuotedCharAST'
const STR_CHAR_RANGE_AST         : String = 'CharRangeAST'
const STR_QUOTED_STRING_AST      : String = 'QuotedStringAST'
const STR_START_AST              : String = 'StartAST'
const STR_NOTHING_AST            : String = 'NothingAST'

# ***************************
# | Public Static Functions |
# ***************************


static func grammar() -> Grammar:

	var top_rule: Rule = Factory.rule(
		STR_GRAMMAR,
		Factory.seq(
			[
				Factory.start(),
				Factory.rule_ref(STR_WSC),
				Factory.one_or_more(
					Factory.rule_ref(STR_RULE)
				)
			]
		)
	)

	var rule: Rule = Factory.rule(
		STR_RULE,
		Factory.ast(
			STR_RULE_AST,
			Factory.seq(
				[
					Factory.rule_ref(STR_IDENT),
					Factory.rule_ref(STR_WSC),
					Factory.optional(
						Factory.rule_ref(STR_PREC)
					),
					Factory.string('<-'),
					Factory.rule_ref(STR_WSC),
					Factory.rule_ref(STR_CLAUSE),
					Factory.rule_ref(STR_WSC),
					Factory.c(';'),
					Factory.rule_ref(STR_WSC)
				]
			)
		)
	)

	# Define precedence order for clause sequences

	# Parens

	var parens: Rule = Factory.full_rule(
		STR_CLAUSE,
		8,
		null,
		Factory.seq(
			[
				Factory.c('('),
				Factory.rule_ref(STR_WSC),
				Factory.rule_ref(STR_CLAUSE),
				Factory.rule_ref(STR_WSC),
				Factory.c(')')
			]
		)
	)

	# Terminals

	var terminals: Rule = Factory.full_rule(
		STR_CLAUSE,
		7,
		null,
		Factory.first(
			[
				Factory.rule_ref(STR_IDENT),
				Factory.rule_ref(STR_QUOTED_STRING),
				Factory.rule_ref(STR_CHAR_SET),
				Factory.rule_ref(STR_NOTHING),
				Factory.rule_ref(STR_START)
			]
		)
	)

	# OneOrMore / ZeroOrMore

	var one_or_more_zero_or_more: Rule = Factory.full_rule(
		STR_CLAUSE,
		6,
		null,
		Factory.first(
			[
				Factory.seq(
					[
						Factory.ast(
							STR_ONE_OR_MORE_AST,
							Factory.rule_ref(STR_CLAUSE)
						),
						Factory.rule_ref(STR_WSC),
						Factory.c('+')
					]
				),
				Factory.seq(
					[
						Factory.ast(
							STR_ZERO_OR_MORE_AST,
							Factory.rule_ref(STR_CLAUSE)
						),
						Factory.rule_ref(STR_WSC),
						Factory.c('*')
					]
				)
			]
		)
	)

	# FollowedBy / NotFollowedBy

	var followed_by_not_followed_by: Rule = Factory.full_rule(
		STR_CLAUSE,
		5,
		null,
		Factory.first(
			[
				Factory.seq(
					[
						Factory.c('&'),
						Factory.ast(
							STR_FOLLOWED_BY_AST,
							Factory.rule_ref(STR_CLAUSE)
						)
					]
				),
				Factory.seq(
					[
						Factory.c('!'),
						Factory.ast(
							STR_NOT_FOLLOWED_BY_AST,
							Factory.rule_ref(STR_CLAUSE)
						)
					]
				)
			]
		)
	)

	# Optional

	var optional: Rule = Factory.full_rule(
		STR_CLAUSE,
		4,
		null,
		Factory.seq(
			[
				Factory.ast(
					STR_OPTIONAL_AST,
					Factory.rule_ref(STR_CLAUSE)
				),
				Factory.rule_ref(STR_WSC),
				Factory.c('?')
			]
		)
	)

	# ASTNodeLabel

	var ast_node_label: Rule = Factory.full_rule(
		STR_CLAUSE,
		3,
		null,
		Factory.ast(
			STR_LABEL_AST,
			Factory.seq(
				[
					Factory.ast(
						STR_LABEL_NAME_AST,
						Factory.rule_ref(STR_IDENT)
					),
					Factory.rule_ref(STR_WSC),
					Factory.c(':'),
					Factory.rule_ref(STR_WSC),
					Factory.ast(
						STR_LABEL_CLAUSE_AST,
						Factory.rule_ref(STR_CLAUSE)
					),
					Factory.rule_ref(STR_WSC)
				]
			)
		)
	)

	# Seq

	var seq: Rule = Factory.full_rule(
		STR_CLAUSE,
		2,
		null,
		Factory.ast(
			STR_SEQ_AST,
			Factory.seq(
				[
					Factory.rule_ref(STR_CLAUSE),
					Factory.rule_ref(STR_WSC),
					Factory.one_or_more(
						Factory.seq(
							[
								Factory.rule_ref(STR_CLAUSE),
								Factory.rule_ref(STR_WSC)
							]
						)
					)
				]
			)
		)
	)

	# First

	var first: Rule = Factory.full_rule(
		STR_CLAUSE,
		1,
		null,
		Factory.ast(
			STR_FIRST_AST,
			Factory.seq(
				[
					Factory.rule_ref(STR_CLAUSE),
					Factory.rule_ref(STR_WSC),
					Factory.one_or_more(
						Factory.seq(
							[
								Factory.c('/'),
								Factory.rule_ref(STR_WSC),
								Factory.rule_ref(STR_CLAUSE),
								Factory.rule_ref(STR_WSC)
							]
						)
					)
				]
			)
		)
	)

	# Whitespace or comment

	var whitespace_or_comment: Rule = Factory.rule(
		STR_WSC,
		Factory.zero_or_more(
			Factory.first(
				[
					Factory.c(" \n\r\t"),
					Factory.rule_ref(STR_COMMENT)
				]
			)
		)
	)

	# Comment

	var comment: Rule = Factory.rule(
		STR_COMMENT,
		Factory.seq(
			[
				Factory.c('#'),
				Factory.zero_or_more(
					Factory.c("\n").invert()
				)
			]
		)
	)

	# Identifier

	var identifier: Rule = Factory.rule(
		STR_IDENT,
		Factory.ast(
			STR_IDENT_AST,
			Factory.seq(
				[
					Factory.rule_ref(STR_NAME_CHAR),
					Factory.zero_or_more(
						Factory.first(
							[
								Factory.rule_ref(STR_NAME_CHAR),
								Factory.c_range('0', '9')
							]
						)
					)
				]
			)
		)
	)

	# Number

	var number: Rule = Factory.rule(
		STR_NUM,
		Factory.one_or_more(
			Factory.c_range('0', '9')
		)
	)

	# Name character

	var name_character: Rule = Factory.rule(
		STR_NAME_CHAR,
		Factory.c_union(
			[
				Factory.c_range('a', 'z'),
				Factory.c_range('A', 'Z'),
				Factory.c('_-')
			]
		)
	)

	# Precedence and optional associativity modifiers for rule name

	var prec_assoc: Rule = Factory.rule(
		STR_PREC,
		Factory.seq(
			[
				Factory.c('['),
				Factory.rule_ref(STR_WSC),
				Factory.ast(
					STR_PREC_AST,
					Factory.rule_ref(STR_NUM)
				),
				Factory.rule_ref(STR_WSC),
				Factory.optional(
					Factory.seq(
						[
							Factory.c(','),
							Factory.rule_ref(STR_WSC),
							Factory.first(
								[
									Factory.ast(
										STR_R_ASSOC_AST,
										Factory.first(
											[
												Factory.c('r'),
												Factory.c('R')
											]
										)
									),
									Factory.ast(
										STR_L_ASSOC_AST,
										Factory.first(
											[
												Factory.c('l'),
												Factory.c('L')
											]
										)
									),
								]
							),
							Factory.rule_ref(STR_WSC)
						]
					)
				),
				Factory.c(']'),
				Factory.rule_ref(STR_WSC)
			]
		)
	)

	# Character set

	var character_set: Rule = Factory.rule(
		STR_CHAR_SET,
		Factory.first(
			[
				Factory.seq(
					[
						Factory.c("'"),
						Factory.ast(
							STR_SINGLE_QUOTED_CHAR_AST,
							Factory.rule_ref(STR_SINGLE_QUOTED_CHAR)
						),
						Factory.c("'")
					]
				),
				Factory.seq(
					[
						Factory.c('['),
						Factory.ast(
							STR_CHAR_RANGE_AST,
							Factory.seq(
								[
									Factory.optional(
										Factory.c('^')
									),
									Factory.one_or_more(
										Factory.first(
											[
												Factory.rule_ref(STR_CHAR_RANGE),
												Factory.rule_ref(STR_CHAR_RANGE_CHAR)
											]
										)
									)
								]
							)
						),
						Factory.c(']')
					]
				)
			]
		)
	)

	# Single quoted character

	var single_quoted_char: Rule = Factory.rule(
		STR_SINGLE_QUOTED_CHAR,
		Factory.first(
			[
				Factory.rule_ref(STR_ESCAPED_CTRL_CHAR),
				Factory.c("'").invert()
			]
		)
	)

	# Char range

	var char_range: Rule = Factory.rule(
		STR_CHAR_RANGE,
		Factory.seq(
			[
				Factory.rule_ref(STR_CHAR_RANGE_CHAR),
				Factory.c('-'),
				Factory.rule_ref(STR_CHAR_RANGE_CHAR)
			]
		)
	)

	# Char range character

	var char_range_character: Rule = Factory.rule(
		STR_CHAR_RANGE_CHAR,
		Factory.first(
			[
				Factory.c("\\]").invert(),
				Factory.rule_ref(STR_ESCAPED_CTRL_CHAR),
				Factory.string("\\-"),
				Factory.string("\\\\"),
				Factory.string("\\]"),
				Factory.string("\\^")
			]
		)
	)

	# Quoted string

	var quoted_string: Rule = Factory.rule(
		STR_QUOTED_STRING,
		Factory.seq(
			[
				Factory.c('"'),
				Factory.ast(
					STR_QUOTED_STRING_AST,
					Factory.zero_or_more(
						Factory.rule_ref(STR_STR_QUOTED_CHAR)
					)
				),
				Factory.c('"')
			]
		)
	)

	# Character within quoted string

	var str_quoted_char: Rule = Factory.rule(
		STR_STR_QUOTED_CHAR,
		Factory.first(
			[
				Factory.rule_ref(STR_ESCAPED_CTRL_CHAR),
				Factory.c('"\\').invert()
			]
		)
	)

	# Hex digit

	var hex_digit: Rule = Factory.rule(
		STR_HEX,
		Factory.c_union(
			[
				Factory.c_range('0', '9'),
				Factory.c_range('a', 'f'),
				Factory.c_range('A', 'F')
			]
		)
	)

	# Escaped control character

	var escaped_control_character: Rule = Factory.rule(
		STR_ESCAPED_CTRL_CHAR,
		Factory.first(
			[
				Factory.string("\\t"),
				Factory.string("\\b"),
				Factory.string("\\n"),
				Factory.string("\\r"),
				Factory.string("\\f"),
				Factory.string("\\'"),
				Factory.string('\\"'),
				Factory.string("\\\\"),
				Factory.seq(
					[
						Factory.string("\\u"),
						Factory.rule_ref(STR_HEX),
						Factory.rule_ref(STR_HEX),
						Factory.rule_ref(STR_HEX),
						Factory.rule_ref(STR_HEX)
					]
				)
			]
		)
	)

	# Nothing (empty string match)

	var nothing: Rule = Factory.rule(
		STR_NOTHING,
		Factory.ast(
			STR_NOTHING_AST,
			Factory.seq(
				[
					Factory.c('('),
					Factory.rule_ref(STR_WSC),
					Factory.c(')')
				]
			)
		)
	)

	# Match start position

	var start: Rule = Factory.rule(
		STR_START,
		Factory.ast(
			STR_START_AST,
			Factory.c('^')
		)
	)

	return Grammar.grammar_instantiate(
		[
			top_rule,
			rule,
			parens,
			terminals,
			one_or_more_zero_or_more,
			followed_by_not_followed_by,
			optional,
			ast_node_label,
			seq,
			first,
			whitespace_or_comment,
			comment,
			identifier,
			number,
			name_character,
			prec_assoc,
			character_set,
			single_quoted_char,
			char_range,
			char_range_character,
			quoted_string,
			str_quoted_char,
			hex_digit,
			escaped_control_character,
			nothing,
			start
		]
	)


# Return true if subClause precedence is less than or equal to parentClause
# precedence (or if subclause is a Seq clause and parentClause is a First
# clause, for clarity, even though parens are not needed because Seq has higher
# precedence).
static func need_to_add_parens_around_subclause(
		parent_clause : Clause,
		subclause     : Clause) -> bool:

	var clause_prec    : int = \
		_clause_type_to_precedence(parent_clause.__get_script())
	var subclause_prec : int = \
		_clause_type_to_precedence(subclause.__get_script())

	# Always parenthesize Seq inside First for clarity, even though Seq has
	# higher precedence
	return (parent_clause is First and subclause is Seq) \
		or subclause_prec <= clause_prec


# Return true if subclause has lower precedence than an AST node label.
static func need_to_add_parens_around_ast_node_label(
		subclause: Clause) -> bool:

	var ast_node_label_prec: int = +_clause_type_to_precedence(
		'res://addons/PressAccept/Parser/Pika/Clauses/Reesource/ASTNodeLabel.gd'
	)

	var subclause_prec: int = \
		_clause_type_to_precedence(subclause.__get_script())

	return subclause_prec < ast_node_label_prec


# Parse a grammar description in an input string, returning a new Grammar
# object.
static func parse(
		input: String) -> Grammar:

	var grammar    : Grammar = grammar()
	# grammar.DEBUG = true
	var memo_table : MemoTable = grammar.parse(input)

	#   //      ParserInfo.printParseResult("GRAMMAR", memoTable, new String[] { "GRAMMAR", "RULE", "CLAUSE[1]" },
	#   //				/* showAllMatches = */ false);
	#   //
	#   //		System.out.println("\nParsed meta-grammar:");
	#   //		for (var clause : MetaGrammar.grammar.allClauses) {
	#   //			System.out.println("    " + clause.toStringWithRuleNames());
	#   //		}
	
	ParserInfo.print_memo_table(memo_table)

	var syntax_errors = memo_table.get_syntax_errors(
		[
			STR_GRAMMAR,
			STR_RULE,
			STR_CLAUSE + '[' + str(_clause_type_to_precedence(
				'res://addons/PressAccept/Parser/Pika/Clauses/Nonterminal/First.gd'
			)) + ']'
		]
	)

	if not syntax_errors.empty():
		ParserInfo.print_syntax_errors(syntax_errors)

	var top_level_rule: Rule = grammar.get_rule(STR_GRAMMAR)
	var top_level_rule_ast_node_label: String = \
		top_level_rule.labeled_clause.ast_node_label

	if top_level_rule_ast_node_label:
		top_level_rule_ast_node_label = '<root>'

	var top_level_matches = \
		grammar.get_nonoverlapping_matches(STR_GRAMMAR, memo_table)
	
	if top_level_matches is Exception:
		return top_level_matches

	if top_level_matches.empty():
		return Exception.create(
			{
				Exception.STR_EXCEPTION_CODE    : 'Illegal Argument',
				Exception.STR_EXCEPTION_MESSAGE : \
					"Toplevel rule \"" + STR_GRAMMAR + "\" did not match"
			},
			Error
		)

	elif top_level_matches.size() > 1:
		var error_message: String = "Multiple toplevel matches:\n"
		for top_level_match in top_level_matches:
			var top_level_ast_node: ASTNode = ASTNode.astnode_instantiate(
				top_level_rule_ast_node_label,
				top_level_match,
				input
			)

			error_message += top_level_ast_node.to_string()

		return Exception.create(
			{
				Exception.STR_EXCEPTION_CODE    : 'Illegal Argument',
				Exception.STR_EXCEPTION_MESSAGE : error_message
			},
			Error
		)

	var top_level_match = top_level_matches[0]

	# TreeUtils.printTreeView(topLevelMatch, input);

	var top_level_ast_node: ASTNode = ASTNode.astnode_instantiate(
		top_level_rule_ast_node_label,
		top_level_match,
		input
	)

	# System.out.println(topLevelASTNode);

	var rules: Array = [] # ArrayList<> (List<Rule>)
	for ast_node in top_level_ast_node.children:
		if not ast_node.label == STR_RULE_AST:
			return Exception.create(
				{
					Exception.STR_EXCEPTION_CODE    : 'Illegal Argument',
					Exception.STR_EXCEPTION_MESSAGE : 'Wrong node type'
				},
				Error
			)

		var rule: Rule = _parse_rule(ast_node)
		rules.append(rule)

	return Grammar.grammar_instantiate(rules)


# ****************************
# | Private Static Functions |
# ****************************


static func _clause_type_to_precedence(
		klass: String) -> int:

	match klass:
		'res://addons/PressAccept/Parser/Pika/Clauses/Nonterminal/First.gd':
			return 1
		'res://addons/PressAccept/Parser/Pika/Clauses/Nonterminal/Seq.gd':
			return 2
		'res://addons/PressAccept/Parser/Pika/Clauses/Resource/ASTNodeLabel.gd':
			return 3
		# Optional is not present in final grammar, so it is skipped here
		'res://addons/PressAccept/Parser/Pika/Clauses/Nonterminal/FollowedBy.gd', \
		'res://addons/PressAccept/Parser/Pika/Clauses/Nonterminal/NotFollowedBy.gd':
			return 5
		# ZeroOrMore is not present in the final grammar, so it is skipped here
		'res://addons/PressAccept/Parser/Pika/Clauses/Nonterminal/OneOrMore.gd':
			return 6
		# Treat RuleRef as having the same precedence as a terminal for string
		# interning purposes
		'res://addons/PressAccept/Parser/Pika/Clauses/Resource/RuleRef.gd', \
		'res://addons/PressAccept/Parser/Pika/Clauses/Terminal/CharSeq.gd', \
		'res://addons/PressAccept/Parser/Pika/Clauses/Terminal/CharSet.gd', \
		'res://addons/PressAccept/Parser/Pika/Clauses/Terminal/Nothing.gd', \
		'res://addons/PressAcecpt/Parser/Pika/Clauses/Terninal/Start.gd':
			return 7

	return -1


# Expect just a single clause in the list of clauses, and return it, or throw
# an exception if the length of the list of clauses is not 1.
static func _expect_one(
		clauses  : Array, # List<Clause>
		ast_node : ASTNode
		): # -> Clause:

	if clauses.size() != 1:
		return Exception.create(
			{
				Exception.STR_EXCEPTION_CODE    : 'Illegal Argument',
				Exception.STR_EXCEPTION_MESSAGE : \
					'Expected one subclause, got ' + str(clauses.size()) \
					+ ': ' + ast_node.to_string()
			}
		)

	return clauses[0]


# Recursively convert a list of AST nodes into a list of Clauses.
static func _parse_ast_nodes(
		ast_nodes: Array # List<Clause>
		) -> Array: # List<ASTNode>

	var clauses: Array = []
	for ast_node in ast_nodes:
		clauses.append(_parse_ast_node(ast_node))

	return clauses


# Recursively parse a single AST node.
static func _parse_ast_node(
		ast_node: ASTNode): # -> Clause:

	var clause: Clause
	match ast_node.label:
		STR_SEQ_AST:
			clause = Factory.seq(_parse_ast_nodes(ast_node.children))
		STR_FIRST_AST:
			clause = Factory.first(_parse_ast_nodes(ast_node.children))
		STR_ONE_OR_MORE_AST:
			clause = Factory.one_or_more(
				_expect_one(_parse_ast_nodes(ast_node.children), ast_node)
			)
		STR_ZERO_OR_MORE_AST:
			clause = Factory.zero_or_more(
				_expect_one(_parse_ast_nodes(ast_node.children), ast_node)
			)
		STR_OPTIONAL_AST:
			clause = Factory.optional(
				_expect_one(_parse_ast_nodes(ast_node.children), ast_node)
			)
		STR_FOLLOWED_BY_AST:
			clause = Factory.followed_by(
				_expect_one(_parse_ast_nodes(ast_node.children), ast_node)
			)
		STR_LABEL_AST:
			var first_child = ast_node.get_child(0)

			if first_child is Exception:
				return first_child

			var second_child = ast_node.get_child(1)

			if second_child is Exception:
				return second_child

			var sub_child = second_child.get_child(0)

			if sub_child is Exception:
				return sub_child
			
			clause = Factory.ast(
				first_child.get_text(),
				_parse_ast_node(sub_child)
			)
		STR_IDENT_AST:
			clause = Factory.rule_ref(ast_node.get_text())
		STR_QUOTED_STRING_AST:
			clause = Factory.string(
				PressAccept_Parser_Pika_String.unescape_string(
					ast_node.get_text()
				)
			)
		STR_SINGLE_QUOTED_CHAR_AST:
			clause = Factory.c(
				PressAccept_Parser_Pika_String.unescape_char(
					ast_node.get_text()
				)
			)
		STR_START_AST:
			clause = Factory.start()
		STR_NOTHING_AST:
			clause = Factory.nothing()
		STR_CHAR_RANGE_AST:
			clause = Factory.c_range(ast_node.get_text())
		_:
			# Keep recursing for parens (the only type of AST node that doesn't
			# have a label)
			clause = _expect_one(_parse_ast_nodes(ast_node.children), ast_node)

	return clause


# Parse a rule in the AST, returning a new Rule.
static func _parse_rule(
		rule_node: ASTNode): # -> Rule:

	var rule_node_child = rule_node.get_child(0)

	if rule_node_child is Exception:
		return rule_node_child

	var rule_name: String = rule_node_child.get_text()
	var has_precedence: bool = rule_node.children.size() > 2

	var rule_node_third_child = rule_node.get_child(2)

	if rule_node_third_child is Exception:
		return rule_node_third_child

	var associativity = null if rule_node.children.size() < 4 else \
		(Rule.ASSOCIATIVITY.LEFT \
			if rule_node_third_child.label == STR_L_ASSOC_AST
			else (Rule.ASSOCIATIVITY.RIGHT \
				if rule_node_third_child.label == STR_R_ASSOC_AST \
				else null))

	var rule_node_second_child = rule_node.get_child(1)

	if rule_node_second_child is Exception:
		return rule_node_second_child

	var precedence: int = int(rule_node_second_child.get_text()) \
		if has_precedence else -1
	if has_precedence and precedence < 0:
		return Exception.create(
			{
				Exception.STR_EXCEPTION_CODE    : 'Illegal Argument',
				Exception.STR_EXCEPTION_MESSAGE : \
					'Precedence needs to be zero or positive (rule ' \
						+ rule_name + ' has precedence level ' \
						+ str(precedence) + ')'
			},
			Error
		)

	var ast_node = rule_node.get_child(rule_node.children.size() - 1)

	if ast_node is Exception:
		return ast_node

	var clause: Clause = _parse_ast_node(ast_node)
	return Factory.rule(rule_name, precedence, associativity, clause)

