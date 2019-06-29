--Kyle Tam
-- Some things taken from Glenn Chappell's lexer.lua
--Lexit.lua
--CS331
local lexit={}

lexit.KEY    = 1
lexit.ID     = 2
lexit.NUMLIT = 3
lexit.STRLIT = 4
lexit.OP     = 5
lexit.PUNCT  = 6
lexit.MAL    = 7

-- *********************************************************************
-- Kind-of-Character Functions
-- *********************************************************************

-- All functions return false when given a string whose length is not
-- exactly 1.


-- isLetter
-- Returns true if string c is a letter character, false otherwise.
local function isLetter(c)
    if c:len() ~= 1 then
        return false
    elseif c >= "A" and c <= "Z" then
        return true
    elseif c >= "a" and c <= "z" then
        return true
    else
        return false
    end
end

local function isquote(c)
	if c:len() ~=1 then
		return false
	elseif c == "\""or"\'" then
		return true
	end
end


-- isDigit
-- Returns true if string c is a digit character, false otherwise.
local function isDigit(c)
    if c:len() ~= 1 then
        return false
    elseif c >= "0" and c <= "9" then
        return true
    else
        return false
    end
end


-- isWhitespace
-- Returns true if string c is a whitespace character, false otherwise.
local function isWhitespace(c)
    if c:len() ~= 1 then
        return false
    elseif c == " " or c == "\t" or c == "\n" or c == "\r"
      or c == "\f" then
        return true
    else
        return false
    end
end


-- isIllegal
-- Returns true if string c is an illegal character, false otherwise.
local function isIllegal(c)
    if c:len() ~= 1 then
        return false
    elseif isWhitespace(c) then
        return false
    elseif c >= " " and c <= "~" then
        return false
    else
        return true
    end
end

