%%
%% %CopyrightBegin%
%%
%% Copyright Ericsson AB 1999-2010. All Rights Reserved.
%%
%% The contents of this file are subject to the Erlang Public License,
%% Version 1.1, (the "License"); you may not use this file except in
%% compliance with the License. You should have received a copy of the
%% Erlang Public License along with this software. If not, it can be
%% retrieved online at http://www.erlang.org/.
%%
%% Software distributed under the License is distributed on an "AS IS"
%% basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
%% the License for the specific language governing rights and limitations
%% under the License.
%%
%% %CopyrightEnd%
%%

%%
-module(fun_SUITE).

-export([all/1,
	 init_per_testcase/2,end_per_testcase/2,
	 init_all/1,finish_all/1,
	 good_call/1,bad_apply/1,bad_fun_call/1,badarity/1,
	 ext_badarity/1,otp_6061/1]).
-export([nothing/0]).

-include("test_server.hrl").

all(suite) ->
    [{conf,init_all,cases(),finish_all}].

cases() ->
    [good_call,bad_apply,bad_fun_call,badarity,ext_badarity,otp_6061].

init_per_testcase(_Case, Config) ->
    test_lib:interpret(?MODULE),
    Dog = test_server:timetrap(?t:minutes(1)),
    [{watchdog,Dog}|Config].

end_per_testcase(_Case, Config) ->
    Dog = ?config(watchdog, Config),
    ?t:timetrap_cancel(Dog),
    ok.

init_all(Config) when is_list(Config) ->
    ?line test_lib:interpret(?MODULE),
    ?line true = lists:member(?MODULE, int:interpreted()),
    ok.

finish_all(Config) when is_list(Config) ->
    ok.

good_call(Config) when is_list(Config) ->
    ?line F = fun() -> ok end,
    ?line ok = F(),
    ?line FF = fun ?MODULE:nothing/0,
    ?line ok = FF(),
    ok.

bad_apply(doc) ->
    "Test that the correct EXIT code is returned for all types of bad funs.";
bad_apply(suite) -> [];
bad_apply(Config) when is_list(Config) ->
    ?line bad_apply_fc(42, [0]),
    ?line bad_apply_fc(xx, [1]),
    ?line bad_apply_fc({}, [2]),
    ?line bad_apply_fc({1}, [3]),
    ?line bad_apply_fc({1,2,3}, [4]),
    ?line bad_apply_fc({1,2,3}, [5]),
    ?line bad_apply_fc({1,2,3,4}, [6]),
    ?line bad_apply_fc({1,2,3,4,5,6}, [7]),
    ?line bad_apply_fc({1,2,3,4,5}, [8]),
    ?line bad_apply_badarg({1,2}, [9]),
    ok.

bad_apply_fc(Fun, Args) ->
    Res = (catch apply(Fun, Args)),
    erlang:garbage_collect(),
    erlang:yield(),
    case Res of
	{'EXIT',{{badfun,Fun},_Where}} ->
	    ok = io:format("apply(~p, ~p) -> ~p\n", [Fun,Args,Res]);
	Other ->
	    ok = io:format("apply(~p, ~p) -> ~p\n", [Fun,Args,Res]),
	    ?t:fail({bad_result,Other})
    end.

bad_apply_badarg(Fun, Args) ->
    Res = (catch apply(Fun, Args)),
    erlang:garbage_collect(),
    erlang:yield(),
    case Res of
	{'EXIT',{{badfun,Fun},_Where}} ->
	    ok = io:format("apply(~p, ~p) -> ~p\n", [Fun,Args,Res]);
	Other ->
	    ok = io:format("apply(~p, ~p) -> ~p\n", [Fun,Args,Res]),
	    ?t:fail({bad_result, Other})
    end.

bad_fun_call(doc) ->
    "Try directly calling bad funs.";
bad_fun_call(suite) -> [];
bad_fun_call(Config) when is_list(Config) ->
    ?line bad_call_fc(42),
    ?line bad_call_fc(xx),
    ?line bad_call_fc({}),
    ?line bad_call_fc({1}),
    ?line bad_call_fc({1,2,3}),
    ?line bad_call_fc({1,2,3}),
    ?line bad_call_fc({1,2,3,4}),
    ?line bad_call_fc({1,2,3,4,5,6}),
    ?line bad_call_fc({1,2,3,4,5}),
    ?line bad_call_fc({1,2}),
    ok.

