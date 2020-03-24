#define LUA_LIB

#include <core.h>

static void
TASK_CB(CORE_P_ core_task *task, int revents){
	lua_State *co = (lua_State *) core_get_watcher_userdata(task);
	if (co && (lua_status(co) == LUA_YIELD || lua_status(co) == LUA_OK)){
		int status = CO_RESUME(co, NULL, lua_status(co) == LUA_YIELD ? lua_gettop(co) : lua_gettop(co) - 1);
		if (status != LUA_YIELD && status != LUA_OK){
			LOG("ERROR", lua_tostring(co, -1));
		}
		core_task_stop(CORE_LOOP_ task);
	}
}

static int
task_new(lua_State *L){
	core_task *task = lua_newuserdata(L, sizeof(core_task));
	if (!task) return 0;

	core_task_init(task, TASK_CB);

	luaL_setmetatable(L, "__Task__");

	return 1;
}

static int
task_start(lua_State *L){
	core_task *task = (core_task *) luaL_testudata(L, 1, "__Task__");
	if (!task) return luaL_error(L, "attemp to pass a invaild core_task value.");

	lua_State *co = lua_tothread(L, 2);
	if (!co) return luaL_error(L, "attemp to pass a invaild lua_State value.");

	/* 这里假设栈大小永远够用, 因为调用与回调都不需要传入那么多参数 */
	lua_xmove(L, co, lua_gettop(L) - 2);

	core_set_watcher_userdata(task, co);

	core_task_start(CORE_LOOP_ task);

	return 1;
}

static int
task_stop(lua_State *L){
	core_task *task = (core_task *) luaL_testudata(L, 1, "__Task__");
	if (!task) return luaL_error(L, "attemp to pass a invaild core_task value.");

	core_task_stop(CORE_LOOP_ task);

	return 0;
}


LUAMOD_API int
luaopen_task(lua_State *L){
	luaL_checkversion(L);
	luaL_newmetatable(L, "__Task__");
	lua_pushstring (L, "__index");
	lua_pushvalue(L, -2);
	lua_rawset(L, -3);
  lua_pushliteral(L, "__mode");
  lua_pushliteral(L, "kv");
  lua_rawset(L, -3);
	luaL_Reg task_libs[] = {
		{"new", task_new},
		{"start", task_start},
		{"stop", task_stop},
		{NULL, NULL}
	};
	luaL_setfuncs(L, task_libs, 0);
	luaL_newlib(L, task_libs);
	return 1;
}
