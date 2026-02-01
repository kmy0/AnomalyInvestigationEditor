---@class (exact) SearchBase
---@field data table<string, table<string | number, table<any, boolean>>> --inverted index
---@field all_items table<any, boolean>
---@field all_text table<string, table<any, boolean>>
---@field enum SearchBaseEnum

---@class (exact) Token
---@field type TokenType
---@field value string

---@class (exact) Ast
---@field type AstType

---@class (exact) AstOrAnd : Ast
---@field left Ast
---@field right Ast

---@class (exact) AstMatch : Ast
---@field key string

---@class (exact) AstText : Ast
---@field value string

---@class (exact) AstRange : AstMatch
---@field min number
---@field max number

---@class (exact) AstNot : Ast
---@field expr Ast

---@class (exact) AstComparison : AstMatch
---@field operator fun(a: number, b: number): boolean
---@field value number

---@class (exact) AstMatchText : AstMatch, AstText

---@class (exact) SearchBaseEnum
---@field token_type TokenType.*
---@field ast_type AstType.*

local util = require("AnomalyInvestigationEditor.util.misc.util")
local util_table = require("AnomalyInvestigationEditor.util.misc.table")

---@class SearchBase
local this = {
    ---@diagnostic disable-next-line: missing-fields
    enum = {},
}
---@diagnostic disable-next-line: inject-field
this.__index = this

---@enum TokenType
this.enum.token_type = { ---@class TokenType.*
    LPAREN = 1,
    RPAREN = 2,
    AND = 3,
    OR = 4,
    TERM = 5,
    NOT = 7,
}
---@enum AstType
this.enum.ast_type = { ---@class AstType.*
    AND = 1,
    OR = 2,
    COMPARISON = 3,
    RANGE = 4,
    MATCH = 5,
    TEXT = 6,
    NOT = 7,
}

local operator = {
    ["!="] = function(x, y)
        return x ~= y
    end,
    [">="] = function(x, y)
        return x >= y
    end,
    ["<="] = function(x, y)
        return x <= y
    end,
    ["<"] = function(x, y)
        return x < y
    end,
    [">"] = function(x, y)
        return x > y
    end,
    ["="] = function(x, y)
        return x == y
    end,
}

---@param data table<string, table<any, any>>
---@return SearchBase
function this:new(data)
    local o = {
        data = data,
        all_items = {},
        all_text = {},
    }
    setmetatable(o, self)
    ---@cast o SearchBase

    for _, values in pairs(o.data) do
        for key, matches in pairs(values) do
            for m in pairs(matches) do
                o.all_items[m] = true

                if type(key) == "string" then
                    util_table.set_nested_value(o.all_text, { key, m }, true)
                end
            end
        end
    end
    return o
end

---@protected
---@param query string
---@return Token[]
function this:_tokenize(query)
    ---@type Token[]
    local ret = {}
    local i = 1
    local len = #query
    local e = self.enum.token_type

    if
        not query:find("[%(%)]")
        and not query:find(":")
        and not query:find('"')
        and not query:match("%f[%a](AND|OR)%f[%A]")
    then
        return {
            { type = e.TERM, value = query:lower() },
        }
    end

    while i <= len do
        local char = query:sub(i, i)

        if char:match("%s") then
            i = i + 1
        elseif char == "(" then
            table.insert(ret, { type = e.LPAREN, value = "(" })
            i = i + 1
        elseif char == ")" then
            table.insert(ret, { type = e.RPAREN, value = ")" })
            i = i + 1
        else
            local j = i
            local quote = 0
            while j <= len do
                if query:sub(j, j) == '"' then
                    quote = quote + 1
                end

                if query:sub(j, j):match("[%s()]") and quote % 2 == 0 then
                    break
                end

                j = j + 1
            end

            if quote % 2 ~= 0 then
                error("Unclosed quote")
            end

            local term = query:sub(i, j - 1)
            local upper = term:upper()
            if upper == "AND" then
                table.insert(ret, { type = e.AND, value = "AND" })
            elseif upper == "OR" then
                table.insert(ret, { type = e.OR, value = "OR" })
            elseif upper == "NOT" then
                table.insert(ret, { type = e.NOT, value = "NOT" })
            else
                table.insert(ret, { type = e.TERM, value = term:gsub('"', "") })
            end
            i = j
        end
    end

    return ret
end

---@param term string
---@return Ast
function this:_parse_term(term)
    local e = self.enum.ast_type
    local colon_pos = term:find(":")
    if not colon_pos then
        return { type = e.TEXT, value = term:lower() }
    end

    local key = term:sub(1, colon_pos - 1):lower()
    local str = term:sub(colon_pos + 1):lower()

    if not self.data[key] then
        error("Unexpected key: " .. key)
    end

    local range_start, range_end = str:match("^(%-?[%d%.]+)%-(%-?[%d%.]+)$")
    if range_start and range_end then
        return {
            type = e.RANGE,
            key = key,
            min = tonumber(range_start),
            max = tonumber(range_end),
        }
    end

    local op = operator["="]
    local value = str

    if str:sub(1, 2) == "!=" then
        op = operator["!="]
        value = str:sub(3)
    elseif str:sub(1, 2) == ">=" then
        op = operator[">="]
        value = str:sub(3)
    elseif str:sub(1, 2) == "<=" then
        op = operator["<="]
        value = str:sub(3)
    elseif str:sub(1, 1) == ">" then
        op = operator[">"]
        value = str:sub(2)
    elseif str:sub(1, 1) == "<" then
        op = operator["<"]
        value = str:sub(2)
    elseif str:sub(1, 1) == "=" then
        op = operator["="]
        value = str:sub(2)
    end

    local num = tonumber(value)
    if num then
        return {
            type = e.COMPARISON,
            key = key,
            operator = op,
            value = num,
        }
    end

    return {
        type = e.MATCH,
        key = key,
        value = value,
    }
