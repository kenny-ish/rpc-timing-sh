# rpc-timing-sh

Splits the latency of a JSON-RPC call into DNS, TCP, TLS and server time, using the timing variables
curl already records. It sends a few `eth_blockNumber` calls per endpoint and averages them.

```bash
./rpc-timing.sh https://ethereum-rpc.publicnode.com https://eth.drpc.org
./rpc-timing.sh -n 10 -m eth_chainId https://mainnet.base.org
```

```
$ ./rpc-timing.sh -n 3 https://ethereum-rpc.publicnode.com https://eth.drpc.org https://doesnotexist.invalid
endpoint                                         dns    tcp    tls   server    total      max   ok
https://ethereum-rpc.publicnode.com                1      9     29       50       89       92 3/3
https://eth.drpc.org                               1      9     30       53       93       99 3/3
https://doesnotexist.invalid                   all 3 requests failed
```

All values are in milliseconds:

| column | curl variables |
|---|---|
| dns | `time_namelookup` |
| tcp | `time_connect - time_namelookup` |
| tls | `time_appconnect - time_connect` (0 for plain http) |
| server | `time_starttransfer - time_appconnect`, from sending the request to the first byte back |
| total | `time_total` |

Each request opens a new connection so the handshake cost shows up. When `tcp` and `tls` are most of
the total, the endpoint is far away, and a client that keeps connections open (or a closer endpoint)
helps more than a faster node. When `server` is most of it, the node or its load balancer is slow.

Needs `bash`, `curl` and `awk`.
