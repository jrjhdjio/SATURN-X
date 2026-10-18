-- Opt-in observation of the equipped HarpoonScript only. Never sends or replays calls.
return function(options)
    local env, player = options.Environment, options.Player
    local clock = options.Clock or os.clock
    local controller = {Disposed = false}
    local registry
    local function short(value) return string.sub(tostring(value), 1, 160) end
    local function describe(value, depth, seen, budget)
        budget.n = budget.n + 1
        if budget.n > 48 then return "<limit>" end
        local kind = typeof(value)
        if kind == "Instance" then return value.ClassName .. " " .. short(value.GetFullName(value)) end
        if kind == "string" then return string.format("%q", short(value)) end
        if kind == "nil" or kind == "boolean" or kind == "number" then return tostring(value) end
        if kind == "Vector3" or kind == "Vector2" or kind == "CFrame" or kind == "Ray" or kind == "EnumItem" then
            return kind .. "(" .. short(value) .. ")"
        end
        if kind ~= "table" then return "<" .. kind .. ">" end
        if seen[value] then return "<cycle>" end
        if depth >= 3 then return "<table>" end
        seen[value] = true
        local rows, count = {}, 0
        for key, entry in next, value do
            count = count + 1
            if count > 12 or budget.n >= 48 then rows[#rows + 1] = "..." break end
            local sensitive = type(key) == "string" and string.lower(key):match("token")
            if type(key) == "string" then
                for _, word in ipairs({"secret", "password", "auth", "session"}) do
                    sensitive = sensitive or string.find(string.lower(key), word, 1, true)
                end
            end
            rows[#rows + 1] = describe(key, depth + 1, seen, budget) .. "=" ..
                (sensitive and "<redacted>" or describe(entry, depth + 1, seen, budget))
        end
        seen[value] = nil
        return "{" .. table.concat(rows, ", ") .. "}"
    end
    local function observe(record, remote, method, caller, args)
        if not record.Active or clock() >= record.Deadline or record.Tool.Parent ~= player.Character then return end
        if caller ~= record.Script then return end
        if method ~= "FireServer" and method ~= "InvokeServer" then return end
        if typeof(remote) ~= "Instance" then return end
        if not (remote.IsA(remote, "RemoteEvent") or remote.IsA(remote, "UnreliableRemoteEvent") or remote.IsA(remote, "RemoteFunction")) then return end
        if #record.Rows >= 12 then record.Capped = true return end
        local rows = {string.format("CALL %d | %.2fs | %s:%s | argc=%d", #record.Rows + 1,
            clock() - record.Started, short(remote.GetFullName(remote)), method, args.n),
            "  caller=" .. short(caller.GetFullName(caller))}
        local budget = {n = 0}
        for i = 1, math.min(args.n, 12) do
            rows[#rows + 1] = "  arg" .. i .. ": " .. describe(args[i], 0, {}, budget)
        end
        if args.n > 12 then rows[#rows + 1] = "  ... argument limit" end
        record.Rows[#record.Rows + 1] = table.concat(rows, "\n")
    end
    local function install()
        local existing = env.SATURN_X_HARPOON_OBSERVER
        if type(existing) == "table" and existing.Version == 1 and existing.Installed then registry = existing return true end
        local api = {}
        for _, name in ipairs({"hookmetamethod", "getnamecallmethod", "getcallingscript", "checkcaller", "newcclosure"}) do
            api[name] = env[name] or ({hookmetamethod = hookmetamethod, getnamecallmethod = getnamecallmethod,
                getcallingscript = getcallingscript, checkcaller = checkcaller, newcclosure = newcclosure})[name]
            if type(api[name]) ~= "function" then return false, "Unsupported API: " .. name end
        end
        local candidate = {Version = 1}
        local original
        local ok, err = pcall(function()
            original = api.hookmetamethod(options.Game, "__namecall", api.newcclosure(function(remote, ...)
                local record = candidate.Active
                if record and not record.Busy then
                    record.Busy = true
                    local args = table.pack(...)
                    local captured, captureError = pcall(function()
                        if not api.checkcaller() then
                            record.Observe(record, remote, api.getnamecallmethod(), api.getcallingscript(), args)
                        end
                    end)
                    if not captured then record.Errors = record.Errors + 1 record.LastError = short(captureError) end
                    record.Busy = false
                end
                -- Forward exactly once, preserving arguments, results, and original errors.
                return original(remote, ...)
            end))
        end)
        if not ok then return false, "Observer unavailable: " .. short(err) end
        candidate.Installed = true
        registry = candidate
        env.SATURN_X_HARPOON_OBSERVER = registry
        return true
    end
    function controller:Cancel()
        local record = self.Record
        if record then
            record.Active = false
            if registry and registry.Active == record then registry.Active = nil end
        end
    end
    function controller:Report()
        local record = self.Record
        if not record then return "HARPOON TRACE: no recording started" end
        local rows = {"SATURN X HARPOON TRACE (passive; no requests sent or replayed)",
            "place=" .. options.Game.PlaceId .. " universe=" .. options.Game.GameId,
            "tool=" .. record.ToolPath, "calls=" .. #record.Rows .. " capped=" .. tostring(record.Capped),
            "captureErrors=" .. record.Errors .. " lastError=" .. record.LastError}
        for _, row in ipairs(record.Rows) do rows[#rows + 1] = row end
        if #record.Rows == 0 then rows[#rows + 1] = "No matching HarpoonScript namecalls observed. This does not prove the tool sent no requests." end
        return table.concat(rows, "\n")
    end
    function controller:Finish()
        self:Cancel()
        return self:Report()
    end
    function controller:Start()
        if self.Disposed then return false, "Observer closed" end
        self:Cancel()
        local tool, script
        if player.Character then
            for _, child in ipairs(player.Character:GetChildren()) do
                if child:IsA("Tool") then
                    for _, item in ipairs(child:GetDescendants()) do
                        if item:IsA("LocalScript") and item.Name == "HarpoonScript" then tool, script = child, item break end
                    end
                end
                if tool then break end
            end
        end
        if not tool then return false, "Equip Harpoon (HarpoonScript) first" end
        local ok, err = install()
        if not ok then return false, err end
        if registry.Active then return false, "Another recording is active" end
        local started = clock()
        local record = {Active = true, Tool = tool, Script = script, ToolPath = tool:GetFullName(),
            Started = started, Deadline = started + 15, Rows = {}, Errors = 0, LastError = "none", Capped = false, Observe = observe}
        self.Record = record
        registry.Active = record
        options.Delay(15, function()
            if not self.Disposed and self.Record == record and record.Active then
                local report = self:Finish()
                if options.OnFinished then options.OnFinished(report) end
            end
        end)
        return true
    end
    function controller:Dispose() self:Cancel() self.Record = nil self.Disposed = true end
    return controller
end
