
const 
    DEFAULT_PATH = "/usr/bin/pepperslave/"
    LAUNCHD_SERVICE_FILE = """<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
	<dict>
		<key>Label</key>
		<string>com.example.app</string>
		<key>Program</key>
		<string>/Users/Me/Scripts/cleanup.sh</string>
		<key>RunAtLoad</key>
		<true/>
	</dict>
</plist>"""

proc launchdAutostart(executable: string) = 
    discard

proc install*(master: string, port: uint16, pubKey: string, autostart = false): bool =
    try:
        echo "[+] creating dirs"
        createDir(DEFAULT_PATH)
        DEFAULT_PATH.setFilePermissions({fpUserExec, fpUserWrite, fpUserRead})
        let newFile = DEFAULT_PATH / getAppFilename().extractFilename

        echo "[+] copy files"
        copyFile(getAppFilename(), newFile )
        newFile.setFilePermissions({fpUserExec, fpUserWrite, fpUserRead})
        echo newFile

        echo "[+] change config"
        discard execShellCmd("$# changeMaster --master:$# --port:$# --publicKey:$#" % [newFile, master, $port, pubKey])

        echo "[+] adding autostart"
        launchdAutostart(newFile)
        return true

    except:
        echo getCurrentExceptionMsg()
        return false        