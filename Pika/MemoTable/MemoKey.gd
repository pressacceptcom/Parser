tool
class_name PressAccept_Parser_Pika_MemoKey

# |=============================|
# |                             |
# |    Press Accept: Parser     |
# | Parsing Algorithms In Godot |
# |                             |
# |=============================|
#
# "A memo table key, consisting of a Clause and a match start position."
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
# Class                  : MemoKey
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

const Comparator     : Script = PressAccept_Comparator_Comparator
const DictComparator : Script = PressAccept_Comparator_Dictionary

const Conductable: Script = PressAccept_Conductor_Conductable
const CONDUCTABLE: String = Conductable.STR_MIXIN_IDENTIFIER

const Mixer: Script = PressAccept_Mixer_Mixer

const Normalizer: Script = PressAccept_Normalizer_Normalizer

const Typer: Script = PressAccept_Typer_Typer

# ********************
# | Internal Classes |
# ********************

class MemoKeyComparator:
	extends Comparator


	static func __get_script() -> String:

		return 'res://addons/PressAccept/Parser/Pika/MemoTable/MemoKey.gd'


	# by_ref is true for dictionaries, clauses will match references
	static func compare(
			a,
			b,
			by_ref: bool = true) -> int:

		var Self: Script = \
			load('res://addons/PressAccept/Parser/Pika/MemoTable/MemoKey.gd') as Script

		if a is Self and b is Self:
			if a == b:
				return Comparator.ENUM_RELATION.EQUAL
			if a.clause == b.clause:
				if a.start_pos == b.start_pos:
					return Comparator.ENUM_RELATION.EQUAL
				elif a.start_pos > b.start_pos:
					return Comparator.ENUM_RELATION.GREATER_THAN
				else:
					return Comparator.ENUM_RELATION.LESS_THAN
			elif a.clause.hash() > b.clause.hash():
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

# __to_dict keys
const STR_CLAUSE_KEY    : String = 'clause'
const STR_START_POS_KEY : String = 'start_pos'

# *************************
# | Meta Static Functions |
# *************************


# this is made up of the following mixins
static func __mixed_info() -> Array:

	return [
		# Comparable Dependency
		'res://addons/PressAccept/Conductor/Conductable.gd',
		# Comparison methods
		'res://addons/PressAccept/Utilizer/Mixins/Comparable.gd'
	]


# |------------|
# | Normalizer |
# |------------|


# Normalizer hook for normalizing value to PressAccept_Utilizer_Data_Array
static func __normalize_to(
		value): # -> PressAccept_Utilizer_Data_Array:

	return normalize_to(value)


# Normalizer hook for determining if value can be normalized to ..._Array
static func __is_normalizable(
		value) -> bool:

	return is_normalizable(value)


# Normalizer convenience method giving all types ..._Array can be normalized to
#
# NOTE: for convenience/informational purposes only (not tested in Normalizer)
static func __normalizable_to() -> Array:

	return [
		'res://addons/PressAccept/Parser/Pika/MemoTable/MemoKey.gd',
		Typer.STR_DICT,
		Typer.STR_STRING
	]


# ***************************
# | Public Static Functions |
# ***************************


# wraps Mixin functionality to create a new object, use instead of new()
static func memokey_instantiate(
		init_clause, # : Clause,
		init_start_pos : int) -> PressAccept_Parser_Pika_MemoKey:

	return Mixer.instantiate(
		'res://addons/PressAccept/Parser/Pika/MemoTable/MemoKey.gd',
		[
			init_clause,
			init_start_pos
		],
		true
	)


# normalize a given value to a PressAccept_Utilizer_Array
#
# returns null if value can't be normalized
static func normalize_to(
		value) -> PressAccept_Parser_Pika_MemoKey:

	if value is \
			load('res://addons/PressAccept/Parser/MemoTable/MemoKey.gd') as Script:
		return value

	value = Normalizer.normalize_to_dict(value)

	if not value \
			or not STR_CLAUSE_KEY in value \
			or not STR_START_POS_KEY in value:
		return null

	return memokey_instantiate(value['clause'], value['start_pos'])


# can a value be normalized to a PressAccept_Utilizer_Array
static func is_normalizable(
		value) -> bool:

	if Normalizer.is_normalizable_to(value, Typer.STR_DICT):
		var dict: Dictionary = Normalizer.normalize_to_dict(value)

		return dict and STR_CLAUSE_KEY in dict and STR_START_POS_KEY in dict

	return false


# *********************
# | Public Properties |
# *********************

# The Clause object
var clause # : Clause

# The start position
var start_pos: int

# **********************
# | Private Properties |
# **********************

var _being_output: bool = false

# ***************
# | Constructor |
# ***************


func __init(
		init_clause, # : Clause,
		init_start_pos : int) -> void:

	clause    = init_clause
	start_pos = init_start_pos


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
		return "\n" + prefix + 'MemoKey:' + str(self.get_instance_id())

	_being_output = true

	var output_str: String = ''
	
	output_str += "\n" + prefix + self.__get_script() \
		+ ' (' + str(self.get_instance_id()) + ') ='

	output_str += self[CONDUCTABLE].__output(prefix + tab_char, tab_char)
	output_str += self[COMPARABLE].__output(prefix + tab_char, tab_char)

	output_str += "\n" + prefix + tab_char + 'clause: '
	if clause:
		output_str += clause.__output(prefix + tab_char + tab_char, tab_char)
	else:
		output_str +=  'null'

	output_str += "\n" + prefix + tab_char + 'start_pos: ' + str(start_pos)

	_being_output = false
	
	return output_str


# ****************
# | Meta Methods |
# ****************


func __get_script():

	return 'res://addons/PressAccept/Parser/Pika/MemoTable/MemoKey.gd'


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
		load('res://addons/PressAccept/Parser/Pika/MemoTable/MemoKey.gd') as Script

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

	var return_value = MemoKeyComparator
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
		STR_CLAUSE_KEY    : clause,
		STR_START_POS_KEY : start_pos
	}


# Normalizer.normalize_to_string compatibility, returns string representation
func __to_string() -> String:

	return str(self)


# ******************
# | Public Methods |
# ******************


func hash() -> int:

	if clause:
		return clause.hash() ^ start_pos

	return start_pos


# compare a target value against internal seq returning Comparator.ENUM_RELATION
func make_comparison(
		target_value,
		by_ref: bool = false):

	var Self: Script = \
		load('res://addons/PressAccept/Parser/Pika/MemoTable/MemoKey.gd') as Script

	if not target_value is Self:
		if Normalizer.is_normalizeable_to_dict(target_value):
			target_value = Normalizer.normalize_to_dict(target_value)
		else:
			target_value = Normalizer.normalize_to_string(target_value)

	return self[COMPARABLE].make_comparison(target_value, by_ref)


func to_string_with_rule_names() -> String:

	if clause == null:
		return 'clause = null : start_pos = ' + str(start_pos)

	return clause.to_string_with_rule_names() + ' : ' + str(start_pos)


func to_string() -> String:

	if clause == null:
		return 'clause = null : ' + str(start_pos)

	return clause.to_string() + ' : ' + str(start_pos)