lexit.catnames = {
    "Keyword",-- cr, def, else, elseif, end, false, if, readnum, return, true, while, write
    "Identifier",--letter or underscore followed by letters or digits
    "NumericLiteral",-- +/- followed by numbers or exponent
	"StringLiteral", -- 'something' or "something else"
    "Operator", --  &&    ||    !    ==    !=    <    <=    >    >=    +    -    *    /    %    [    ]    =
    "Punctuation", -- not whitespace, ascii 32-126
    "Malformed"
}
function lexit.lex(str)
	local pos       -- Index of next character in program
	local state     -- Current state for our state machine
    local ch        -- Current character
    local lexstr    -- The lexeme, so far
    local category  -- Category of lexeme, set when state set to DONE
	local handlers  -- Dispatch table; value created later
	local previousCAT
	local previousLEX

	local DONE   = 0
    local START  = 1
    local LETTER = 2
    local DIGIT  = 3
    local PLUS   = 4
    local MINUS  = 5
    local STAR   = 6
	local SINGLE = 7
	local AMP    = 8
	local OR     = 9
	local EQUAL  = 10
	local DOUBLE = 11
	local EXP    = 12
	 -- currChar --ported from Chappell
    -- Return the current character, at index pos in program. Return
    -- value is a single-character string, or the empty string if pos is
    -- past the end.
	local function currChar()
        return str:sub(pos, pos)
    end
	-- nextChar --ported from Chappell
    -- Return the next character, at index pos+1 in program. Return
    -- value is a single-character string, or the empty string if pos+1
    -- is past the end.
	local function nextChar()
        return str:sub(pos+1, pos+1)
    end
	  -- drop1 ported from Chappell
    -- Move pos to the next character.
	local function lookTwo()
		return str:sub(pos+2,pos+2)
	end
    local function drop1()
        pos = pos+1
    end
	-- add1 ported from Chappell
    -- Add the current character to the lexeme, moving pos to the next
    -- character.
	local function add1()
        lexstr = lexstr .. currChar()
        drop1()
	end
		--ported from Chappell
        -- Skip whitespace and comments, moving pos to the beginning of
    -- the next lexeme, or to program:len()+1.
	local function maxMunch()
		return previousCAT==lexit.ID
			or previousCAT==lexit.NUMLIT
			or previousLEX==")"
			or previousLEX=="]"
			or previousLEX=="true"
			or previousLEX=="false"
	end
    local function skipWhitespace()
        while true do      -- In whitespace
            while isWhitespace(currChar()) do
                drop1()
            end

            if currChar() ~= "#" then  -- Comment?
                break
            end
            drop1()

            while true do  -- In comment
                if currChar() == "\n"  then
                    drop1()
					break
                elseif currChar() == "" then  -- End of input?
                   return
                end
                drop1()
            end
        end
    end
	local function handle_DONE()
        io.write("ERROR: 'DONE' state should not be handled\n")
        assert(0)
    end

    local function handle_START()
        if isIllegal(ch) then
            add1()
            state = DONE
            category = lexit.MAL
        elseif isLetter(ch) or ch == "_" then
            add1()
            state = LETTER
		elseif ch=="\'" then
			add1()
			state = SINGLE
		elseif ch=="\"" then
			add1()
			state= DOUBLE
        elseif isDigit(ch) then
            add1()
            state = DIGIT
        elseif ch == "+" then
            add1()
            state = PLUS
		elseif ch == "&" then
            add1()
            state = AMP
		elseif ch == "|" then
            add1()
            state = OR
		elseif ch == ">"
			or ch == "<"
			or ch =="="
			or ch == "!"then
            add1()
            state = EQUAL
        elseif ch == "-" then
            add1()
            state = MINUS
        elseif ch == "*"
			or ch == "/"
			or ch == "%"
			or ch == "["
			or ch == "]"
			then
			add1()
            state = DONE
			category =lexit.OP
        else
            add1()
            state = DONE
            category = lexit.PUNCT
        end
    end
	local function handle_LETTER()
        if isLetter(ch) or isDigit(ch) or ch == "_"  then
            add1()
        else
            state = DONE
            if lexstr == "cr"
				or lexstr == "def"
				or lexstr == "elseif"
				or lexstr == "end"
				or lexstr == "false"
				or lexstr == "if"
				or lexstr == "readnum"
				or lexstr == "return"
				or lexstr == "true"
				or lexstr == "while"
				or lexstr == "write"
				or lexstr == "else" then

                category = lexit.KEY

			else
                category = lexit.ID
            end
        end
    end
	local function handle_DOUBLE()

			if ch=="\n"or ch=="" then
				category=lexit.MAL
				state = DONE

			elseif ch== "\"" then
				state=DONE
				category=lexit.STRLIT
			end
			add1()
	end
	local function handle_SINGLE()

			if ch=="\n"or ch=="" then
				category=lexit.MAL
				state = DONE

			elseif ch== "\'" then
				state=DONE
				category=lexit.STRLIT
			end
			add1()
	end
	local function handle_DIGIT()
        if isDigit(ch) then
            add1()
		elseif ch=='e' or ch=='E' then --probs wrong
			if isDigit(nextChar()) or (nextChar()=="+" and isDigit(lookTwo())) then
			add1()
			add1()
			state=EXP
			else
			state= DONE
			category=lexit.NUMLIT
			end
        else
            state = DONE
            category = lexit.NUMLIT
        end
    end
	local function handle_EXP()
		if  isDigit(ch) then
		add1()
		else
		state= DONE
		category=lexit.NUMLIT
		end
	end
	local function handle_AMP()
		if  ch == "&" then
			add1()
			state = DONE
			category = lexit.OP
		else

			state=DONE
			category =lexit.PUNCT
		end
	end
	local function handle_OR()
		if  ch == "|" then
			add1()
			state = DONE
			category = lexit.OP
		else

			state=DONE
			category =lexit.PUNCT
		end
	end
	local function handle_EQUAL()
		if  ch == "=" then
			add1()
		end

			state=DONE
			category =lexit.OP

	end
    local function handle_PLUS()
	if isDigit(ch) and not maxMunch() then
            add1()
            state = DIGIT
        else
            state = DONE
            category = lexit.OP
        end
    end

    local function handle_MINUS()
		if isDigit(ch) and not maxMunch() then
            add1()
            state = DIGIT
        else
            state = DONE
            category = lexit.OP
        end
	end
	local function handle_STAR()  -- Handle * or / or %
		add1()
		state = DONE
		category = lexit.OP

    end
	    -- ***** Table of State-Handler Functions *****

    handlers = {
        [DONE]=handle_DONE,
        [START]=handle_START,
        [LETTER]=handle_LETTER,
        [DIGIT]=handle_DIGIT,
        [PLUS]=handle_PLUS,
        [MINUS]=handle_MINUS,
		[STAR]=handle_STAR,
		[SINGLE]=handle_SINGLE,
		[AMP] =handle_AMP,
		[OR] = handle_OR,
		[EQUAL]=handle_EQUAL,
		[DOUBLE]=handle_DOUBLE,
		[EXP]=handle_EXP,
    }

    -- ***** Iterator Function *****

    -- getLexeme
    -- Called each time through the for-in loop.
    -- Returns a pair: lexeme-string (string) and category (int), or
    -- nil, nil if no more lexemes.
    local function getLexeme(dummy1, dummy2)
        if pos > str:len() then
            return nil, nil
        end
        lexstr = ""
        state = START
        while state ~= DONE do
            ch = currChar()
            handlers[state]()
        end

        skipWhitespace()
		previousCAT, previousLEX=category,lexstr
        return lexstr, category
    end

    -- ***** Body of Function lex *****

    -- Initialize & return the iterator function
    pos = 1
    skipWhitespace()
    return getLexeme, nil, nil
end

return lexit
