import os, random
type 
    Worker = Thread[ChkLib]
    ChkLib = ref object
        chanAwaiting: Channel[Check]
        chanDone: Channel[Result]
        threads: seq[Worker]
    Check = string
    Result = string      
    # Check = object
    # Result = object
    #     check: Check
    #     retcode: int
    #     output: string

proc randId(): int =
    rand(100)

var chanAwaiting: Channel[Check]
var chanDone: Channel[Result]

# proc worker(chklib: ChkLib) {.thread.} = 
proc worker(chklib: ChkLib) {.thread.} = 
    # chklib.chanAwaiting.open()
    # chklib.chanDone.open()s
    var id = randId()
    echo "Thread: ", id
    while true:
        discard
        var check = chanAwaiting.tryRecv()

        #get new work
        #dowork
        #returnwork
        if check.dataAvailable:
            var done = $id & ":WORK WORK " & check.msg
            chanDone.send(done)
        sleep(500)

proc newChkLib(threadCount =  5): ChkLib =
    result = ChkLib()
    chanAwaiting.open(100_000)
    chanDone.open(100_000)
    for idx in 1..threadCount:
        var thread: Worker
        # createThread(thread, worker, 1)
        result.threads.add thread

proc spawn(chklib: var ChkLib) = 
    for thread in chklib.threads.mitems:
        createThread(thread, worker, chklib)
        


when isMainModule:
    var chklib = newChkLib()
    chklib.spawn()
    # sleep(10000)
    # joinThreads(chklib.threads)
    var idx = 0
    while true:
        echo "genWork"
        let checkTodo = $idx #$randId() & $randId() & $randId() & $randId() & $randId() 
        idx.inc
        echo checkTodo
        chanAwaiting.send(checkTodo)
        var res = chanDone.tryRecv()
        echo res
        if res.dataAvailable:
          echo res
        else:
          sleep(5000)