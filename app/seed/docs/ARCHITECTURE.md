# Runtime architecture

```text
browser or Fossil client
  -> Althttpd
     -> Tcl 9.1b0 + Wapp for the FossilHub reference UI
     -> Fossil 2.29 CGI for repository pages and sync protocol
  -> /data/repositories/dig.fossil
```

The repository and Althttpd request logs survive container replacement in the
dedicated `/data` bind mount. The image filesystem stays read-only.
