import parsetoml, json, tables, os, times
import flatdb

let cmds = parseToml.parseFile(getAppdir() / "../../traps/mastertraps.toml")
# echo cmds.getTable()
for k, v in cmds["trap"].getTable :
    echo k
    # echo v["binary"]
    # echo v["params"]
# echo cmds["web_200"]
# echo table1.toJson.pretty()