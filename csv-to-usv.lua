#!/usr/bin/env lua

-- USV Delimiter: Unit Separator (\x1f)
local USV_UNIT = "\x1f"

-- A robust CSV to USV converter
local function csv_to_usv(input_handle, output_handle)
    local in_quote = false
    local field = {}
    local row = {}

    while true do
        local char = input_handle:read(1)
        if not char then
            -- EOF
            if #field > 0 or #row > 0 then
                table.insert(row, table.concat(field))
                output_handle:write(table.concat(row, USV_UNIT), "\n")
            end
            break
        end

        if in_quote then
            if char == '"' then
                local next_char = input_handle:read(1)
                if next_char == '"' then
                    -- Escaped quote: "" -> "
                    table.insert(field, '"')
                else
                    -- End of quote
                    in_quote = false
                    -- Process what comes after the quote
                    if next_char == "," then
                        table.insert(row, table.concat(field))
                        field = {}
                    elseif next_char == "\n" or next_char == "\r" then
                        table.insert(row, table.concat(field))
                        output_handle:write(table.concat(row, USV_UNIT), "\n")
                        row = {}
                        field = {}
                        if next_char == "\r" then
                            local peek = input_handle:read(1)
                            if peek ~= "\n" and peek ~= nil then
                                -- Not a newline, handle somehow? For now just ignore.
                            end
                        end
                    elseif next_char == nil then
                        table.insert(row, table.concat(field))
                        output_handle:write(table.concat(row, USV_UNIT), "\n")
                        break
                    else
                        -- Malformed CSV: character immediately after closing quote
                        -- We'll just treat it as part of the next field or continue
                        table.insert(row, table.concat(field))
                        field = {next_char}
                    end
                end
            else
                table.insert(field, char)
            end
        else
            if char == '"' then
                in_quote = true
            elseif char == "," then
                table.insert(row, table.concat(field))
                field = {}
            elseif char == "\n" or char == "\r" then
                -- End of record
                table.insert(row, table.concat(field))
                output_handle:write(table.concat(row, USV_UNIT), "\n")
                row = {}
                field = {}
                if char == "\r" then
                    local peek = input_handle:read(1)
                    if peek ~= "\n" and peek ~= nil then
                        -- Handle non-standard line endings
                    end
                end
            else
                table.insert(field, char)
            end
        end
    end
end

-- If run as a script
if arg and arg[0]:match("csv%-to%-usv%.lua$") then
    csv_to_usv(io.stdin, io.stdout)
end

return {
    csv_to_usv = csv_to_usv
}
