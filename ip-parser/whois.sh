#!/bin/zsh
#
# ipreport.sh — extract public IPv4 addresses from a log, enrich them
# via whois, filter by country, and aggregate into /24 subnets.
#
# Usage:
#   ./ipreport.sh [-c RU,N/A,US] sshuttle.log
#   cat sshuttle.log | ./ipreport.sh -c RU,N/A
#
# Options:
#   -c LIST   comma-separated country codes to keep (e.g. "RU,N/A,US").
#             "N/A" matches IPs whois could not resolve. Omit to keep all.
#
# Excluded automatically: 192.168.*, 127.*, 0.*
#
set -o pipefail

typeset -a filter
countries=""

while getopts "c:h" opt; do
  case $opt in
    c) countries=$OPTARG ;;
    h) sed -n '3,15p' "$0"; exit 0 ;;
    *) exit 1 ;;
  esac
done
shift $((OPTIND - 1))

[[ -n $countries ]] && filter=(${(s:,:)${(U)countries}})

# ---------------------------------------------------------------
# 1. Extract unique IPv4 addresses (valid octets, exclusions applied)
# ---------------------------------------------------------------
typeset -a ips
ips=("${(@f)$(cat -- "$@" \
  | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' \
  | awk -F. '$1<256 && $2<256 && $3<256 && $4<256' \
  | grep -vE '^(192\.168\.|127\.|0\.)' \
  | sort -u -t. -k1,1n -k2,2n -k3,3n -k4,4n)}")

if (( ${#ips} == 0 )) || [[ -z ${ips[1]} ]]; then
  print -u2 "No public IPs found in input."
  exit 1
fi

# ---------------------------------------------------------------
# 2. whois lookup per IP, build filtered detail table
# ---------------------------------------------------------------
field() {  # field <whois-output> <regex>  -> value after "key:"
  print -r -- "$1" | grep -iE "$2" | head -1 \
    | sed -E 's/^[^:]+:[[:space:]]*//'
}

typeset -a rows kept
typeset i=0

for ip in $ips; do
  (( i++ ))
  print -nu2 "\r[whois] $i/${#ips}  $ip                    "

  out=$(whois -- "$ip" 2>/dev/null)

  country=$(field "$out" '^country:' | awk '{print toupper($1)}')
  netname=$(field "$out" '^netname:' | awk '{print $1}')
  cidr=$(field "$out" '^(CIDR|route):' | cut -d, -f1 | awk '{print $1}')
  [[ -z $cidr ]] && cidr=$(field "$out" '^inetnum:')
  org=$(field "$out" '^(OrgName|org-name|owner|organization):')
  [[ -z $org ]] && org=$(field "$out" '^descr:')

  : ${country:=N/A} ${netname:=N/A} ${cidr:=N/A} ${org:=N/A}
  org=${org//|/\\|}        # escape pipes for markdown

  # country filter (exact match against the -c list)
  if (( ${#filter} )) && [[ -z ${filter[(re)$country]} ]]; then
    continue
  fi

  rows+=("| $ip | $org | $country | $netname | $cidr |")
  kept+=("$ip")

  sleep 0.2   # be polite to RIR whois servers
done
print -u2 ""

if (( ${#kept} == 0 )); then
  print -u2 "No IPs matched the country filter: $countries"
  exit 0
fi

# ---------------------------------------------------------------
# 3. Detail table
# ---------------------------------------------------------------
print "| IP | Org | Country | Netname | CIDR |"
print "|---|---|---|---|---|"
print -l -- $rows

# ---------------------------------------------------------------
# 4. /24 aggregation table
# ---------------------------------------------------------------
typeset -A bucket
for ip in $kept; do
  key="${ip%.*}.0/24"
  (( bucket[$key]++ ))
done

print ""
print "| CIDR | Subnet Mask | IPs |"
print "|---|---|---|"
for key in ${(f)"$(print -l -- ${(k)bucket} | sort -t. -k1,1n -k2,2n -k3,3n)"}; do
  print "| $key | 255.255.255.0 | ${bucket[$key]} |"
done
