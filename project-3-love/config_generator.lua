local counter = 1
local matrix = {}          -- create the matrix
local neighborhood = {}
local lines = tonumber(arg[1])
local columns = tonumber(arg[2])

for i=1,lines do
    matrix[i] = {}     -- create a new row
    for j=1,columns do
        matrix[i][j] = counter
        counter = counter + 1
    end
end

-- for i=1,lines do
--     local msg = ''
--     for j=1,columns do
--         msg = msg..matrix[i][j]..","
--     end
--     print(msg)
-- end

for i=1,lines do
    for j=1,columns do
        if i == 1 or i == lines or j == 1 or j == columns then
            local new_neighbor = {}
            if i ~= 1 then
                table.insert(new_neighbor, matrix[i - 1][j])
            end

            if j ~= columns then
                table.insert(new_neighbor, matrix[i][j + 1])
            end

            if i ~= lines then
                table.insert(new_neighbor, matrix[i + 1][j])
            end

            if j ~= 1 then
                table.insert(new_neighbor, matrix[i][j - 1])
            end
            table.insert(neighborhood, matrix[i][j], new_neighbor)
        else
            local new_neighbor = {}
            table.insert(new_neighbor, matrix[i - 1][j]) -- vizinho de cima
            table.insert(new_neighbor, matrix[i + 1][j]) -- vizinho de baixo
            table.insert(new_neighbor, matrix[i][j - 1]) -- vizinho de esquerda
            table.insert(new_neighbor, matrix[i][j + 1]) -- vizinho de direita
            table.insert(neighborhood, matrix[i][j], new_neighbor)
        end
    end
end

for index, value in ipairs(neighborhood) do
    local topics = ''
    for i, v in ipairs(value) do
        if(i == #value) then
            topics = topics.."'channel"..v.."'" 
        else
            topics = topics.."'channel"..v.."',"
        end
    end
    local info = "config = {id ="..index..", topic = 'channel"..index.."',".."subscribedTo = {"..topics.."},".."numberOfNodes = "..lines*columns.."}"
    local file = assert(io.open("config/" .."node"..index..".lua", "w"))
    file:write(info)
    file:close()
    print(index, info)
end