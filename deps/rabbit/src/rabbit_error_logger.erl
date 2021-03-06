%% The contents of this file are subject to the Mozilla Public License
%% Version 1.1 (the "License"); you may not use this file except in
%% compliance with the License. You may obtain a copy of the License
%% at http://www.mozilla.org/MPL/
%%
%% Software distributed under the License is distributed on an "AS IS"
%% basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
%% the License for the specific language governing rights and
%% limitations under the License.
%%
%% The Original Code is RabbitMQ.
%%
%% The Initial Developer of the Original Code is GoPivotal, Inc.
%% Copyright (c) 2007-2017 Pivotal Software, Inc.  All rights reserved.
%%

-module(rabbit_error_logger).
-include("rabbit.hrl").
-include("rabbit_framing.hrl").

-define(LOG_EXCH_NAME, <<"amq.rabbitmq.log">>).

-behaviour(gen_event).

-export([start/0, stop/0]).

-export([init/1, terminate/2, code_change/3, handle_call/2, handle_event/2,
         handle_info/2]).


%%----------------------------------------------------------------------------

-spec start() -> 'ok'.
-spec stop() -> 'ok'.

%%----------------------------------------------------------------------------

start() ->
    {ok, DefaultVHost} = application:get_env(default_vhost),
    case error_logger:add_report_handler(?MODULE, [DefaultVHost]) of
        ok ->
            ok;
        {error, {no_such_vhost, DefaultVHost}} ->
            rabbit_log:warning("Default virtual host '~s' not found; "
                               "exchange '~s' disabled~n",
                               [DefaultVHost, ?LOG_EXCH_NAME]),
            ok
    end.

stop() ->
    case error_logger:delete_report_handler(rabbit_error_logger) of
        ok                        -> ok;
        {error, module_not_found} -> ok
    end.

%%----------------------------------------------------------------------------

init([DefaultVHost]) ->
    #exchange{} = rabbit_exchange:declare(
                    rabbit_misc:r(DefaultVHost, exchange, ?LOG_EXCH_NAME),
                    topic, true, false, true, [], ?INTERNAL_USER),
    {ok, #resource{virtual_host = DefaultVHost,
                   kind = exchange,
                   name = ?LOG_EXCH_NAME}}.

terminate(_Arg, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

handle_call(_Request, State) ->
    {ok, not_understood, State}.

handle_event(Event, State) ->
    safe_handle_event(fun handle_event0/2, Event, State).

handle_event0({Kind, _Gleader, {_Pid, Format, Data}}, State) ->
    ok = publish(Kind, Format, Data, State),
    {ok, State};
handle_event0(_Event, State) ->
    {ok, State}.

handle_info(_Info, State) ->
    {ok, State}.

publish(error, Format, Data, State) ->
    publish1(<<"error">>, Format, Data, State);
publish(warning_msg, Format, Data, State) ->
    publish1(<<"warning">>, Format, Data, State);
publish(info_msg, Format, Data, State) ->
    publish1(<<"info">>, Format, Data, State);
publish(_Other, _Format, _Data, _State) ->
    ok.

publish1(RoutingKey, Format, Data, LogExch) ->
    %% 0-9-1 says the timestamp is a "64 bit POSIX timestamp". That's
    %% second resolution, not millisecond.
    Timestamp = os:system_time(seconds),

    Args = [truncate:term(A, ?LOG_TRUNC) || A <- Data],
    Headers = [{<<"node">>, longstr, list_to_binary(atom_to_list(node()))}],
    case rabbit_basic:publish(LogExch, RoutingKey,
                              #'P_basic'{content_type = <<"text/plain">>,
                                         timestamp    = Timestamp,
                                         headers      = Headers},
                              list_to_binary(io_lib:format(Format, Args))) of
        {ok, _DeliveredQPids} -> ok;
        {error, not_found}    -> ok
    end.


safe_handle_event(HandleEvent, Event, State) ->
    try
        HandleEvent(Event, State)
    catch
        _:Error ->
            io:format(
              "Error in log handler~n====================~n"
              "Event: ~P~nError: ~P~nStack trace: ~p~n~n",
              [Event, 30, Error, 30, erlang:get_stacktrace()]),
            {ok, State}
    end.
