src/cowboy_handler.erl:: src/cowboy_middleware.erl; @touch $@
src/cowboy_rest.erl:: src/cowboy_sub_protocol.erl; @touch $@
src/cowboy_router.erl:: src/cowboy_middleware.erl; @touch $@
src/cowboy_websocket.erl:: src/cowboy_sub_protocol.erl; @touch $@

COMPILE_FIRST += cowboy_sub_protocol cowboy_middleware
