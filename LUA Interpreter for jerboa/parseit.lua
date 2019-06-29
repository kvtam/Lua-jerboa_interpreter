-- parseit.lua
--Kyle Tam
--CS 331
-- HW 4

local parseit = {} -- The module
local lexit = require "lexit"

-- Some code below Taken from rdparser4, credit to chappell

-- Variables

-- For lexer iteration
local iter          -- Iterator returned by lexer.lex
local state         -- State for above iterator (maybe not used)
local lexer_out_s   -- Return value #1 from above iterator
local lexer_out_c   -- Return value #2 from above iterator

-- For current lexeme
local lexstr = ""   -- String form of current lexeme
local lexcat = 0    -- Category of current lexeme:
                    --  one of categories below, or 0 for past the end


-- Symbolic Constants for AST
STMT_LIST    = 1
WRITE_STMT   = 2
FUNC_DEF     = 3
FUNC_CALL    = 4
IF_STMT      = 5
WHILE_STMT   = 6
RETURN_STMT  = 7
ASSN_STMT    = 8
CR_OUT       = 9
STRLIT_OUT   = 10
BIN_OP       = 11
UN_OP        = 12
NUMLIT_VAL   = 13
BOOLLIT_VAL  = 14
READNUM_CALL = 15
SIMPLE_VAR   = 16
ARRAY_VAR    = 17
-- Utility Functions

-- advance
-- Go to next lexeme and load it into lexstr, lexcat.
-- Should be called once before any parsing is done.
-- Function init must be called before this function is called.
local function advance()
    -- Advance the iterator
    lexer_out_s, lexer_out_c = iter(state, lexer_out_s)

    -- If we're not past the end, copy current lexeme into vars
    if lexer_out_s ~= nil then
        lexstr, lexcat = lexer_out_s, lexer_out_c
    else
        lexstr, lexcat = "", 0
    end
end

-- init
-- Initial call. Sets input for parsing functions.
local function init(prog)
    iter, state, lexer_out_s = lexit.lex(prog)
    advance()
end

-- atEnd
-- Return true if pos has reached end of input.
-- Function init must be called before this function is called.
local function atEnd()
    return lexcat == 0
end

-- matchString
-- Given string, see if current lexeme string form is equal to it. If
-- so, then advance to next lexeme & return true. If not, then do not
-- advance, return false.
-- Function init must be called before this function is called.
local function matchString(s)
    if lexstr == s then
        advance()
        return true
    else
        return false
    end
end

-- matchCat
-- Given lexeme category (integer), see if current lexeme category is
-- equal to it. If so, then advance to next lexeme & return true. If
-- not, then do not advance, return false.
-- Function init must be called before this function is called.
local function matchCat(c)
    if lexcat == c then
        advance()
        return true
    else
        return false
    end
end

-- "local" statements for parsing functions
local parse_program
local parse_stmt_list
local parse_statment
local parse_expr
local parse_term
local parse_factor
local parse_write_args
local parse_identifier
local parse_arith_expr
local parse_comp_expr

function parseit.parse(prog) -- should be the only function visable from outside of the file
	--Initialization
	init(prog)

	--Parsing results
	local good, ast = parse_program() --Parse start Symbol
	local done = atEnd() -- If at the end of input we're done

	--return
	return good, done, ast

end
-- function to parse the whole program
function parse_program()
	local good, ast

	good, ast = parse_stmt_list()
	return good, ast
end
-- function to parse statement list
function parse_stmt_list ()
	local good, ast, newast

	ast= {STMT_LIST}-- each statement
	while true do
		if  lexstr ~= "write"
		and lexstr ~= "if"
		and lexstr ~= "def"
		and lexstr ~= "func"
		and lexstr ~= "while"
		and lexstr ~= "return"
		and lexcat ~= lexit.ID then
			return true, ast
		end
		--must be a statement at this point in the code

		good, newast = parse_statment()
		if not good then
			return false, nil
		end

		table.insert(ast, newast) --insert into the ast
	end
	return true, ast
end
--function to parse each statement
function parse_statment()
	local good, ast, newast, savelex

	if matchString("write") then
		good, ast= parse_write_args() --either cr strlit or expression
		if not good then
			return false, nil
		end
		return true, ast

	elseif matchString("if") then
		local if_ast ={IF_STMT}

		good, ast = parse_expr()-- parse the if and its expression
		if not good then
			return false, nil
		end

		good, newast = parse_stmt_list()
		if not good then
			return false, nil
		end

		table.insert(if_ast,ast)
		table.insert(if_ast,newast)

		while matchString("elseif") do --parse elseif like an if statement
										--keep doing this loop until no longer elseif
			good, ast = parse_expr()
			if not good then
				return false, nil
			end
			good, newast = parse_stmt_list()
			if not good then
				return false, nil
			end

			table.insert(if_ast,ast)
			table.insert(if_ast,newast)
		end
		if matchString("else") then --else
			good, newast = parse_stmt_list()
			if not good then
				return false, nil
			end
			table.insert(if_ast,newast)
		end
		if matchString("end") then --reached the end
			return true, if_ast
		end

		return false, if_ast	--if there is no end

	elseif matchString("def")then

		savelex=lexstr
		if not matchCat(lexit.ID) or not matchString("(") or not matchString(")") then
			return false, nil
		end

		good, ast = parse_stmt_list()
		if not good then
			return false, nil
		end

		if matchString("end") then
			return true, {FUNC_DEF,savelex,ast}
		end

		return false, ast
	elseif matchString("while") then

		good, ast = parse_expr()
		if not good then
			return false, nil

		end

		good, newast = parse_stmt_list()
		if not good then
			return false, nil
		end

		if matchString("end") then
			return true, {WHILE_STMT,ast,newast}
		end

		return false, nil--{ast,newast}
	elseif matchString("return") then

		good, ast = parse_expr()
		if not good then
			return false, nil
		end

		return true, {RETURN_STMT,ast}
	else 						--it is a lvalue or a lefthand value an ID for example
		good, ast =parse_identifier()	--parse  the identifier
		if not good then 		--bad identifier
			return false, nil
		elseif ast[1]==FUNC_CALL  then
			return true, ast
		--elseif ast[1]==ARRAY_VAR then
			--return true, ast
		end

		if not matchString("=") then
			return false, nil
		end
		good, newast = parse_expr()
		if not good then
			return false, nil
		end
		return true, {ASSN_STMT,ast,newast}
	end
