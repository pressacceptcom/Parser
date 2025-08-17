tool
class_name PressAccept_Parser_Pika_IntervalUnion

# |=============================|
# |                             |
# |    Press Accept: Parser     |
# | Parsing Algorithms In Godot |
# |                             |
# |=============================|
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
# Class                  : IntervalUnion
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

const Throwable: Script = PressAccept_Utilizer_Mixins_Throwable
const THROWABLE: String = Throwable.STR_MIXIN_IDENTIFIER

# *************************
# | Meta Static Functions |
# *************************


# this is made up of the following mixins (it overrides some methods)
static func __mixed_info() -> Array:

	return [
		# throwable dependency
		'res://addons/PressAccept/Conductor/Conductable.gd',
		# throwable
		'res://addons/PressAccept/Utilizer/Mixins/Throwable.gd'
	]


# ***************************
# | Public Static Functions |
# ***************************


static func intervalunion_instantiate() -> PressAccept_Parser_Pika_IntervalUnion:

	return Mixer.instantiate(
		'res://addons/PressAccept/Parser/Pika/Utility/IntervalUnion.gd',
		[],
		true
	)


# **********************
# | Private Properties |
# **********************

var _nonoverlapping_ranges : OrderedDictionary

var _being_output          : bool = false

# ***************
# | Constructor |
# ***************


func __init() -> void:

	_nonoverlapping_ranges = OrderedDictionary.ordereddictionary_instantiate()
	_nonoverlapping_ranges.enable_autosort()


# ********************
# | Built-In Methods |
# ********************


# dislay this array as a pretty-printed string
func _to_string() -> String:

	return __output('')


# pretty print the internal sequence info prefaced by, and using a whitespace
func __output(
		prefix   : String,
		tab_char : String = "\t") -> String:


	if _being_output:
		return "\n" + prefix + __get_script() + ':' \
			+ str(get_instance_id())

	_being_output = true

	var output_str: String = ''
	
	output_str += "\n" + prefix + __get_script() + ' (' \
		+ str(get_instance_id()) + ') ='
	output_str += self[CONDUCTABLE].__output(prefix + tab_char, tab_char)
	output_str += self[THROWABLE].__output(prefix + tab_char, tab_char)
	output_str += "\n" + prefix + tab_char + '_nonoverlapping_ranges:'
	output_str += _nonoverlapping_ranges \
		.__output(prefix + tab_char + tab_char, tab_char)

	_being_output = false

	return output_str


# ****************
# | Meta Methods |
# ****************


func __get_script():

	return 'res://addons/PressAccept/Parser/Pika/Utility/IntervalUnion.gd'


# ******************
# | Public Methods |
# ******************


