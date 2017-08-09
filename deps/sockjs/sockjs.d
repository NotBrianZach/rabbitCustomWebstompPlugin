src/sockjs_action.erl:: src/sockjs_internal.hrl; @touch $@
src/sockjs_cowboy_handler.erl:: src/sockjs_internal.hrl; @touch $@
src/sockjs_filters.erl:: src/sockjs_internal.hrl; @touch $@
src/sockjs_handler.erl:: src/sockjs_internal.hrl; @touch $@
src/sockjs_http.erl:: src/sockjs_internal.hrl; @touch $@
src/sockjs_multiplex.erl:: src/sockjs_service.erl; @touch $@
src/sockjs_session.erl:: src/sockjs_internal.hrl; @touch $@
src/sockjs_util.erl:: src/sockjs_internal.hrl; @touch $@
src/sockjs_ws_handler.erl:: src/sockjs_internal.hrl; @touch $@

COMPILE_FIRST += sockjs_service
