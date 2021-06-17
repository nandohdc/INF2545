local num_nodes = 16
local messages = {}
local j = 2*num_nodes

for i = 1, num_nodes, 1 do
    messages[i] = {j, j - 1}
    j = j - 2
end

for index, value in ipairs(messages) do
    for i, v in ipairs(value) do
        print(index, v)
    end
end


