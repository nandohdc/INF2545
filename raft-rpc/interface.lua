struct = {
  name = "servers",
  fields = {
    {name = "hashid", type = "string"},
    {name = "ip", type = "string"},
    {name = "port", type = "int"}
  }
}

interface = {
  methods = {
    requestVotes = {
      resulttype = "string",
      args = {
        {direction = "in", type = "string"},
        {direction = "inout", type = "int"}
      }
    },
    appendEntries = {
      resulttype = "string",
      args = {
        {direction = "in", type = "string"},
        {direction = "inout", type = "int"}
      }
    },
    execute = {
      resulttype = "void",
      args = {
        {direction = "in", type = "string"},
        {direction = "out", type = "void"}
      }
    }
  }
}
