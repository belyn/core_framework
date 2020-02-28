#include "lcrypt.h"

#define hex_char(ch) ({(uint8_t)((ch) > 9 ? (ch) + 55: (ch) + 48);})

#define is_normal_char(ch) ({((ch) >= 'a' && (ch) <= 'z') || ((ch) >= 'A' && (ch) <= 'Z') || ((ch) >= '0' && (ch) <= '9') ? 1 : 0;})

/* url编码 */
int lurlencode(lua_State *L){
	size_t url_len;
  const char* url = luaL_checklstring(L, 1, &url_len);
	if (!url)
		return luaL_error(L, "Invalid url text");

	luaL_Buffer convert_url;
	luaL_buffinit(L, &convert_url);

	while (*url) {
		uint8_t ch = (uint8_t)*url++;
		if (ch == ' ') {
			luaL_addlstring(&convert_url, "%20", 3);
			continue;
		}
		if (is_normal_char(ch) || strchr("-_.!~*'()", ch)){
			luaL_addchar(&convert_url, ch);
			continue;
		}
		char ver[3] = {'%', hex_char(((uint8_t)ch) >> 4), hex_char(((uint8_t)ch) & 15)};
		luaL_addlstring(&convert_url, ver, 3);
	}

	luaL_pushresult(&convert_url);
	return 1;
}

/* url解码 */
int lurldecode(lua_State *L){
	size_t url_len;
  const char* url = luaL_checklstring(L, 1, &url_len);
	if (!url)
		return luaL_error(L, "Invalid url text");

	luaL_Buffer convert_url;
	luaL_buffinit(L, &convert_url);

	while (*url) {
		uint8_t ch = (uint8_t)*url++;
		if (ch != '%') {
			luaL_addchar(&convert_url, ch);
			continue;
		}
		char vert[2];
		vert[0] = (uint8_t)*url++;
		vert[1] = (uint8_t)*url++;
		luaL_addchar(&convert_url, (uint8_t)((vert[0] - 48 - ((vert[0] >= 'A') ? 7 : 0) - ((vert[0] >= 'a') ? 32 : 0)) * 16 + (vert[1] - 48 - ((vert[1] >= 'A') ? 7 : 0) - ((vert[1] >= 'a') ? 32 : 0))));
	}
	
	luaL_pushresult(&convert_url);
	return 1;
}
