-- Kyle Tam
--interpit.lua  INCOMPLETE
-- Skeleton code provided  by: Glenn G. Chappell
-- 3 Apr 2019
--
-- For CS F331 / CSCE A331 Spring 2019
-- Interpret AST from parseit.parse
-- For Assignment 6, Exercise B


-- *******************************************************************
-- * To run a Jerboa program, use jerboa.lua (which uses this file). *
-- *******************************************************************


local interpit = {}  -- Our module


-- ***** Variables *****


-- Symbolic Constants for AST

local STMT_LIST    = 1
local WRITE_STMT   = 2
local FUNC_DEF     = 3
local FUNC_CALL    = 4
local IF_STMT      = 5
local WHILE_STMT   = 6
local RETURN_STMT  = 7
local ASSN_STMT    = 8
local CR_OUT       = 9
local STRLIT_OUT   = 10
local BIN_OP       = 11
local UN_OP        = 12
local NUMLIT_VAL   = 13
local BOOLLIT_VAL  = 14
local READNUM_CALL = 15
local SIMPLE_VAR   = 16
local ARRAY_VAR    = 17



-- ***** Utility Functions *****


-- numToInt
-- Given a number, return the number rounded toward zero.
local function numToInt(n)
    assert(type(n) == "number")

    if n >= 0 then
        return math.floor(n)
    else
        return math.ceil(n)
    end
end


-- strToNum
-- Given a string, attempt to interpret it as an integer. If this
-- succeeds, return the integer. Otherwise, return 0.
local function strToNum(s)
    assert(type(s) == "string")

    -- Try to do string -> number conversion; make protected call
    -- (pcall), so we can handle errors.
    local success, value = pcall(function() return 0+s end)

    -- Return integer value, or 0 on error.
    if success then
        return numToInt(value)
    else
        return 0
    end
end


-- numToStr
-- Given a number, return its string form.
local function numToStr(n)
    assert(type(n) == "number")

    return ""..n
end


-- boolToInt
-- Given a boolean, return 1 if it is true, 0 if it is false.
local function boolToInt(b)
    assert(type(b) == "boolean")

    if b then
        return 1
    else
        return 0
    end
end

local function strToBool(str)
		assert(type(str)=="string")
		return str== "true"
end

-- astToStr
-- Given an AST, produce a string holding the AST in (roughly) Lua form,
-- with numbers replaced by names of symbolic constants used in parseit.
-- A table is assumed to represent an array.
-- See the Assignment 4 description for the AST Specification.
--
-- THIS FUNCTION IS INTENDED FOR USE IN DEBUGGING ONLY!
-- IT SHOULD NOT BE CALLED IN THE FINAL VERSION OF THE CODE.
function astToStr(x)
    local symbolNames = {
        "STMT_LIST", "WRITE_STMT", "FUNC_DEF", "FUNC_CALL", "IF_STMT",
        "WHILE_STMT", "RETURN_STMT", "ASSN_STMT", "CR_OUT",
        "STRLIT_OUT", "BIN_OP", "UN_OP", "NUMLIT_VAL", "BOOLLIT_VAL",
        "READNUM_CALL", "SIMPLE_VAR", "ARRAY_VAR"
    }
    if type(x) == "number" then
        local name = symbolNames[x]
        if name == nil then
            return "<Unknown numerical constant: "..x..">"
        else
            return name
        end
    elseif type(x) == "string" then
        return '"'..x..'"'
    elseif type(x) == "boolean" then
        if x then
            return "true"
        else
            return "false"
        end
    elseif type(x) == "table" then
        local first = true
        local result = "{"
        for k = 1, #x do
            if not first then
                result = result .. ","
            end
            result = result .. astToStr(x[k])
            first = false
        end
        result = result .. "}"
        return result
    elseif type(x) == "nil" then
        return "nil"
    else
        return "<"..type(x)..">"
    end
end


-- ***** Primary Function for Client Code *****


-- interp
-- Interpreter, given AST returned by parseit.parse.
-- Parameters:
--   ast     - AST constructed by parseit.parse
--   state   - Table holding Jerboa variables & functions
--             - AST for function xyz is in state.f["xyz"]
--             - Value of simple variable xyz is in state.v["xyz"]
--             - Value of array item xyz[42] is in state.a["xyz"][42]
--   incall  - Function to call for line input
--             - incall() inputs line, returns string with no newline
--   outcall - Function to call for string output
--             - outcall(str) outputs str with no added newline
--             - To print a newline, do outcall("\n")
-- Return Value:
--   state, updated with changed variable values
function interpit.interp(ast, state, incall, outcall)
    -- Each local interpretation function is given the AST for the
    -- portion of the code it is interpreting. The function-wide
    -- versions of state, incall, and outcall may be used. The
    -- function-wide version of state may be modified as appropriate.


    -- Forward declare local functions
    local interp_stmt_list
    local interp_stmt
    local eval_expr

--interpret the list of statements
    function interp_stmt_list(ast)
        assert(ast[1] == STMT_LIST,
               "stmt list AST must start w/ STMT_LIST")
        for i = 2, #ast do
            interp_stmt(ast[i])
        end
    end

