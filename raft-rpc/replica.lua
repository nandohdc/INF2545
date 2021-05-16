local socket = require("socket")

local replica = {}

function replica.new(new_id, new_number_replicas, new_seed)
    local self = {}
    
    self.id = new_id
    self.number_replicas = new_number_replicas
    self.state = "FOLLOWER"
    self.term = 0
    self.seed = 0
    self.votes = 0
    self.majority = 0
    self.heartbeat = 0

    self.set_majority = function(local_num_replicas)
        self.majority =  math.floor(local_num_replicas/2) + 1
    end

    self.get_majority = function ()
        return self.majority
    end

    self.get_seed = function ()
        return self.seed
    end

    self.set_seed = function (local_seed)
        if(not local_seed) then
            self.seed = 0
        elseif (type(local_seed) ~= "number") then
            self.seed = 0
        else
            self.seed = local_seed
        end
    end

    self.get_id = function ()
       return self.id
    end

    self.set_id = function (new_identifier)
        self.id = new_identifier
    end

    self.get_state = function ()
        return self.state
    end

    self.set_state = function (new_state)
        self.state = new_state
    end

    self.get_term = function ()
        return self.term
    end

    self.set_term = function (new_term)
        self.term = new_term
    end

    self.check_leader = function ()
        if self.state ~= "LEADER" then
            return false
        end

        return true
    end

    self.check_follower = function ()
         if self.state ~= "FOLLOWER" then
            return false
        end

        return true
    end

    self.check_candidate = function ()
         if self.state ~= "CANDIDATE" then
            return false
        end

        return true
    end

    self.get_votes = function ()
        return self.votes
    end

    self.set_votes = function (new_votes)
        -- print("VOTES: "..new_votes)
        self.votes = new_votes
    end

    self.get_heartbeat = function ()
        return self.heartbeat
    end

    self.set_heartbeat = function ()
        self.heartbeat = socket.gettime()
    end

    self.get_replicas = function ()
        return self.number_replicas
    end

    self.set_replicas = function (local_number_replicas)
        self.number_replicas = local_number_replicas
        self.set_majority(self.get_replicas())
    end

    self.generateRandomWait = function ()
        local random_time = 0
        math.randomseed(os.time())
        random_time = (math.random(1,40)/10)
        random_time = (math.random(1,40)/10)
        random_time = (math.random(1,40)/10)
        return random_time
    end

    self.generateRandomHeartbeat = function ()
        local new_heartbeat = 0
        math.randomseed(os.time())
        new_heartbeat = (math.random(60,120)/10)
        new_heartbeat = (math.random(60,120)/10)
        new_heartbeat = (math.random(60,120)/10)
        return new_heartbeat
    end

    self.get_time = function ()
        return socket.gettime()
    end

    self.display_info = function ()
        print("ID: " .. self.get_id(), "TERM: " .. self.get_term(), "STATE: " .. self.get_state(), "#VOTES: " .. self.get_votes(), "MAJORITY: " .. self.get_majority(), "SEED: " .. tostring(self.get_seed()))
        
    end

    self.set_majority(self.get_replicas())
    self.set_seed(os.time())

    return self
end

return replica