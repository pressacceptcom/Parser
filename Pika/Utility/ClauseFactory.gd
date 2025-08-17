tool
class_name PressAccept_Parser_Pika_ClauseFactory

# |=============================|
# |                             |
# |    Press Accept: Parser     |
# | Parsing Algorithms In Godot |
# |                             |
# |=============================|
#
# "Clause factory, enabling the construction of clauses without "new", using
# static imports."
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
# Class                  : ClauseFactory
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



const ASTNodeLabel: Script = PressAccept_Parser_Pika_ASTNodeLabel

const CharSet: Script = PressAccept_Parser_Pika_CharSet

const CharSeq: Script = PressAccept_Parser_Pika_CharSeq

const Clause: Script = PressAccept_Parser_Pika_Clause

const First: Script = PressAccept_Parser_Pika_First

const FollowedBy: Script = PressAccept_Parser_Pika_FollowedBy

const OneOrMore: Script = PressAccept_Parser_Pika_OneOrMore

const NotFollowedBy: Script = PressAccept_Parser_Pika_NotFollowedBy

const Nothing: Script = PressAccept_Parser_Pika_Nothing

const Rule: Script = PressAccept_Parser_Pika_Rule

const RuleRef: Script = PressAccept_Parser_Pika_RuleRef

const Seq: Script = PressAccept_Parser_Pika_Seq

const Start: Script = PressAccept_Parser_Pika_Start

# ***************************
# | Public Static Functions |
# ***************************

# Construct a Rule.
static func rule(
		rule_name : String,
		clause    : Clause) -> Rule:

	# Use -1 as precedence if rule group has only one precedence
	return Rule.rule_instantiate(rule_name, clause, -1, null)


# Construct a Rule with the given precedence and associativity.
static func full_rule(
		rule_name     : String,
		precedence    : int,
		associativity,
		clause        : Clause) -> Rule:

	return Rule.rule_instantiate(rule_name, clause, precedence, associativity)


# Construct a Seq clause.
static func seq(
		subclauses: Array # Clause...
		) -> Seq:

	return Seq.seq_instantiate(subclauses)


# Construct a OneOrMore clause.
static func one_or_more(
		subclause: Clause) -> Clause:

	# It doesn't make sense to wrap these clause types in OneOrMore, but the
	# OneOrMore should have no effect if this does occur in the grammar, so
	# remove it
	if subclause is OneOrMore \
			or subclause is Nothing \
			or subclause is FollowedBy \
			or subclause is NotFollowedBy \
			or subclause is Start:
		return subclause

	return OneOrMore.oneormore_instantiate(subclause)


# Construct an Optional clause.
static func optional(
		subclause: Clause) -> Clause:

	# Optional(X) -> First(X, Nothing)
	return first( [ subclause, nothing() ] )


# Construct a ZeroOrMore clause.
static func zero_or_more(
		subclause: Clause) -> Clause:
		
	# ZeroOrMore(X) => Optional(OneOrMore(X)) => First(OneOrMore(X), Nothing)
	return optional(one_or_more(subclause))


# Construct a First clause.
static func first(
		subclauses: Array
		) -> Clause:

	return First.first_instantiate(subclauses)


# Construct a FollowedBy clause.
static func followed_by(
		subclause: Clause):

	if subclause is Nothing:
		# FollowedBy(Nothing) -> Nothing (since Nothing always matches)
		return subclause
	elif subclause is FollowedBy \
			or subclause is NotFollowedBy \
			or subclause is Start:
		return Exception.create(
			{
				Exception.STR_EXCEPTION_CODE    : 'Illegal Argument',
				Exception.STR_EXCEPTION_MESSAGE : 'FollowedBy (' \
					+ subclause.get_script().resource_path + ') is nonsensical'
			},
			Error
		)

	return FollowedBy.followedby_instantiate(subclause)