--interpret the statements
    function interp_stmt(ast)
        if (ast[1] == WRITE_STMT) then
            for i = 2, #ast do
                assert(type(ast[i]) == "table",
                       "print arg must be table")
                if ast[i][1] == CR_OUT then
                    outcall("\n")
                elseif ast[i][1] == STRLIT_OUT then
                    local str = ast[i][2]
                    outcall(str:sub(2,str:len()-1))
                else
                    local value = eval_expr(ast[i])
                    outcall(numToStr(value))
                end
            end
        elseif (ast[1] == FUNC_DEF) then
            local name = ast[2]
            local body = ast[3]
            state.f[name] = body
        elseif (ast[1] == FUNC_CALL) then
            local name = ast[2]
            local body = state.f[name]
            if body == nil then
                body = { STMT_LIST }  -- Default AST
            end
            interp_stmt_list(body)
        elseif (ast[1] == IF_STMT) then
			interp_if(ast)
        elseif (ast[1] == WHILE_STMT) then
			interp_while(ast)
        elseif (ast[1] == RETURN_STMT) then
			interp_return(ast)
        elseif (ast[1] == ASSN_STMT) then
			rhs=eval_expr(ast[3])
			interp_lval(ast[2],rhs)
        else
            assert(false, "Illegal statement")
        end
    end

--function to evaluate the expression
    function eval_expr(ast)
		local value
        if ast[1] == NUMLIT_VAL then
             value = strToNum(ast[2])

        elseif ast[1] == READNUM_CALL then
             value = strToNum(incall())

		elseif ast[1] == SIMPLE_VAR then
			value=state.v[ast[2]]

		elseif ast[1] == ARRAY_VAR then
			if	state.a[ast[2]] ~= nil then
				value= state.a[ast[2]][eval_expr(ast[3])]
			else
				value =0
			end

		elseif ast[1] == BOOLLIT_VAL then
			value=boolToInt(strToBool(ast[2]))

		elseif ast[1] == FUNC_CALL then
			interp_stmt(ast)
			value=state.v["return"]

        else --operator
            value=interp_operator(ast)
        end
		if value==nil then
			return 0
		else
			return value
		end
    end
--interpret the Lhs of equality/lvalue
function interp_lval(ast,rhs)
	local lval

	if ast[1]==SIMPLE_VAR then
		lval=ast[2]
		state.v[lval]= numToInt(rhs)
	elseif ast[1]== ARRAY_VAR then
			lval=ast[2]
		if state.a[lval]==nil then
			state.a[lval]= {}
		end
		state.a[lval][eval_expr(ast[3])]=rhs
	end
end
--interprest if statement, either if or else
function interp_if(ast)
	local finished=false
	local elseposition=0

	for i=2, #ast-1, 2 do
		if eval_expr(ast[i]) ~= 0 and not finished then
			interp_stmt_list(ast[i+1])
			finished=true
		end
		elseposition= i
	end
	if ast[elseposition+2]~= nil and not finished then
		interp_stmt_list(ast[elseposition+2])
	end
end

function interp_while(ast)
	while eval_expr(ast[2]) ~= 0 do
		interp_stmt_list(ast[3])
	end
end
--interpret operator
function interp_operator(ast)
	local value, operand, rhs,lhs

	if ast[1][1] == UN_OP then
		operand = eval_expr(ast[2])

		value= interp_un_op(ast[1], operand)
	elseif ast[1][1] == BIN_OP then
		lhs =eval_expr(ast[2])
		rhs =eval_expr(ast[3])
		value = interp_bin_op(ast[1],lhs,rhs)

	end
	return value
end
--interpret unary operators
function interp_un_op(ast, operand)
	local value

	if ast[2] == "+"then
		value= operand
	elseif ast[2] =="-" then
		value = -(operand)
	else
		if operand == 0 then
			value = 1
		else
			value = 0
		end
	end
	return value
end
--interpret binary operators
function interp_bin_op(ast,lhs,rhs)
	local operator = ast[2]
	local isEq = (lhs==rhs)
	local value

	if operator == "+" then
		value = lhs+ rhs
	elseif operator == "-" then
		value = lhs-rhs
	elseif operator == "*" then
		value = lhs*rhs
	elseif operator =="/" then
		if rhs==0 then
			value= 0
		else
			value= numToInt(lhs/rhs)
		end
	elseif operator== "%" then
		if rhs== 0 then
			value=0
		else
			value = numToInt(lhs % rhs)
		end
	elseif operator == "==" then
		value = boolToInt(lhs==rhs)
	elseif operator == "!=" then
		value = boolToInt(lhs~=rhs)
	elseif operator == "<=" then
		value = boolToInt(lhs <= rhs)
	elseif operator == ">=" then
		value = boolToInt(lhs >= rhs)
	elseif operator == ">" then
		value = boolToInt(lhs > rhs)
	elseif operator == "<" then
		value = boolToInt(lhs <rhs)
	elseif operator== "&&" then
		if lhs==0 or rhs==0 then
			value =0
		else
			value= boolToInt(isEq)
		end
	elseif operator =="||" then
		if   lhs==0 and  rhs==0 then
			value = 0
		elseif lhs~=0 or rhs~=0 then
			value=1
		elseif isEq then
			value= boolToInt(isEq)

		end
	end
	return value
end
function interp_return(ast)
	state.v["return"]=eval_expr(ast[2])
end
    -- Body of function interp
    interp_stmt_list(ast)
    return state
end


-- ***** Module Export *****


return interpit

