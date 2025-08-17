tool
class_name PressAccept_Parser_Pika_Terminal

extends PressAccept_Parser_Pika_Clause

# |=============================|
# |                             |
# |    Press Accept: Parser     |
# | Parsing Algorithms In Godot |
# |                             |
# |=============================|
#
# "The superclass of all terminal clauses."
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
# Class                  : Terminal
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

const Clause: Script = PressAccept_Parser_Pika_Clause

# *************************
# | Meta Static Functions |
# *************************


# this is made up of the following mixins
static func __mixed_info() -> Array:

	return Clause.__mixed_info()


# ***************************
# | Public Static Functions |
# ***************************


# wraps Mixin functionality to create a new object, use instead of new()
static func terminal_instantiate() -> PressAccept_Parser_Pika_Terminal:

	return Clause.Mixer.instantiate(
		'res://addons/PressAccept/Parser/Pika/Clauses/Terminal/Terminal.gd',
		[
			{}
		],
		true
	)


# ***************
# | Constructor |
# ***************


func __init(
		init_args: Dictionary) -> void:

	.__init(
		{ STR_SUBCLAUSES: [] }
	)


# ****************
# | Meta Methods |
# ****************


func __get_script():

	return 'res://addons/PressAccept/Parser/Pika/Clauses/Terminal/Terminal.gd'