--TODO
end
--parse function for ids
function parse_identifier()
	local id, ast, good, tempast
	id= lexstr
	if matchCat(lexit.ID) then
		if matchString("(") then
			if matchString(")") then
				return true, {FUNC_CALL, id}
			end
			return false, nil
		elseif matchString("[") then
			good, ast = parse_expr()
			if not good then
				return false, nil
			end

			if matchString("]") then
				return true, {ARRAY_VAR,id,ast}
			end
			return false, nil

		else
			return true, {SIMPLE_VAR, id}
		end

	end
	return false, nil
end
function parse_write_args()
	local savelex, ast, good,newast
	ast= {WRITE_STMT}

	if not matchString("(") then
		return false, nil
	end
	repeat
	savelex=lexstr			--because matchcat trashes lexstr
	if matchString("cr") then --carrage ret
		ast[#ast+1] = {CR_OUT}
	elseif matchCat(lexit.STRLIT) then --string literal
		ast[#ast+1] = {STRLIT_OUT,savelex}
	else
		good, newast = parse_expr()  --expr
		if not good then
			return false, nil
		end
		ast[#ast+1]= newast
	end
	until not matchString(",")
	if matchString(")") then
		return true, ast
	else
		return false, nil
	end
end

function parse_expr()
	local good, ast, saveop, newast

	good, ast= parse_comp_expr()
	if not good then
		return false, nil
	end
	saveop=lexstr
	while matchString("&&") or matchString("||") do

		good , newast = parse_comp_expr()
		if not good then
		return false, nil
		end
		ast= { {BIN_OP, saveop}, ast, newast}
		saveop = lexstr
	end
	return true, ast

end
--function to parse comparisons
function parse_comp_expr()
	local good, ast, newast, saveop

	if matchString("!") then --case not

		good, ast = parse_comp_expr()
		if not good then
			return false, nil
		end

		return true, {{UN_OP, "!"}, ast}

	else --arithmetic

		good, ast = parse_arith_expr()
		if not good then
			return false, nil
		end
		saveop =  lexstr -- matchstring will mess up lexstr
			while true do
				if not matchString("==") and
				   not matchString("!=") and
				   not matchString("<=") and
				   not matchString(">=") and
				   not matchString("<") and
				   not matchString(">") then--check for operators
					break
				end

				good, newast = parse_arith_expr()
				if not good then
					return false, nil
				end

				ast={{BIN_OP,saveop},ast,newast}
				saveop =  lexstr -- matchstring will mess up lexstr
			end
			return true,ast
	end
end
--parse arithmetic expressions
function parse_arith_expr()
	local good, ast, newast, saveop

	good, ast = parse_term()
	if not good then

		return false, nil
	end

	while true do
		saveop= lexstr
		if not matchString("+") and
		   not matchString("-") then
			break
		end

		good ,newast = parse_term()
		if not good then
			return false, nil
		end

		ast = {{BIN_OP,saveop},ast,newast}

	end

	return true, ast
end
--parse terms
function parse_term()
	local good, ast, newast, saveop

	good, ast = parse_factor()
	if not good then

		return false, nil
	end

	while true do --look for operators
		saveop= lexstr
		if not matchString("/") and
			not matchString("*") and
			not matchString("%") then
			break
		end
		good, newast = parse_factor()
		if not good then
			return false, nil
		end

		ast ={{ BIN_OP,saveop},ast,newast}
	end
	return true, ast
end

--parse each individual factor
function parse_factor()
	local savelex, good, ast, newast
	savelex = lexstr

	if matchString("(") then --match parentheses
		good, ast= parse_expr()
		if not good then
			return false, nil
		end

		if not matchString(")") then
			return false, nil
		end
		return true, ast

	elseif matchString("-") or matchString("+") then --match +/- operators
		local saveop= savelex
		good, newast= parse_factor()
		if not good then
			return false, nil
		end
		return true, {{UN_OP,saveop},newast}
	elseif matchCat(lexit.NUMLIT) then --numerical lits
		return true, {NUMLIT_VAL,savelex}
	elseif matchString("true") or matchString("false") then --bools
		return true, {BOOLLIT_VAL, savelex}
	elseif matchString("readnum") then

			if matchString("(") then
				if matchString(")") then
				return true, {READNUM_CALL}
				end
			end
		return false, nil
	else -- identifier

		good, ast = parse_identifier()
		if not good then
		return false, nil
		end
		return true, ast

	end


	return false, nil
end

return parseit