bad_call_fc(Fun) ->
    Args = [some,stupid,args],
    Res = (catch Fun(Args)),
    case Res of
	{'EXIT',{{badfun,Fun},_Where}} ->
	    ok = io:format("~p(~p) -> ~p\n", [Fun,Args,Res]);
	Other ->
	    ok = io:format("~p(~p) -> ~p\n", [Fun,Args,Res]),
	    ?t:fail({bad_result,Other})
    end.

%% Call and apply valid external funs with wrong number of arguments.

badarity(Config) when is_list(Config) ->
    ?line Fun = fun() -> ok end,
    ?line Stupid = {stupid,arguments},
    ?line Args = [some,{stupid,arguments},here],

    %% Simple call.

    ?line Res = (catch Fun(some, Stupid, here)),
    erlang:garbage_collect(),
    erlang:yield(),
    case Res of
	{'EXIT',{{badarity,{Fun,Args}},[_|_]}} ->
	    ?line ok = io:format("~p(~p) -> ~p\n", [Fun,Args,Res]);
	_ ->
	    ?line ok = io:format("~p(~p) -> ~p\n", [Fun,Args,Res]),
	    ?line ?t:fail({bad_result,Res})
    end,

    %% Apply.

    ?line Res2 = (catch apply(Fun, Args)),
    erlang:garbage_collect(),
    erlang:yield(),
    case Res2 of
	{'EXIT',{{badarity,{Fun,Args}},[_|_]}} ->
	    ?line ok = io:format("apply(~p, ~p) -> ~p\n", [Fun,Args,Res2]);
	_ ->
	    ?line ok = io:format("apply(~p, ~p) -> ~p\n", [Fun,Args,Res2]),
	    ?line ?t:fail({bad_result,Res2})
    end,
    ok.

%% Call and apply valid external funs with wrong number of arguments.

ext_badarity(Config) when is_list(Config) ->
    ?line Fun = fun ?MODULE:nothing/0,
    ?line Stupid = {stupid,arguments},
    ?line Args = [some,{stupid,arguments},here],

    %% Simple call.

    ?line Res = (catch Fun(some, Stupid, here)),
    erlang:garbage_collect(),
    erlang:yield(),
    case Res of
	{'EXIT',{{badarity,{Fun,Args}},_}} ->
	    ?line ok = io:format("~p(~p) -> ~p\n", [Fun,Args,Res]);
	_ ->
	    ?line ok = io:format("~p(~p) -> ~p\n", [Fun,Args,Res]),
	    ?line ?t:fail({bad_result,Res})
    end,

    %% Apply.

    ?line Res2 = (catch apply(Fun, Args)),
    erlang:garbage_collect(),
    erlang:yield(),
    case Res2 of
	{'EXIT',{{badarity,{Fun,Args}},_}} ->
	    ?line ok = io:format("apply(~p, ~p) -> ~p\n", [Fun,Args,Res2]);
	_ ->
	    ?line ok = io:format("apply(~p, ~p) -> ~p\n", [Fun,Args,Res2]),
	    ?line ?t:fail({bad_result,Res2})
    end,
    ok.

nothing() ->
    ok.

otp_6061(suite) ->
    [];
otp_6061(doc) ->
    ["Test handling of fun expression referring to uninterpreted code"];
otp_6061(Config) when is_list(Config) ->

    ?line OrigFlag = process_flag(trap_exit, true),

    ?line Self = self(),
    ?line Pid = spawn_link(fun() -> test_otp_6061(Self) end),

    receive
	working ->
	    ?line ok;
	not_working ->
	    ?line ?t:fail(not_working);
	{'EXIT', Pid, Reason} ->
	    ?line ?t:fail({crash, Reason})
    after
	5000 ->
	    ?line ?t:fail(timeout)
    end,

    ?line process_flag(trap_exit, OrigFlag),

    ok.

test_otp_6061(Starter) ->
    Passes = [2],
    PassesF = [fun() -> Starter ! not_working end,
	       fun() -> Starter ! working end,
	       fun() -> Starter ! not_working end],
    lists:foreach(fun(P)->(lists:nth(P,PassesF))() end,Passes).
