tool
class_name PressAccept_Parser_Pika_String

# |=============================|
# |                             |
# |    Press Accept: Parser     |
# | Parsing Algorithms In Godot |
# |                             |
# |=============================|
#
# "String utilities."
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
# Class                  : String
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

const Hexadecimal: Script = PressAccept_Byter_Hexadecimal

const Error     : Script = PressAccept_Error_Error
const Exception : Script = PressAccept_Error_Exception

# ***************************
# | Public Static Functions |
# ***************************


# Escape a character
static func escape_char(
		c: String) -> String:

	var ord_c: int = ord(c)

	if ord_c >= 32 and ord_c <= 126:
		return c

	match c:
		"\n":
			return "\\n"
		"\r":
			return "\\r"
		"\t":
			return "\\t"
		"\f":
			return "\\f"
		"\b":
			return "\\b"
		_:
			return "\\u" + Hexadecimal.unsigned2str(ord(c)).pad_zeros(4)


# Escape a character for inclusion in a character range pattern
static func escape_char_range_char(
		c: String) -> String:

	if not c:
		return c

	match c:
		']':
			return "\\]"
		'^':
			return "\\^"
		'-':
			return "\\-"
		"\\":
			return "\\\\"
		_:
			return escape_char(c)


# Escape a string
static func escape_string(
		chars: String) -> String:

	var buf: String = ''

	for i in range(chars.length()):
		var c: String = chars[i]
		buf += '\\"' if c == '"' else escape_quoted_string_char(c)

	return buf


# Escape a single-quoted character
static func escape_quoted_char(
		c: String) -> String:

	match c:
		"\'":
			return "\\'"
		"\\":
			return "\\\\"
		_:
			return escape_char(c)


# Escape a character
static func escape_quoted_string_char(
		c: String) -> String:

	match c:
		'"':
			return '\\"'
		"\\":
			return "\\\\"
		_:
			return escape_char(c)


# Get the sequence of (possibly escaped) characters in a char range string
static func get_char_range_chars(
		chars: String): # -> Array:

	var char_range_chars: Array = []

	var i: int = 0
	while i < chars.length():
		var c: String = chars[i]
		if c == "\\":
			var chars_length: int = chars.length()
			if i == chars_length - 1:
				return Exception.create(
					{
						Exception.STR_EXCEPTION_CODE    : 'Illegal Argument',
						Exception.STR_EXCEPTION_MESSAGE : \
							'Got backslash at end of char range'
					},
					Error
				)
			if chars[i + 1] == 'u':
				if i > chars_length - 6:
					return Exception.create(
						{
							Exception.STR_EXCEPTION_CODE    : \
								'Illegal Argument',
							Exception.STR_EXCEPTION_MESSAGE : \
								'Truncated Unicode character sequence'
						},
						Error
					)
				char_range_chars.append(unescape_char(chars.substr(i, 6)))
				# Consume escaped characters
				i += 6
			else:
				var escape_seq: String = chars.substr(i, 2)
				if escape_seq == "\\-" \
						or escape_seq == "\\^" or escape_seq == "\\]":
					# Preserve range-specific escaping for char ranges
					char_range_chars.append(escape_seq)
				else:
					char_range_chars.append(unescape_char(escape_seq))
				i += 2 # Consume escaped character
		else:
			char_range_chars.append(c)
			i += 1

	return char_range_chars


# Convert a hex digit to an integer
static func hex_to_int(
		c: String) -> int:

	return ('0x' + c).hex_to_int()


# Unescape a single character
static func unescape_char(
		escaped_char: String): # -> String:

	if escaped_char.length() == 0:
		return Exception.create(
			{
				Exception.STR_EXCEPTION_CODE    : 'Illegal Argument',
				Exception.STR_EXCEPTION_MESSAGE : \
					'Illegal hex digit: ' + escaped_char
			},
			Error
		)
	elif escaped_char.length() == 1:
		return escaped_char

	match escaped_char:
		"\\t":
			return "\t"
		"\\b":
			return "\b"
		"\\n":
			return "\n"
		"\\r":
			return "\r"
		"\\f":
			return "\f"
		"\\'":
			return "'"
		'\\"':
			return '"'
		"\\\\":
			return "\\"
		_:
			if escaped_char.begins_with("\\u") and escaped_char.length() == 6:
				var hex_digits = escaped_char.substr(2)
				return char(hex_to_int(hex_digits))
			else:
				return Exception.create(
					{
						Exception.STR_EXCEPTION_CODE    : 'Illegal Argument',
						Exception.STR_EXCEPTION_MESSAGE : \
							'Illegal charater: ' + escaped_char
					},
					Error
				)

# Unescape a string
static func unescape_string(
		chars: String): # -> String:

	var buf: String = ''

	var i: int = 0
	while i < chars.length():
		var c: String = chars[i]
		if c == "\\":
			var chars_length: int = chars.length()
			if i == chars_length - 1:
				return Exception.create(
					{
						Exception.STR_EXCEPTION_CODE    : 'Illegal Argument',
						Exception.STR_EXCEPTION_MESSAGE : \
							'Got backslash at end of quoted string'
					},
					Error
				)
			if chars[i + 1] == 'u':
				if i > chars_length - 6:
					return Exception.create(
						{
							Exception.STR_EXCEPTION_CODE    : 'Illegal Argument',
							Exception.STR_EXCEPTION_MESSAGE : \
								'Truncated Unicode character sequence'
						},
						Error
					)
				buf += unescape_char(chars.substr(i, 6))
				i += 6 # Consume escaped characters
			else:
				buf += unescape_char(chars.substr(i, 2))
				i += 2 # Consume escaped characters
		else:
			buf += c
			i += 1

	return buf


