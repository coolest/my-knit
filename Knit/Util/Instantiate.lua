local Instantiate = {}

function Instantiate.new(ClassName, Parent, Properties)
    assert(type(ClassName) == "string", "Argument #1 must be a string")
    assert(type(Properties) == "table" or Properties == nil, "Argument #3 must be a table")

    local NewInstance = Instance.new(ClassName)

    if Properties then
        pcall(function()
            for Property,Value in pairs(Properties) do
                assert(NewInstance[tostring(Property)], "Invalid property: " .. tostring(Property))
                NewInstance[tostring(Property)] = Value
            end
        end)
    end

    if Parent then
        NewInstance.Parent = Parent
    end

    return NewInstance
end

return Instantiate