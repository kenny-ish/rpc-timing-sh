#!/usr/bin/env bash
# Per-phase latency of JSON-RPC endpoints using curl's timing variables.
set -euo pipefail

rounds=5
method=eth_blockNumber
while getopts "n:m:h" opt; do
  case "$opt" in
    n) rounds=$OPTARG ;;
    m) method=$OPTARG ;;
    *) echo "usage: $0 [-n rounds] [-m method] URL..." >&2; exit 2 ;;
  esac
done
shift $((OPTIND - 1))
(($# > 0)) || { echo "usage: $0 [-n rounds] [-m method] URL..." >&2; exit 2; }

body="{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"$method\",\"params\":[]}"
fmt='%{time_namelookup} %{time_connect} %{time_appconnect} %{time_starttransfer} %{time_total} %{http_code}\n'

printf '%-45s %6s %6s %6s %8s %8s %8s %4s\n' endpoint dns tcp tls server total max ok
for url in "$@"; do
  for ((i = 0; i < rounds; i++)); do
    # curl still prints the -w line (with http_code 000) when the request fails
    curl -s -o /dev/null -m 10 -H 'Content-Type: application/json' -d "$body" -w "$fmt" "$url" || true
  done | awk -v url="$url" '
    $6 ~ /^2/ {
      n++
      dns += $1
      tcp += $2 - $1
      start = ($3 > 0) ? $3 : $2
      tls += ($3 > 0) ? $3 - $2 : 0
      srv += $4 - start
      tot += $5
      if ($5 > max) max = $5
      next
    }
    { fail++ }
    END {
      if (n) printf "%-45s %6.0f %6.0f %6.0f %8.0f %8.0f %8.0f %d/%d\n", url, dns/n*1000, tcp/n*1000, tls/n*1000, srv/n*1000, tot/n*1000, max*1000, n, n+fail
      else printf "%-45s  all %d requests failed\n", url, fail
    }'
done