# Construct a NotFollowedBy clause.
static func not_followed_by(
		subclause: Clause) -> Clause:

	if subclause is Nothing:
		return Exception.create(
			{
				Exception.STR_EXCEPTION_CODE    : 'Illegal Argument',
				Exception.STR_EXCEPTION_MESSAGE : \
					'NotFollowedBy (Nothing) will never match anything'
			},
			Error
		)
	elif subclause is NotFollowedBy:
		# Doubling NotFollowedBy yields FollowedBy.
		# N.B. this will not catch the case of "X <- !Y; Y <- !Z;", 
		# since RuleRefs are not resolved yet
		return FollowedBy \
			.followedby_instantiate(subclause.labeled_subclauses[0].clause)
	elif subclause is FollowedBy \
			or subclause is Start:
		return Exception.create(
			{
				Exception.STR_EXCEPTION_CODE    : 'Illegal Argument',
				Exception.STR_EXCEPTION_MESSAGE : \
					'NotFollowedBy (' + subclause.get_script().resource_path \
					+ ') will never match anything'
			},
			Error
		)

	return NotFollowedBy.notfollowedby_instantiate(subclause)


# Construct a Start terminal.
static func start() -> Clause:

	return Start.start_instantiate()


# Construct a Nothing terminal.
static func nothing() -> Clause:

	return Nothing.nothing_instantiate()


# Construct a terminal that matches a string token.
static func string(
		string: String) -> Clause:

	if string.length() == 1:
		return c(string[0]) as Clause
	else:
		return CharSeq.charseq_instantiate(string, false)


# Construct a terminal that matches one instance of any character given in the
# varargs param.
static func c(
		chars: String) -> CharSet:

	return CharSet.charset_instantiate(chars)


# Construct a terminal that matches one instance of any character in a given
# string.
static func c_in_str(
		string: String) -> CharSet:

	return CharSet.charset_instantiate(string)


# Construct a terminal that matches a character range.
static func c_range(
		min_char: String,
		max_char: String) -> CharSet:

	var min_char_int: int = ord(min_char)
	var max_char_int: int = ord(max_char)

	if min_char_int > max_char_int:
		return Exception.create(
			{
				Exception.STR_EXCEPTION_CODE    : 'Illegal Argument',
				Exception.STR_EXCEPTION_MESSAGE : 'max_char < min_char'
			},
			Error
		)

	var bs: CharSet.BitSet = CharSet.BitSet.new()
	bs.set_bit_range(min_char_int, max_char_int + 1)
	return CharSet.charset_instantiate_with_bitset(bs)


# Construct a terminal that matches a character range, specified using regexp
# notation without the square brackets.
static func c_range_regex(
		char_range_str: String) -> CharSet:

	var invert: bool = char_range_str.begins_with('^')
	var char_list = PressAccept_Parser_Pika_String.get_char_range_chars(
		char_range_str.substr(1) if invert else char_range_str
	)
	var chars: CharSet.BitSet = CharSet.BitSet.new()
	for i in range(char_list.size()):
		var c: String = char_list[i]
		if c.length() == 2:
			# Unescape \^, \-, \], \\
			c = c.substr(1)

		var c0: String = c[0]
		if i <= char_list.size() - 3 and char_list[i + 1] == '-':
			var c_end: String = char_list[i + 2]
			if c_end.length() == 2:
				# Unescape \^, \-, \], \\
				c_end = c_end.substr(1)
			var c_end0 = c_end[0]
			var c0_int     : int = ord(c0)
			var c_end0_int : int = ord(c_end0)
			if c_end0_int < c0_int:
				return Exception.create(
					{
						Exception.STR_EXCEPTION_CODE    : 'Illegal Argument',
						Exception.STR_EXCEPTION_MESSAGE : 
							'Char range limits out of order: ' \
								+ c0 + ', ' + c_end0
					},
					Error
				)
			chars.set_bit_range(c0_int, c_end0_int + 1)
			i += 2
		else:
			chars.set_bit(ord(c0))

	return CharSet.charset_instantiate_with_bitset(chars).invert() \
		if invert else CharSet.charset_instantiate_with_bitset(chars)


# Construct a character set as the union of other character sets.
static func c_union(
		charsets: Array # CharSet...
		) -> CharSet:

	return CharSet.charset_instantiate_with_charsets(charsets)


# Construct an ASTNodeLabel.
static func ast(
		ast_node_label : String,
		clause         : Clause) -> Clause:

	return ASTNodeLabel.astnodelabel_instantiate(ast_node_label, clause)


# Construct a RuleRef.
static func rule_ref(
		rule_name: String) -> Clause:

	return RuleRef.ruleref_instantiate(rule_name)

