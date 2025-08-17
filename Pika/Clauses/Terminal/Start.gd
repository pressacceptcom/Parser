tool
class_name PressAccept_Parser_Pika_Start

extends PressAccept_Parser_Pika_Terminal

# |=============================|
# |                             |
# |    Press Accept: Parser     |
# | Parsing Algorithms In Godot |
# |                             |
# |=============================|
#
# "A terminal clause that only matches at input position 0."
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
# Class                  : Start
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

const Terminal: Script = PressAccept_Parser_Pika_Terminal

# *************
# | Constants |
# *************

const STR_START: String = '^'

# *************************
# | Meta Static Functions |
# *************************


# this is made up of the following mixins
static func __mixed_info() -> Array:

	return Terminal.__mixed_info()


# ***************************
# | Public Static Functions |
# ***************************


# wraps Mixin functionality to create a new object, use instead of new()
static func start_instantiate() -> PressAccept_Parser_Pika_Start:

	return Terminal.Mixer.instantiate(
		'res://addons/PressAccept/Parser/Pika/Clauses/Terminal/Start.gd',
		[
			{}
		],
		true
	)


# ***************
# | Constructor |
# ***************


func __init(
		init_args    : Dictionary) -> void:

	.__init({})


# ****************
# | Meta Methods |
# ****************


func __get_script():

	return 'res://addons/PressAccept/Parser/Pika/Clauses/Terminal/Start.gd'


# ******************
# | Public Methods |
# ******************


func determine_whether_can_match_zero_chars(): # -> void:

	can_match_zero_chars = true


func match(
		memo_table : MemoTable,
		memo_key   : Array, # : MemoKey,
		input      : String): # -> MemoMatch:

	if memo_key[MemoTable.INT_START_POS_INDEX] == 0:
		# Return a new zero-length match
		return MemoMatch.match_instantiate(memo_key)

	return null


func to_string() -> String:

	if not to_string_cached:
		to_string_cached = STR_START

	return to_string_cached

