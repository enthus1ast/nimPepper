import parsetoml, json, tables

# let table1 = parsetoml.parseString("""

# [checks]

#     [checks.diskusage]
#     yellow = ">80%"
#     red = ">90%"
    


# [[inputs]]
#     [[inputs.input]]
#     file_name = "test.txt"

#     [[inputs.input]]
#     file_name = "FOO"

# [output]
# verbose = true
# """)


# let table1 = parsetoml.parseString("""





# [[checks.web]]
# host = "foo"




# """)

let cmds = parseToml.parseFile(getAppDir() / "mastertraps.toml")
# echo cmds.getTable()
for k, v in cmds.getTable :
    echo k
    # echo v["binary"]
    # echo v["params"]
# echo cmds["web_200"]
# echo table1.toJson.pretty()