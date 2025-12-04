#set search_path "
#	$search_path
#	../lib/t40lp/nldm
#"

set search_path "
	$search_path
	../lib/t28hpcplus/nldm/
	../lib/tsdn28hpcpuhdb512x128m4m_170a/NLDM/
"

#set target_library "
#	tcbn40lpbwpwc.db
#"

set target_library "
	tcbn28hpcplusbwp30p140ssg0p81v125c.db
	tsdn28hpcpuhdb512x128m4m_170a_ssg0p81v125c.db
"

set link_library "
	*
	$target_library
"

#set_dont_use tcbn40lpbwpwc/CK*
#set_dont_touch tcbn40lpbwpwc/CK*

set_dont_use tcbn28hpcplusbwp30p140ssg0p81v125c/CK*
set_dont_touch tcbn28hpcplusbwp30p140ssg0p81v125c/CK*
