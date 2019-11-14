import times
export times
type 
  TrapTrigger* = object 
    trap*: string
    good*: bool
    bad*: bool
    data*: string
    dateCreated*: string # TODO both should be DateTime but json.to cannot serialize them
    dateStored*: string # TODO both should be DateTime but json.to cannot serialize them