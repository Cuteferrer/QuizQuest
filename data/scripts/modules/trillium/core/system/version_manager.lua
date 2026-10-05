--Determine and save version info: solarus version, etc.
sol.main.version = {}
sol.main.version.major, sol.main.version.minor, sol.main.version.patch = sol.main.get_solarus_version():match("(%d+).(%d+).(%d+)")
for k, ver in pairs(sol.main.version) do sol.main.version[k] = tonumber(ver) end
