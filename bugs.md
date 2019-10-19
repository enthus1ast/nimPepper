BUGS
=======

Recent
------

- when client was already connected but then 
  unaccepted client still receives msg, and also can send to master
  - remove client when unnaccepted?
  - check for every msg that client is un/accepted

- multiple clients with the same name can connect
  - enforce different name?

- client that blocks forever also blocks master forever
  - timeout on receive?

- modules should parse their params with parseopt 
  (or even cligen) and inform the master about misuse

Resolved
--------