# Add a range to a union of ranges.
func add_range(
		start_pos : int,
		end_pos   : int):

	if end_pos < start_pos:
		return self[THROWABLE].throw(
			{
				Exception.STR_EXCEPTION_CODE: 'Invalid Parameter',
				Exception.STR_EXCEPTION_MESSAGE: 'end_pos < start_pos'
			},
			Error
		)

	# Try merging new range with floor entry in TreeMap
	var floor_entry_start = _nonoverlapping_ranges.floor_key(start_pos)
	var floor_entry_end   = null if floor_entry_start == null \
		else _nonoverlapping_ranges.get_value(floor_entry_start, true)
	var new_entry_range_start : int
	var new_entry_range_end   : int
	if floor_entry_start == null or floor_entry_end < start_pos:
		# There is no startFloorEntry, or startFloorEntry ends before startPos
		# -- add a new entry
		new_entry_range_start = start_pos
		new_entry_range_end   = end_pos
	else:
		# startFloorEntry overlaps with range -- extend startFloorEntry
		new_entry_range_start = floor_entry_start
		new_entry_range_end   = max(floor_entry_end, end_pos)

	# Try merging new range with the following entr(ies) in TreeMap
	# 
	# 3-8 11-15 + 2-18 -> 2-18 , 3-8 11-19 + 2 - 18 -> 2-19
	var higher_entry_start = \
		_nonoverlapping_ranges.ceiling_key(new_entry_range_start, true)
	var higher_entry_end = null if higher_entry_start == null \
		else _nonoverlapping_ranges.get_value(higher_entry_start, true)
	if higher_entry_start != null \
			and higher_entry_start <= new_entry_range_end:
		while higher_entry_start != null \
				and higher_entry_start <= new_entry_range_end:
			# Expanded-range entry overlaps with the following entry -- collapse
			# them into one
			_nonoverlapping_ranges.remove(higher_entry_start, true)
			var expanded_range_end: int = \
				max(new_entry_range_end, higher_entry_end)
			_nonoverlapping_ranges.set_value(
				new_entry_range_start,
				expanded_range_end,
				true
			)

			higher_entry_start = \
				_nonoverlapping_ranges.ceiling_key(new_entry_range_start, true)
			higher_entry_end = null if higher_entry_start == null \
				else _nonoverlapping_ranges.get_value(higher_entry_start, true)
	else:
		# There's no overlap, just add the new entry (may overwrite the earlier
		# entry for the range start)
		_nonoverlapping_ranges.set_value(
			new_entry_range_start,
			new_entry_range_end,
			true
		)


# Get the inverse of the intervals in this set within [StartPos, endPos).
func invert(
		start_pos : int,
		end_pos   : int) -> PressAccept_Parser_Pika_IntervalUnion:

	var inverted_interval_set: PressAccept_Parser_Pika_IntervalUnion = \
		load('res://addons/PressAccept/Parser/Pika/Utility/IntervalUnion.gd') \
			.intervalunion_instantiate()

	var prev_end_pos: int = start_pos
	if not _nonoverlapping_ranges.empty():
		for curr_start_pos in _nonoverlapping_ranges.sequence:
			if curr_start_pos > end_pos:
				break

			var curr_end_pos: int = \
				_nonoverlapping_ranges.get_value(curr_start_pos, true)
			if curr_end_pos > prev_end_pos:
				# There's a gap of at least one position between adjacent ranges
				inverted_interval_set.add_range(prev_end_pos, curr_start_pos)

			prev_end_pos = curr_end_pos

		var last_entry_end_pos: int = _nonoverlapping_ranges.get_value(
			_nonoverlapping_ranges.last_key(),
			true
		)
		if last_entry_end_pos < end_pos:
			# Final range: there is at least one position before endPos
			inverted_interval_set.add_range(last_entry_end_pos, end_pos)
	else:
		inverted_interval_set.add_range(start_pos, end_pos)

	return inverted_interval_set


# Return true if the specified range overlaps with any range in interval union.
func range_overlaps(
		start_pos : int,
		end_pos   : int) -> bool:

	# Range overlap test: https://stackoverflow.com/a/25369187/3950982
	# (Need to repeat for both floor entry and ceiling entry)
	var floor_entry_start = _nonoverlapping_ranges.floor_key(start_pos)
	if floor_entry_start != null:
		var floor_entry_end = \
			_nonoverlapping_ranges.get_value(floor_entry_start, true)
		if (max(end_pos, floor_entry_end) - min(start_pos, floor_entry_start)) \
				< ((end_pos - start_pos) \
					+ (floor_entry_end - floor_entry_start)):
			return true

	var ceil_entry_start = _nonoverlapping_ranges.ceiling_key(start_pos)
	if ceil_entry_start != null:
		var ceil_entry_end = \
			_nonoverlapping_ranges.get_value(ceil_entry_start, true)
		if (max(end_pos, ceil_entry_end) - min(start_pos, ceil_entry_start)) \
				< ((end_pos - start_pos) \
					+ (ceil_entry_end - ceil_entry_start)):
			return true

	return false


func get_nonoverlapping_ranges() -> OrderedDictionary:

	return _nonoverlapping_ranges