end

---@protected
---@param tokens Token[]
---@param pos integer
---@return Ast, integer
function this:_parse_primary(tokens, pos)
    if pos > #tokens then
        error("Unexpected end of expression")
    end

    local e = self.enum.token_type
    local token = tokens[pos]

    if token.type == e.NOT then
        local expr, new_pos = self:_parse_primary(tokens, pos + 1)
        return { type = self.enum.ast_type.NOT, expr = expr }, new_pos
    end

    if token.type == e.LPAREN then
        local expr, new_pos = self:_parse_expression(tokens, pos + 1)
        if new_pos > #tokens or tokens[new_pos].type ~= e.RPAREN then
            error("Missing closing parenthesis")
        end
        return expr, new_pos + 1
    end

    if token.type == e.TERM then
        return self:_parse_term(token.value), pos + 1
    end

    error("Unexpected token: " .. token.type)
end

---@protected
---@param tokens Token[]
---@param pos integer
---@return Ast, integer
function this:_parse_and(tokens, pos)
    local left, new_pos = self:_parse_primary(tokens, pos)
    local e = self.enum.token_type

    while new_pos <= #tokens and tokens[new_pos].type == e.AND do
        new_pos = new_pos + 1
        local right
        right, new_pos = self:_parse_primary(tokens, new_pos)
        left = { type = self.enum.ast_type.AND, left = left, right = right }
    end

    return left, new_pos
end

---@protected
---@param tokens Token[]
---@param pos integer
---@return Ast, integer
function this:_parse_or(tokens, pos)
    local left, new_pos = self:_parse_and(tokens, pos)
    local e = self.enum.token_type

    while new_pos <= #tokens and tokens[new_pos].type == e.OR do
        new_pos = new_pos + 1
        local right
        right, new_pos = self:_parse_and(tokens, new_pos)
        left = { type = self.enum.ast_type.OR, left = left, right = right }
    end

    return left, new_pos
end

---@protected
---@param tokens Token[]
---@param pos integer
---@return Ast, integer
function this:_parse_expression(tokens, pos)
    return self:_parse_or(tokens, pos)
end

---@protected
---@param query string
---@return Ast?
function this:_parse(query)
    if not query or query == "" then
        return
    end

    local tokens = self:_tokenize(query)
    if #tokens == 0 then
        return
    end

    local ast, pos = self:_parse_expression(tokens, 1)

    if pos <= #tokens then
        error("Unexpected tokens after expression")
    end

    return ast
end

---@param ast Ast
---@return table<any, boolean>?
function this:_evaluate(ast)
    local e = self.enum.ast_type
    ---@type table<any, boolean>
    local ret = {}

    if ast.type == e.AND then
        ---@cast ast AstOrAnd
        local left = self:_evaluate(ast.left)
        if not left then
            return
        end

        local right = self:_evaluate(ast.right)
        if not right then
            return
        end

        ret = util_table.intersect_table(left, right)
    elseif ast.type == e.OR then
        ---@cast ast AstOrAnd
        local left = self:_evaluate(ast.left)
        local right = self:_evaluate(ast.right)

        if left and right then
            ret = util_table.merge_t(left, right)
        elseif left then
            ret = left
        elseif right then
            ret = right
        end
    elseif ast.type == e.COMPARISON then
        ---@cast ast AstComparison
        for value, matches in pairs(self.data[ast.key]) do
            if type(value) == "number" and ast.operator(value, ast.value) then
                ret = util_table.merge_t(ret, matches)
            end
        end
    elseif ast.type == e.RANGE then
        ---@cast ast AstRange
        for value, matches in pairs(self.data[ast.key]) do
            if type(value) == "number" and value >= ast.min and value <= ast.max then
                ret = util_table.merge_t(ret, matches)
            end
        end
    elseif ast.type == e.MATCH then
        ---@cast ast AstMatchText
        for value, matches in pairs(self.data[ast.key]) do
            if type(value) == "string" and value == ast.value then
                ret = util_table.merge_t(ret, matches)
            end
        end
    elseif ast.type == e.TEXT then
        ---@cast ast AstText
        for value, matches in pairs(self.all_text) do
            if value:match(ast.value) then
                ret = util_table.merge_t(ret, matches)
            end
        end
    elseif ast.type == e.NOT then
        ---@cast ast AstNot
        local res = self:_evaluate(ast.expr) or {}
        for k in pairs(self.all_items) do
            if not res[k] then
                ret[k] = true
            end
        end
    end

    if not util_table.empty(ret) then
        return ret
    end
end

function this:clear()
    local search = self.data --[[@as table<string, table<any, table<integer, any>>>]]

    for key, _ in pairs(search) do
        search[key] = {}
    end

    self.all_items = {}
    self.all_text = {}
end

---@param query string
---@return any[]
function this:query(query)
    local ret = {}

    ---@type Ast?
    local ast
    util.try(function()
        ast = self:_parse(query)
    end)

    if not ast then
        return ret
    end

    local res = self:_evaluate(ast)
    if res then
        return util_table.keys(res)
    end

    return ret
end

return this
