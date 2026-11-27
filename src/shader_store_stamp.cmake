# Writes OUTPUT with KYTY_SHADER_STORE_STAMP: a hash of the files listed in INPUTS (one path per
# line) that decide what the shader store holds. Rebuilds that touch none of them keep the store.
# OUTPUT is only rewritten when the stamp changes, so unrelated builds recompile nothing.
if(NOT DEFINED INPUTS OR NOT DEFINED OUTPUT OR NOT DEFINED ROOT)
	message(FATAL_ERROR "shader_store_stamp.cmake requires INPUTS, OUTPUT and ROOT")
endif()

file(STRINGS "${INPUTS}" files)
list(SORT files)
set(digests "")
foreach(file IN LISTS files)
	file(SHA256 "${file}" digest)
	file(RELATIVE_PATH name "${ROOT}" "${file}")
	string(APPEND digests "${name}:${digest}\n")
endforeach()
string(SHA256 total "${digests}")
string(SUBSTRING "${total}" 0 16 stamp)

set(contents "#pragma once\n#include <cstdint>\ninline constexpr uint64_t KYTY_SHADER_STORE_STAMP = 0x${stamp}ull;\n")
if(EXISTS "${OUTPUT}")
	file(READ "${OUTPUT}" old)
	if(old STREQUAL contents)
		return()
	endif()
endif()
file(WRITE "${OUTPUT}" "${contents}")
